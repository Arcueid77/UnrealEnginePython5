"""Persist two BP packages, then prove automatic discovery in a fresh process.

The load phase deliberately never calls a registration API. Main's CDO has a
hard reference to Companion's class so loading Main must also discover the
imported BP package. Assets are created only in a marked disposable host by the
PowerShell driver, never in the canonical validation project or official Lyra.
"""

import json
from pathlib import Path
import sys
import traceback

import unreal_engine as ue
from unreal_engine.classes import DataAssetFactory, UEPValidationObject, UEPPythonMixinSet
from unreal_engine.structs import UEPPythonMixinProfile


def argument(name):
    prefix = "-" + name + "="
    return next(value[len(prefix):].strip('"') for value in sys.argv if value.startswith(prefix))


def check(condition, message):
    if not condition:
        raise AssertionError(message)


def validate():
    phase = argument("UEPPackageLoadPhase")
    package_root = argument("UEPPackageLoadRoot")
    check(package_root.startswith("/Game/UEPValidation/PackageLoad_"), "fixture root is not task-owned")
    paths = {name: package_root + "/" + name for name in ("Main", "Companion", "MixinSet")}
    if phase == "author":
        factory = DataAssetFactory()
        factory.DataAssetClass = UEPPythonMixinSet
        mixin = ue.create_asset("MixinSet", package_root, UEPPythonMixinSet, factory)
        mixin.DefaultProfile = "Python"
        mixin.Profiles = [
            UEPPythonMixinProfile(ProfileName="Python", PythonModule="mixin_package_load_profiles", PythonClass="PythonProfile"),
            UEPPythonMixinProfile(ProfileName="BlueprintFallback", PythonModule="mixin_package_load_profiles", PythonClass="BlueprintFallbackProfile"),
        ]
        blueprints = {}
        for name in ("Companion", "Main"):
            bp = ue.create_blueprint(UEPValidationObject, paths[name])
            ue.blueprint_configure_mixin(bp, mixin, "Python", "PythonMixinProfile")
            ue.compile_blueprint(bp)
            blueprints[name] = bp
        blueprints["Main"].GeneratedClass.get_cdo().ObjectValue = blueprints["Companion"].GeneratedClass
        # Never serialize injected transient dispatch functions into the fixture.
        ue.unregister_all_mixins()
        mixin.save_package()
        for name in ("Companion", "Main"):
            blueprints[name].save_package()
        return {"status": "passed", "phase": phase, "packages": list(paths.values()), "runtime_acceptance": False}

    check(phase == "load", "unknown fixture phase")
    expected = {paths[name] + "." + name + "_C" for name in ("Main", "Companion")}
    check(not any(item["target_class"].get_path_name() in expected for item in ue.get_registered_mixins()),
          "fixture classes were already registered before load")
    cls = ue.load_class(paths["Main"] + ".Main_C")
    check(cls is not None, "saved Main class did not load")
    registered = {item["target_class"].get_path_name() for item in ue.get_registered_mixins()}
    check(expected <= registered, "completed/imported BP packages were not both automatically discovered: " + repr(registered))
    companion = cls.get_cdo().ObjectValue
    check(companion.get_path_name() == paths["Companion"] + ".Companion_C", "saved import reference was not preserved")
    results = []
    try:
        for target in (cls, companion):
            first, second = ue.new_object(target), ue.new_object(target)
            second.set_property("PythonMixinProfile", "BlueprintFallback")
            signals = []
            callback = signals.append
            first.bind_event("OnSignal", callback)
            second.bind_event("OnSignal", callback)
            try:
                first.call_function("BroadcastSignal", 11)
                second.call_function("BroadcastSignal", 22)
                check(signals == [22] and first.Int32Value == 11 and second.Int32Value == 0,
                      "Python replacement fell through or explicit original was lost")
                check(first.call_function("OverrideableValue", 7) == 107, "Python return dispatch failed")
                check(second.call_function("OverrideableValue", 7) == 7, "missing callable did not use native fallback")
                check(first.get_class() == second.get_class() == target, "per-instance profile changed the Unreal type")
                ue.unregister_mixin(target)
                first.call_function("BroadcastSignal", 33)
                second.call_function("BroadcastSignal", 44)
                check(signals == [22, 33, 44], "unregister did not restore native methods")
                check(first.call_function("OverrideableValue", 7) == 7, "native return was not restored")
                results.append({"class": target.get_path_name(), "native_signals": signals,
                                "python_value": first.Int32Value, "same_class": True,
                                "automatic_fallback": True, "original_restored": True})
            finally:
                first.unbind_event("OnSignal", callback)
                second.unbind_event("OnSignal", callback)
        check(not any(item["target_class"].get_path_name() in expected for item in ue.get_registered_mixins()),
              "fixture routers remained after cleanup")
        return {"status": "passed", "phase": phase, "automatic_registration": True,
                "explicit_registration_called": False, "imported_package_discovered": True,
                "classes": results, "full_acceptance": False}
    finally:
        ue.unregister_all_mixins()


try:
    report = validate()
except Exception:
    ue.unregister_all_mixins()
    report = {"status": "failed", "error": traceback.format_exc()}
Path(argument("UEPPackageLoadResult")).write_text(json.dumps(report, indent=2), encoding="utf-8")
ue.log("UEP_PACKAGE_LOAD_" + report["status"].upper())
if report["status"] != "passed":
    raise RuntimeError(report["error"])
