#include "UEPyBlueprintScript.h"

#include "Engine/BlueprintGeneratedClass.h"
#include "UObject/Script.h"
#include "UObject/UnrealType.h"

namespace
{
struct FScriptBinding
{
	TWeakObjectPtr<UFunction> Function;
	FNativeFuncPtr OriginalNative = nullptr;
	EFunctionFlags OriginalFlags = FUNC_None;
	TArray<uint8> OriginalScript;
	PyObject* Callable = nullptr;
	uint64 Calls = 0;
};

TMap<TWeakObjectPtr<UFunction>, TUniquePtr<FScriptBinding>> ScriptBindings;
int32 ActiveScriptCalls = 0;

struct FScopedParameters
{
	UFunction* Function;
	uint8* Data;
	explicit FScopedParameters(UFunction* InFunction) : Function(InFunction)
	{
		Data = static_cast<uint8*>(FMemory::Malloc(FMath::Max<int32>(Function->PropertiesSize, 1), Function->GetMinAlignment()));
		Function->InitializeStruct(Data);
	}
	~FScopedParameters() { Function->DestroyStruct(Data); FMemory::Free(Data); }
};

bool IsOutput(FProperty* Property)
{
	return Property->HasAnyPropertyFlags(CPF_ReturnParm) ||
		(Property->HasAnyPropertyFlags(CPF_OutParm) && !Property->HasAnyPropertyFlags(CPF_ConstParm));
}

struct FScriptOutputAddress
{
	FProperty* Property = nullptr;
	void* Address = nullptr;
};

void CopyOutputValue(FProperty* SourceProperty, void* Source, const FScriptOutputAddress& Output)
{
	// A BP output can target a packed bool with a different mask than the
	// function parameter. Preserve neighbouring bits using the target property.
	if (FBoolProperty* SourceBool = CastField<FBoolProperty>(SourceProperty))
	{
		if (FBoolProperty* TargetBool = CastField<FBoolProperty>(Output.Property))
		{
			TargetBool->SetPropertyValue(Output.Address, SourceBool->GetPropertyValue(Source));
			return;
		}
	}
	SourceProperty->CopyCompleteValue(Output.Address, Source);
}

PyObject* ReadValue(FProperty* Property, uint8* Data)
{
	if (FDelegateProperty* Delegate = CastField<FDelegateProperty>(Property))
	{
		FScriptDelegate Value = Delegate->GetPropertyValue_InContainer(Data);
		PyObject* Target = Value.GetUObject() ? reinterpret_cast<PyObject*>(ue_get_python_uobject(Value.GetUObject())) : Py_None;
		if (!Target) return nullptr;
		return Py_BuildValue("{s:(Os)}", "__ue_delegate__", Target, TCHAR_TO_UTF8(*Value.GetFunctionName().ToString()));
	}
	return ue_py_convert_property(Property, Data, 0, true);
}

bool WriteValue(PyObject* Value, FProperty* Property, uint8* Data)
{
	if (FDelegateProperty* Delegate = CastField<FDelegateProperty>(Property))
	{
		PyObject* Pair = PyDict_Check(Value) ? PyDict_GetItemString(Value, "__ue_delegate__") : nullptr;
		if (!Pair || !PyTuple_Check(Pair) || PyTuple_Size(Pair) != 2)
		{
			PyErr_SetString(PyExc_TypeError, "delegate values require a __ue_delegate__ (UObject, function) pair");
			return false;
		}
		PyObject* TargetValue = PyTuple_GetItem(Pair, 0);
		PyObject* NameValue = PyTuple_GetItem(Pair, 1);
		FScriptDelegate ScriptDelegate;
		if (TargetValue != Py_None)
		{
			UObject* Target = ue_py_check_type<UObject>(TargetValue);
			if (!Target || !PyUnicode_Check(NameValue))
			{
				PyErr_SetString(PyExc_TypeError, "invalid delegate target or function name");
				return false;
			}
			FName Name(UTF8_TO_TCHAR(PyUnicode_AsUTF8(NameValue)));
			UFunction* Function = Target->FindFunction(Name);
			if (!Function || !Function->IsSignatureCompatibleWith(Delegate->SignatureFunction))
			{
				PyErr_SetString(PyExc_TypeError, "delegate function does not match its declared signature");
				return false;
			}
			ScriptDelegate.BindUFunction(Target, Name);
		}
		Delegate->SetPropertyValue_InContainer(Data, ScriptDelegate);
		return true;
	}
	return ue_py_convert_pyobject(Value, Property, Data, 0);
}

void BlueprintScriptThunk(UObject* Context, FFrame& Stack, RESULT_DECL)
{
	FScopePythonGIL GIL;
	UFunction* Function = Stack.CurrentNativeFunction;
	TUniquePtr<FScriptBinding>* Found = ScriptBindings.Find(Function);
	if (!Found || !IsInGameThread())
	{
		UE_LOG(LogPython, Error, TEXT("Blueprint script dispatch is unavailable for %s"), *GetNameSafe(Function));
		return;
	}
	FScriptBinding* Binding = Found->Get();
	FScopedParameters Parameters(Function);
	TMap<FProperty*, FScriptOutputAddress> OutputAddresses;
	const bool BytecodeCall = Stack.Code && *Stack.Code != EX_EndFunctionParms;
	for (TFieldIterator<FProperty> It(Function); It; ++It)
	{
		FProperty* Property = *It;
		if (!Property->HasAnyPropertyFlags(CPF_Parm) || Property->HasAnyPropertyFlags(CPF_ReturnParm)) continue;
		void* Destination = Property->ContainerPtrToValuePtr<void>(Parameters.Data);
		if (BytecodeCall)
		{
			Stack.Step(Stack.Object, Destination);
			if (IsOutput(Property) && Stack.MostRecentPropertyAddress)
				OutputAddresses.Add(Property, {Stack.MostRecentProperty, Stack.MostRecentPropertyAddress});
		}
		else
		{
			void* Source = Property->ContainerPtrToValuePtr<void>(Stack.Locals);
			// ProcessEvent copies parameters to a separate local frame. OutParms
			// points to the caller's real parameter buffer; writing only Locals
			// loses output values because the engine deliberately does not copy
			// out parameters back from that local frame on return.
			if (Property->HasAnyPropertyFlags(CPF_OutParm))
			{
				for (FOutParmRec* Out = Stack.OutParms; Out; Out = Out->NextOutParm)
				{
					if (Out->Property == Property)
					{
						Source = Out->PropAddr;
						break;
					}
				}
			}
			Property->CopyCompleteValue(Destination, Source);
			if (IsOutput(Property)) OutputAddresses.Add(Property, {Property, Source});
		}
	}
	if (Stack.Code) ++Stack.Code;
	PyObject* Arguments = PyDict_New();
	bool Valid = Arguments != nullptr;
	for (TFieldIterator<FProperty> It(Function); Valid && It; ++It)
	{
		FProperty* Property = *It;
		if (!Property->HasAnyPropertyFlags(CPF_Parm) || Property->HasAnyPropertyFlags(CPF_ReturnParm)) continue;
		PyObject* Value = ReadValue(Property, Parameters.Data);
		Valid = Value && PyDict_SetItemString(Arguments, TCHAR_TO_UTF8(*Property->GetName()), Value) == 0;
		Py_XDECREF(Value);
	}
	UObject* Target = Context ? Context : Stack.Object;
	PyObject* PythonTarget = Target ? reinterpret_cast<PyObject*>(ue_get_python_uobject(Target)) : Py_None;
	PyObject* Result = nullptr;
	if (Valid && PythonTarget)
	{
		++ActiveScriptCalls;
		++Binding->Calls;
		Result = PyObject_CallFunctionObjArgs(Binding->Callable, PythonTarget, Arguments, nullptr);
		--ActiveScriptCalls;
		Valid = Result != nullptr;
	}
	for (TFieldIterator<FProperty> It(Function); Valid && It; ++It)
	{
		FProperty* Property = *It;
		if (!Property->HasAnyPropertyFlags(CPF_Parm) || !IsOutput(Property)) continue;
		PyObject* Value = PyDict_Check(Result) ? PyDict_GetItemString(Result, TCHAR_TO_UTF8(*Property->GetName())) : nullptr;
		if (!Value)
		{
			PyErr_Format(PyExc_TypeError, "script omitted output %s.%s", TCHAR_TO_UTF8(*Function->GetName()), TCHAR_TO_UTF8(*Property->GetName()));
			Valid = false;
			break;
		}
		Valid = WriteValue(Value, Property, Parameters.Data);
	}
	if (Valid)
	{
		for (const TPair<FProperty*, FScriptOutputAddress>& Pair : OutputAddresses)
			CopyOutputValue(Pair.Key, Pair.Key->ContainerPtrToValuePtr<void>(Parameters.Data), Pair.Value);
		if (FProperty* Return = Function->GetReturnProperty())
			Return->CopyCompleteValue(RESULT_PARAM, Return->ContainerPtrToValuePtr<void>(Parameters.Data));
	}
	else
	{
		UE_LOG(LogPython, Error, TEXT("Blueprint Python body failed: %s on %s"), *Function->GetPathName(), *GetPathNameSafe(Target));
		if (PyErr_Occurred()) unreal_engine_py_log_error();
	}
	Py_XDECREF(Result);
	Py_XDECREF(Arguments);
}

bool ResolveFunction(PyObject* ClassValue, const char* Name, UClass*& Class, UFunction*& Function)
{
	Class = ue_py_check_type<UClass>(ClassValue);
	if (!Class) { PyErr_SetString(PyExc_TypeError, "expected a UClass"); return false; }
	Function = Class->FindFunctionByName(FName(UTF8_TO_TCHAR(Name)));
	if (!Function) { PyErr_Format(PyExc_AttributeError, "function %s was not found", Name); return false; }
	return true;
}
}

