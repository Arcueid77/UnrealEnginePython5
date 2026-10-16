"""Editor authoring must reuse an inherited selector without changing its parent."""

import json
from pathlib import Path
import sys
import traceback
import types
import uuid

import unreal_engine as ue
from unreal_engine.classes import DataAssetFactory, UEPValidationObject, UEPPythonMixinSet
from unreal_engine.structs import UEPPythonMixinProfile


def check(condition, message):
    if not condition:
        raise AssertionError(message)


class PythonProfile:
    def BroadcastSignal(self, Value):
        self.SelectorPythonCalls = getattr(self, "SelectorPythonCalls", 0) + 1


class FallbackProfile:
    def BroadcastSignal(self, Value):
        self.call_mixin_original("BroadcastSignal", Value)


def validate():
    suffix = uuid.uuid4().hex
    module_name = "uep_selector_fixture_" + suffix
    module = types.ModuleType(module_name)
    module.PythonProfile, module.FallbackProfile = PythonProfile, FallbackProfile
    sys.modules[module_name] = module
    factory = DataAssetFactory()
    factory.DataAssetClass = UEPPythonMixinSet
    mixin = ue.create_asset("SelectorSet_" + suffix, "/Game/UEPValidation", UEPPythonMixinSet, factory)
    mixin.DefaultProfile = "Python"
    mixin.Profiles = [
        UEPPythonMixinProfile(ProfileName="Python", PythonModule=module_name, PythonClass="PythonProfile"),
        UEPPythonMixinProfile(ProfileName="BlueprintFallback", PythonModule=module_name, PythonClass="FallbackProfile"),
    ]
    parent = ue.create_blueprint(UEPValidationObject, "/Game/UEPValidation/SelectorParent_" + suffix)
    ue.blueprint_configure_mixin(parent, mixin, "Python", "PythonMixinProfile")
    ue.compile_blueprint(parent)
    ue.unregister_all_mixins()
    child = ue.create_blueprint(parent.GeneratedClass, "/Game/UEPValidation/SelectorChild_" + suffix)
    ue.blueprint_configure_mixin(child, mixin, "BlueprintFallback", "PythonMixinProfile")
    ue.compile_blueprint(child)
    ue.unregister_all_mixins()
    check(str(parent.GeneratedClass.get_cdo().GetPythonMixinProfile()) == "Python", "child modified parent selector")
    check(str(child.GeneratedClass.get_cdo().GetPythonMixinProfile()) == "BlueprintFallback", "child default was not preserved across compile")
    check(not any(str(value.VarName) == "PythonMixinProfile" for value in child.NewVariables), "child redeclared inherited selector")
    ue.register_declared_mixin(parent.GeneratedClass)
    first, second = ue.new_object(child.GeneratedClass), ue.new_object(child.GeneratedClass)
    # The reflected per-instance selector must work without an explicit
    # set_mixin_profile override or a second Unreal class.
    second.set_property("PythonMixinProfile", "Python")
    signals = []
    callback = signals.append
    first.bind_event("OnSignal", callback)
    second.bind_event("OnSignal", callback)
    try:
        first.call_function("BroadcastSignal", 11)
        second.call_function("BroadcastSignal", 22)
        check(signals == [11], "Python route executed the native original or fallback was lost")
        check(ue.get_mixin_profile(first) == "BlueprintFallback" and ue.get_mixin_profile(second) == "Python",
              "inherited instance selectors were not independent")
        check(first.get_class() == second.get_class() == child.GeneratedClass, "selector changed object class")
        return {"status": "passed", "parent_default": "Python", "child_default": "BlueprintFallback",
                "inherited_selector_reused": True, "parent_unchanged": True,
                "same_class_independent_instances": True, "native_signals": signals}
    finally:
        first.unbind_event("OnSignal", callback)
        second.unbind_event("OnSignal", callback)
        ue.unregister_all_mixins()


prefix = "-UEPInheritedSelectorResult="
result = next((value[len(prefix):] for value in sys.argv if value.startswith(prefix)), None)
if result is None:
    raise RuntimeError("UEPInheritedSelectorResult required")
try:
    report = validate()
except Exception:
    ue.unregister_all_mixins()
    report = {"status": "failed", "error": traceback.format_exc()}
Path(result).write_text(json.dumps(report, indent=2), encoding="utf-8")
ue.log("UEP_INHERITED_SELECTOR_" + report["status"].upper())
if report["status"] != "passed":
    raise RuntimeError(report["error"])
