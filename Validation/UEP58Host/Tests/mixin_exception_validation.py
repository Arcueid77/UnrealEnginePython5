"""A failed Python Mixin must not implicitly broadcast its native original."""

import json
from pathlib import Path
import sys
import traceback
import uuid

import unreal_engine as ue
from unreal_engine.classes import UEPValidationObject


class ThrowingProfile:
    def BroadcastSignal(self, Value):
        raise RuntimeError("UEP_EXPECTED_MIXIN_EXCEPTION")


class RecoveredProfile:
    def BroadcastSignal(self, Value):
        self.call_mixin_original("BroadcastSignal", Value)


def validate():
    blueprint = ue.create_blueprint(UEPValidationObject, "/Game/UEPValidation/Exception_" + uuid.uuid4().hex)
    ue.compile_blueprint(blueprint)
    obj = ue.new_object(blueprint.GeneratedClass)
    calls = []
    callback = calls.append
    obj.bind_event("OnSignal", callback)
    registered = False
    try:
        obj.call_function("BroadcastSignal", 11)
        if calls != [11]:
            raise AssertionError("baseline native original did not broadcast")
        ue.register_mixin_profile(blueprint.GeneratedClass, "Throwing", ThrowingProfile, make_default=True)
        registered = True
        ue.register_mixin_profile(blueprint.GeneratedClass, "Recovered", RecoveredProfile)
        try:
            obj.call_function("BroadcastSignal", 22)
        except Exception as error:
            if "UEP_EXPECTED_MIXIN_EXCEPTION" not in str(error):
                raise
        if calls != [11]:
            raise AssertionError("Python exception fell through to native original")
        ue.set_mixin_profile(obj, "Recovered")
        obj.call_function("BroadcastSignal", 33)
        if calls != [11, 33]:
            raise AssertionError("profile switch did not recover explicit native call")
        ue.unregister_mixin(blueprint.GeneratedClass)
        registered = False
        obj.call_function("BroadcastSignal", 44)
        if calls != [11, 33, 44]:
            raise AssertionError("unregister did not restore native original")
        return {"status": "passed", "expected_exception": "UEP_EXPECTED_MIXIN_EXCEPTION",
                "no_original_after_python_exception": True, "recovered": True, "native_signals": calls}
    finally:
        if registered:
            ue.unregister_mixin(blueprint.GeneratedClass)
        obj.unbind_event("OnSignal", callback)


prefix = "-UEPMixinExceptionResult="
result = next((argument[len(prefix):] for argument in sys.argv if argument.startswith(prefix)), None)
if result is None:
    raise RuntimeError(prefix + "<path> is required")
try:
    report = validate()
except Exception:
    report = {"status": "failed", "error": traceback.format_exc()}
Path(result).write_text(json.dumps(report, indent=2), encoding="utf-8")
ue.log("UEP_MIXIN_EXCEPTION_" + report["status"].upper())
if report["status"] != "passed":
    raise RuntimeError(report["error"])
