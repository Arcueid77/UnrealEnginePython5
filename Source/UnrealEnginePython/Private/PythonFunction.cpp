
#include "PythonFunction.h"
#include "UEPyModule.h"
#include "UEPyMixin.h"

namespace
{
bool IsNamedOutput(const FProperty* Property)
{
	return Property->HasAnyPropertyFlags(CPF_OutParm) &&
		!Property->HasAnyPropertyFlags(CPF_ReturnParm | CPF_ConstParm);
}

struct FNamedOutputAddress
{
	FProperty* Property = nullptr;
	void* Address = nullptr;
};

void CopyNamedOutputs(uint8* Frame, const TMap<FProperty*, FNamedOutputAddress>& Addresses)
{
	for (const TPair<FProperty*, FNamedOutputAddress>& Pair : Addresses)
	{
		void* Source = Pair.Key->ContainerPtrToValuePtr<void>(Frame);
		if (FBoolProperty* SourceBool = CastField<FBoolProperty>(Pair.Key))
		{
			if (FBoolProperty* TargetBool = CastField<FBoolProperty>(Pair.Value.Property))
			{
				// BP caller fields can share a byte and use a different mask.
				TargetBool->SetPropertyValue(Pair.Value.Address, SourceBool->GetPropertyValue(Source));
				continue;
			}
		}
		Pair.Key->CopyCompleteValue(Pair.Value.Address, Source);
	}
}
}


void UPythonFunction::SetPyCallable(PyObject *callable)
{
	Py_XINCREF(callable);
	Py_XDECREF(py_callable);
	py_callable = callable;
}