PyObject* py_unreal_engine_register_blueprint_script(PyObject*, PyObject* Args)
{
	PyObject* ClassValue;
	PyObject* Callable;
	const char* Name;
	if (!PyArg_ParseTuple(Args, "OsO:register_blueprint_script", &ClassValue, &Name, &Callable)) return nullptr;
	if (ActiveScriptCalls) return PyErr_Format(PyExc_RuntimeError, "cannot register a Blueprint body during dispatch");
	UClass* Class;
	UFunction* Function;
	if (!ResolveFunction(ClassValue, Name, Class, Function)) return nullptr;
	if (!IsInGameThread() || !Class->HasAnyClassFlags(CLASS_CompiledFromBlueprint) || Function->GetOuterUClass() != Class)
		return PyErr_Format(PyExc_TypeError, "only directly owned Blueprint functions may receive Python bodies on the game thread");
	if (!PyCallable_Check(Callable)) return PyErr_Format(PyExc_TypeError, "script body must be callable");
	if (ScriptBindings.Contains(Function)) return PyErr_Format(PyExc_RuntimeError, "Blueprint function is already scripted");
	if (Function->HasAnyFunctionFlags(FUNC_Native | FUNC_Delegate | FUNC_MulticastDelegate))
		return PyErr_Format(PyExc_TypeError, "native implementations and delegate signatures are retained");
	TUniquePtr<FScriptBinding> Binding = MakeUnique<FScriptBinding>();
	Binding->Function = Function;
	Binding->OriginalNative = Function->GetNativeFunc();
	Binding->OriginalFlags = Function->FunctionFlags;
	// ProcessEvent constructs FFrame::Code from the UFunction's Script storage.
	// A native body must not retain bytecode there, or its own BP instructions
	// could be mistaken for call arguments. Restore the exact bytes on teardown.
	Binding->OriginalScript = MoveTemp(Function->Script);
	Py_INCREF(Callable);
	Binding->Callable = Callable;
	ScriptBindings.Add(Function, MoveTemp(Binding));
	Function->FunctionFlags = static_cast<EFunctionFlags>(Function->FunctionFlags | FUNC_Native);
	Function->SetNativeFunc(&BlueprintScriptThunk);
	Py_RETURN_NONE;
}

