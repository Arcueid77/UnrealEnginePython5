#Requires -Version 7.0
# Static guards only; persistent child discovery/original calls need native tests.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$source=Get-Content -LiteralPath (Join-Path $repo 'Source/UnrealEnginePython/Private/UEPyMixin.cpp') -Raw
if(!$source.Contains('provider && provider->GetOuter() == target_class')){throw 'An inherited provider alone must not create a child router'}
if(!$source.Contains('target_class->ImplementsInterface(interface_class) &&')){throw 'Owned provider must still implement the native Interface'}
if(!$source.Contains('target_class->HasAnyFlags(RF_Transient)') -or !$source.Contains('CLASS_NewerVersionExists')){throw 'Persistent/reinstanced target safety was weakened'}
if(!$source.Contains('FindFunctionBindingForClass(self->ue_object->GetClass(), function_name)')){throw 'Child disjoint router must not shadow ancestor originals'}
if(!$source.Contains('FindFunctionBinding(found->Get(), function_name)')){throw 'Original lookup must use each registered function map'}
if(!$source.Contains('FindBindingForContext(self->ue_object)') -or !$source.Contains('GMixinInvocations.Pop(EAllowShrinking::No)')){throw 'Nested router context must be scoped and balanced'}
if(!$source.Contains('while (UPythonFunction* routed = Cast<UPythonFunction>(original))')){throw 'Inherited original must not retain an injected parent function'}
if(!$source.Contains('RunTeardownHook(python_class, context, registration_id)')){throw 'Teardown must use its own router context'}
Write-Host 'Inherited Mixin declaration source guards PASS: 8 (not native acceptance)'