#if UEP_LEGACY_ENGINE_MINOR_VERSION > 18
void UPythonFunction::CallPythonCallable(UObject *Context, FFrame& Stack, RESULT_DECL)
#else
void UPythonFunction::CallPythonCallable(FFrame& Stack, RESULT_DECL)
#endif
{

	FScopePythonGIL gil;

#if UEP_LEGACY_ENGINE_MINOR_VERSION <= 18
	UObject *Context = Stack.Object;
#endif

	UPythonFunction *function = static_cast<UPythonFunction *>(Stack.CurrentNativeFunction);
	PyObject* resolved_mixin_callable = nullptr;
	UFunction* mixin_original = nullptr;
	const EUEPyMixinDispatch mixin_dispatch = ue_py_resolve_mixin_call(
		function,
		Context,
		resolved_mixin_callable,
		mixin_original);
	if (mixin_dispatch == EUEPyMixinDispatch::Error)
	{
		unreal_engine_py_log_error();
		return;
	}

	bool on_error = false;
	bool is_static = function->HasAnyFunctionFlags(FUNC_Static);
	const bool needs_python_args = mixin_dispatch != EUEPyMixinDispatch::Original;

	// count the number of arguments
	const Py_ssize_t context_arg_count = (Context && !is_static) ? 1 : 0;
	Py_ssize_t argn = context_arg_count;
	TFieldIterator<FProperty> IArgs(function);
	for (; IArgs && ((IArgs->PropertyFlags & (CPF_Parm | CPF_ReturnParm)) == CPF_Parm); ++IArgs) {
		if (!IsNamedOutput(*IArgs))
			argn++;
	}
#if defined(UEPY_MEMORY_DEBUG)
	UE_LOG(LogPython, Warning, TEXT("Initializing %d parameters"), argn);
#endif
	PyObject *py_args = needs_python_args ? PyTuple_New(argn) : nullptr;
	if (needs_python_args && !py_args)
	{
		Py_XDECREF(resolved_mixin_callable);
		unreal_engine_py_log_error();
		return;
	}
	argn = 0;

	if (needs_python_args && Context && !is_static) {
		PyObject *py_obj = (PyObject *)ue_get_python_uobject(Context);
		if (!py_obj) {
			unreal_engine_py_log_error();
			on_error = true;
		}
		else {
			Py_INCREF(py_obj);
			PyTuple_SetItem(py_args, argn++, py_obj);
		}
	}

	uint8 *frame = Stack.Locals;
	bool owns_frame = false;
	TMap<FProperty*, FNamedOutputAddress> named_output_addresses;
	bool has_named_outputs = false;

	// is it a blueprint call ?
	if (!Stack.Code || *Stack.Code == EX_EndFunctionParms) {
		for (TFieldIterator<FProperty> PropIt(function); PropIt; ++PropIt) {
			FProperty* prop = *PropIt;
			if (!prop->HasAnyPropertyFlags(CPF_Parm))
				continue;
			if (prop->PropertyFlags & CPF_ReturnParm)
				continue;
			if (IsNamedOutput(prop))
			{
				has_named_outputs = true;
				void* address = prop->ContainerPtrToValuePtr<void>(Stack.Locals);
				for (FOutParmRec* out = Stack.OutParms; out; out = out->NextOutParm)
				{
					if (out->Property == prop)
					{
						address = out->PropAddr;
						break;
					}
				}
				named_output_addresses.Add(prop, {prop, address});
				continue;
			}
			if (needs_python_args && !on_error) {
				PyObject *arg = ue_py_convert_property(prop, (uint8 *)Stack.Locals, 0);
				if (!arg) {
					unreal_engine_py_log_error();
					on_error = true;
				}
				else {
					PyTuple_SetItem(py_args, argn++, arg);
				}
			}
		}
	}
	else {
		//UE_LOG(LogPython, Warning, TEXT("BLUEPRINT CALL"));
		frame = (uint8 *)FMemory_Alloca_Aligned(function->PropertiesSize, function->GetMinAlignment());
		function->InitializeStruct(frame);
		owns_frame = true;
		for (TFieldIterator<FProperty> PropIt(function); PropIt && *Stack.Code != EX_EndFunctionParms; ++PropIt) {
			FProperty* prop = *PropIt;
			if (!prop->HasAnyPropertyFlags(CPF_Parm))
				continue;
			// The return slot has no argument expression in BP call bytecode.
			// Blueprint functions may place it before additional out parameters;
			// stepping it would consume the next out expression as a return value.
			if (prop->PropertyFlags & CPF_ReturnParm)
				continue;
			Stack.Step(Stack.Object, prop->ContainerPtrToValuePtr<uint8>(frame));
			if (IsNamedOutput(prop))
			{
				has_named_outputs = true;
				if (Stack.MostRecentPropertyAddress)
					named_output_addresses.Add(prop, {Stack.MostRecentProperty, Stack.MostRecentPropertyAddress});
				continue;
			}
			if (needs_python_args && !on_error) {
				PyObject *arg = ue_py_convert_property(prop, frame, 0);
				if (!arg) {
					unreal_engine_py_log_error();
					on_error = true;
				}
				else {
					PyTuple_SetItem(py_args, argn++, arg);
				}
			}
		}
	}

	if (Stack.Code)
	{
		Stack.Code++;
	}

	PyObject* callable = mixin_dispatch == EUEPyMixinDispatch::Python
		? resolved_mixin_callable
		: function->py_callable;
	if (on_error ||
		(mixin_dispatch != EUEPyMixinDispatch::Original && !callable)) {
		Py_XDECREF(py_args);
		Py_XDECREF(resolved_mixin_callable);
		if (owns_frame)
		{
			function->DestroyStruct(frame);
		}
		return;
	}

	if (mixin_dispatch == EUEPyMixinDispatch::Original)
	{
		Py_XDECREF(py_args);
		Py_XDECREF(resolved_mixin_callable);
		if (!mixin_original || !Context)
		{
			UE_LOG(LogPython, Error, TEXT("Python mixin router lost its original function or target context"));
			if (owns_frame)
			{
				function->DestroyStruct(frame);
			}
			return;
		}

		// The injected and preserved UFunctions expose the same reflected
		// properties, but each StaticLink pass owns its offsets. Build a frame in
		// the preserved function's layout and copy native values by property name;
		// sharing the injected buffer would silently read the wrong bool/ref slots
		// on layouts such as AddInstances(const TArray<FTransform>&, ...).
		// Parameterless native events (for example UUserWidget::Destruct) have
		// zero PropertiesSize. Alloca(0) may return null, but InitializeStruct
		// requires a valid destination even when there is nothing to initialize.
		uint8* original_frame = static_cast<uint8*>(FMemory_Alloca_Aligned(
			FMath::Max<int32>(mixin_original->PropertiesSize, 1),
			mixin_original->GetMinAlignment()));
		mixin_original->InitializeStruct(original_frame);
		bool compatible_frame = true;
		for (TFieldIterator<FProperty> property_it(mixin_original); property_it; ++property_it)
		{
			FProperty* original_property = *property_it;
			if (!original_property->HasAnyPropertyFlags(CPF_Parm) ||
				original_property->HasAnyPropertyFlags(CPF_ReturnParm))
			{
				continue;
			}
			FProperty* injected_property = FindFProperty<FProperty>(
				function,
				original_property->GetFName());
			if (!injected_property || !original_property->SameType(injected_property))
			{
				UE_LOG(
					LogPython,
					Error,
					TEXT("Python mixin native fallback lost compatible parameter %s.%s"),
					*mixin_original->GetName(),
					*original_property->GetName());
				compatible_frame = false;
				break;
			}
			void* destination = original_property->ContainerPtrToValuePtr<void>(original_frame);
			const void* source = injected_property->ContainerPtrToValuePtr<void>(frame);
			original_property->CopyCompleteValue(destination, source);
		}
		if (!compatible_frame)
		{
			mixin_original->DestroyStruct(original_frame);
			if (owns_frame)
			{
				function->DestroyStruct(frame);
			}
			return;
		}

		{
			FUEPyScopedMixinCallback callback_scope;
			Py_BEGIN_ALLOW_THREADS;
			Context->ProcessEvent(mixin_original, original_frame);
			Py_END_ALLOW_THREADS;
		}

		// Preserved BP/native fallback writes its own layout. Propagate all
		// explicitly named outputs, not only CPF_ReturnParm, to the real caller.
		for (TFieldIterator<FProperty> it(function); it; ++it)
		{
			FProperty* injected_property = *it;
			if (!injected_property->HasAnyPropertyFlags(CPF_Parm) || !IsNamedOutput(injected_property))
				continue;
			FProperty* original_property = FindFProperty<FProperty>(mixin_original, injected_property->GetFName());
			if (!original_property || !injected_property->SameType(original_property))
			{
				UE_LOG(LogPython, Error, TEXT("Python mixin fallback lost named output %s"), *injected_property->GetName());
				continue;
			}
			injected_property->CopyCompleteValue(injected_property->ContainerPtrToValuePtr<void>(frame),
				original_property->ContainerPtrToValuePtr<void>(original_frame));
		}
		CopyNamedOutputs(frame, named_output_addresses);

		FProperty* return_property = function->GetReturnProperty();
		FProperty* original_return_property = mixin_original->GetReturnProperty();
		if (return_property && original_return_property &&
			return_property->SameType(original_return_property) &&
			function->ReturnValueOffset != MAX_uint16 &&
			mixin_original->ReturnValueOffset != MAX_uint16)
		{
			void* return_value = frame + function->ReturnValueOffset;
			const void* original_return_value =
				original_frame + mixin_original->ReturnValueOffset;
			return_property->CopyCompleteValue(return_value, original_return_value);
			if (RESULT_PARAM != return_value)
			{
				return_property->CopyCompleteValue(RESULT_PARAM, return_value);
			}
		}
		else if (return_property || original_return_property)
		{
			UE_LOG(
				LogPython,
				Error,
				TEXT("Python mixin native fallback lost a compatible return property for %s"),
				*mixin_original->GetName());
		}
		mixin_original->DestroyStruct(original_frame);
		if (owns_frame)
		{
			function->DestroyStruct(frame);
		}
		return;
	}

	PyObject* ret = nullptr;
	if (mixin_dispatch == EUEPyMixinDispatch::Python)
	{
		FUEPyScopedMixinCallback callback_scope;
		ret = PyObject_CallObject(callable, py_args);
	}
	else
	{
		ret = PyObject_CallObject(callable, py_args);
	}
	Py_DECREF(py_args);
	Py_XDECREF(resolved_mixin_callable);
	if (!ret) {
		unreal_engine_py_log_error();
		if (owns_frame)
		{
			function->DestroyStruct(frame);
		}
		return;
	}

	// get return value (if required)
	FProperty *return_property = function->GetReturnProperty();
	if (has_named_outputs)
	{
		// Convert a complete named dictionary in isolated storage first. A
		// missing/bad later output must not partially mutate caller-owned data.
		uint8* output_frame = static_cast<uint8*>(FMemory_Alloca_Aligned(
			FMath::Max<int32>(function->PropertiesSize, 1), function->GetMinAlignment()));
		function->InitializeStruct(output_frame);
		int32 output_count = 0;
		bool outputs_valid = PyDict_Check(ret) != 0;
		if (!outputs_valid)
			PyErr_SetString(PyExc_TypeError, "named mixin outputs require a dictionary");
		for (TFieldIterator<FProperty> it(function); it && outputs_valid; ++it)
		{
			FProperty* property = *it;
			if (!property->HasAnyPropertyFlags(CPF_Parm) ||
				!(IsNamedOutput(property) || property->HasAnyPropertyFlags(CPF_ReturnParm)))
				continue;
			++output_count;
			PyObject* value = PyDict_GetItemString(ret, TCHAR_TO_UTF8(*property->GetName()));
			if (!value)
			{
				PyErr_Format(PyExc_TypeError, "named mixin output omitted %s.%s",
					TCHAR_TO_UTF8(*function->GetName()), TCHAR_TO_UTF8(*property->GetName()));
				outputs_valid = false;
			}
			else
				outputs_valid = ue_py_convert_pyobject(value, property, output_frame, 0);
		}
		if (outputs_valid && PyDict_Size(ret) != output_count)
		{
			PyErr_SetString(PyExc_TypeError, "named mixin output dictionary has unexpected keys");
			outputs_valid = false;
		}
		if (outputs_valid)
		{
			for (TFieldIterator<FProperty> it(function); it; ++it)
			{
				FProperty* property = *it;
				if (property->HasAnyPropertyFlags(CPF_Parm) &&
					(IsNamedOutput(property) || property->HasAnyPropertyFlags(CPF_ReturnParm)))
					property->CopyCompleteValue(property->ContainerPtrToValuePtr<void>(frame),
						property->ContainerPtrToValuePtr<void>(output_frame));
			}
			CopyNamedOutputs(frame, named_output_addresses);
			if (return_property && function->ReturnValueOffset != MAX_uint16 && RESULT_PARAM != frame + function->ReturnValueOffset)
				return_property->CopyCompleteValue(RESULT_PARAM, frame + function->ReturnValueOffset);
		}
		else
		{
			UE_LOG(LogPython, Error, TEXT("Invalid named outputs for mixin function %s"), *function->GetName());
			if (PyErr_Occurred()) unreal_engine_py_log_error();
		}
		function->DestroyStruct(output_frame);
	}
	else if (return_property && function->ReturnValueOffset != MAX_uint16) {
#if defined(UEPY_MEMORY_DEBUG)
		UE_LOG(LogPython, Warning, TEXT("FOUND RETURN VALUE"));
#endif
		if (ue_py_convert_pyobject(ret, return_property, frame, 0)) {
			// copy value to stack result value
			void* return_value = frame + function->ReturnValueOffset;
			if (RESULT_PARAM != return_value)
			{
				return_property->CopyCompleteValue(RESULT_PARAM, return_value);
			}
		}
		else {
			UE_LOG(LogPython, Error, TEXT("Invalid return value type for function %s"), *function->GetFName().ToString());
			if (PyErr_Occurred())
			{
				unreal_engine_py_log_error();
			}
		}
	}
	Py_DECREF(ret);
	if (owns_frame)
	{
		function->DestroyStruct(frame);
	}
}

UPythonFunction::~UPythonFunction()
{
	if (Py_IsInitialized())
	{
		FScopePythonGIL gil;
		Py_XDECREF(py_callable);
	}
	py_callable = nullptr;
	FUnrealEnginePythonHouseKeeper::Get()->UnregisterPyUObject(this);
#if defined(UEPY_MEMORY_DEBUG)
	UE_LOG(LogPython, Warning, TEXT("PythonFunction callable %p XDECREF'ed"), this);
#endif
}