void unreal_engine_python_unregister_all_blueprint_scripts()
{
	for (TPair<TWeakObjectPtr<UFunction>, TUniquePtr<FScriptBinding>>& Pair : ScriptBindings)
	{
		if (UFunction* Function = Pair.Key.Get())
		{
			if (Function->GetNativeFunc() == &BlueprintScriptThunk)
			{
				Function->SetNativeFunc(Pair.Value->OriginalNative);
				Function->FunctionFlags = Pair.Value->OriginalFlags;
				Function->Script = MoveTemp(Pair.Value->OriginalScript);
			}
		}
		Py_XDECREF(Pair.Value->Callable);
	}
	ScriptBindings.Empty();
}

PyObject* py_unreal_engine_unregister_all_blueprint_scripts(PyObject*, PyObject*)
{
	if (!IsInGameThread() || ActiveScriptCalls)
		return PyErr_Format(PyExc_RuntimeError, "script restoration requires an idle game thread");
	unreal_engine_python_unregister_all_blueprint_scripts();
	Py_RETURN_NONE;
}

PyObject* py_unreal_engine_get_registered_blueprint_scripts(PyObject*, PyObject*)
{
	PyObject* Result = PyList_New(0);
	for (const TPair<TWeakObjectPtr<UFunction>, TUniquePtr<FScriptBinding>>& Pair : ScriptBindings)
	{
		if (UFunction* Function = Pair.Key.Get())
		{
			PyObject* Entry = Py_BuildValue("{s:s,s:K,s:k}", "function", TCHAR_TO_UTF8(*Function->GetPathName()),
				"calls", Pair.Value->Calls, "original_flags", static_cast<unsigned long>(Pair.Value->OriginalFlags));
			PyList_Append(Result, Entry);
			Py_DECREF(Entry);
		}
	}
	return Result;
}

PyObject* py_unreal_engine_call_function_by_class(PyObject*, PyObject* Args)
{
	PyObject* TargetValue;
	PyObject* ClassValue;
	PyObject* Arguments;
	const char* Name;
	if (!PyArg_ParseTuple(Args, "OOsO:call_function_by_class", &TargetValue, &ClassValue, &Name, &Arguments)) return nullptr;
	if (!IsInGameThread() || !PyDict_Check(Arguments)) return PyErr_Format(PyExc_TypeError, "native calls require named arguments on the game thread");
	UClass* Class;
	UFunction* Function;
	if (!ResolveFunction(ClassValue, Name, Class, Function)) return nullptr;
	UObject* Target = Function->HasAnyFunctionFlags(FUNC_Static) ? Class->GetDefaultObject() : ue_py_check_type<UObject>(TargetValue);
	if (!Target) return PyErr_Format(PyExc_TypeError, "instance function requires a UObject target");
	if (!Function->HasAnyFunctionFlags(FUNC_Static) && !Target->IsA(Class))
	{
		if (!Class->HasAnyClassFlags(CLASS_Interface) || !Target->GetClass()->ImplementsInterface(Class))
			return PyErr_Format(PyExc_TypeError, "function target does not implement its owning class");
		Function = Target->FindFunction(Function->GetFName());
		if (!Function) return PyErr_Format(PyExc_AttributeError, "interface implementation was not found");
	}
	FScopedParameters Parameters(Function);
	for (TFieldIterator<FProperty> It(Function); It; ++It)
	{
		FProperty* Property = *It;
		if (!Property->HasAnyPropertyFlags(CPF_Parm) || Property->HasAnyPropertyFlags(CPF_ReturnParm)) continue;
		PyObject* Value = PyDict_GetItemString(Arguments, TCHAR_TO_UTF8(*Property->GetName()));
		if (Value && !WriteValue(Value, Property, Parameters.Data)) return nullptr;
	}
	Py_BEGIN_ALLOW_THREADS;
	Target->ProcessEvent(Function, Parameters.Data);
	Py_END_ALLOW_THREADS;
	PyObject* Result = PyDict_New();
	for (TFieldIterator<FProperty> It(Function); It; ++It)
	{
		FProperty* Property = *It;
		if (!Property->HasAnyPropertyFlags(CPF_Parm) || !IsOutput(Property)) continue;
		PyObject* Value = ReadValue(Property, Parameters.Data);
		if (!Value || PyDict_SetItemString(Result, TCHAR_TO_UTF8(*Property->GetName()), Value) != 0)
		{
			Py_XDECREF(Value); Py_DECREF(Result); return nullptr;
		}
		Py_DECREF(Value);
	}
	return Result;
}

PyObject* py_unreal_engine_describe_function(PyObject*, PyObject* Args)
{
	PyObject* ClassValue;
	const char* Name;
	if (!PyArg_ParseTuple(Args, "Os:describe_function", &ClassValue, &Name)) return nullptr;
	UClass* Class;
	UFunction* Function;
	if (!ResolveFunction(ClassValue, Name, Class, Function)) return nullptr;
	PyObject* Parameters = PyList_New(0);
	for (TFieldIterator<FProperty> It(Function); It; ++It)
	{
		FProperty* Property = *It;
		if (!Property->HasAnyPropertyFlags(CPF_Parm)) continue;
		PyObject* Entry = Py_BuildValue("{s:s,s:s,s:K,s:O}", "name", TCHAR_TO_UTF8(*Property->GetName()),
			"type", TCHAR_TO_UTF8(*Property->GetCPPType()), "flags", static_cast<uint64>(Property->GetPropertyFlags()),
			"output", IsOutput(Property) ? Py_True : Py_False);
		PyList_Append(Parameters, Entry); Py_DECREF(Entry);
	}
	return Py_BuildValue("{s:s,s:k,s:N}", "owner", TCHAR_TO_UTF8(*Function->GetOuterUClass()->GetPathName()),
		"flags", static_cast<unsigned long>(Function->FunctionFlags), "parameters", Parameters);
}
