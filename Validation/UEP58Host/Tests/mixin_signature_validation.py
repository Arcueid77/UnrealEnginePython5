"""Production Mixin return/const-struct/fallback and rejection boundaries."""

import json
from pathlib import Path
import sys
import traceback
import uuid

import unreal_engine as ue
from unreal_engine import FVector
from unreal_engine.classes import KismetSystemLibrary, UEPValidationObject
from unreal_engine.structs import UEPValidationStruct


def check(condition, message):
    if not condition:
        raise AssertionError(message)


class PythonProfile:
    def AddIntegers(self, A, B):
        return self.call_mixin_original("AddIntegers", A, B) + 10

    def EchoStruct(self, Input):
        return UEPValidationStruct(Count=Input.Count * 3, Label="Python:" + Input.Label, Vector=Input.Vector)

    def OverrideableValue(self, Input):
        return Input + 41


class FallbackProfile:
    def BroadcastSignal(self, Value):
        self.call_mixin_original("BroadcastSignal", Value)


class BadSignature:
    def AddIntegers(self):
        return 0


class NonConstOutputs:
    def ComputeOutputs(self, Input, Doubled, Label):
        return True


class StaticFunction:
    def IsValid(self, Object):
        return True


def validate():
    suffix = uuid.uuid4().hex
    bp = ue.create_blueprint(UEPValidationObject, "/Game/UEPValidation/Signature_" + suffix)
    ue.compile_blueprint(bp)
    cls = bp.GeneratedClass
    obj = ue.new_object(cls)
    original = obj.find_function("EchoStruct")
    registered = []
    evidence = {"status": "passed", "supported": [], "rejected": [], "same_class": True}
    try:
        ue.register_mixin_profile(cls, "Python", PythonProfile, make_default=True)
        registered.append(cls)
        ue.register_mixin_profile(cls, "Fallback", FallbackProfile)
        value = UEPValidationStruct(Count=7, Label="fixture", Vector=FVector(4, 5, 6))
        check(obj.call_function("AddIntegers", 3, 4) == 17, "integer return/explicit original differs")
        echoed = obj.call_function("EchoStruct", value)
        check((echoed.Count, echoed.Label, echoed.Vector) == (21, "Python:fixture", value.Vector), "const struct input/struct return differs")
        check(value.Count == 7 and value.Label == "fixture", "const input was modified")
        check(obj.call_function("OverrideableValue", 1) == 42, "BlueprintNativeEvent did not enter Python")
        evidence["supported"] += ["integer-return", "explicit-original", "const-struct-input", "struct-return", "reflected-native-event"]
        for profile, message in ((BadSignature, "self plus reflected inputs"), (NonConstOutputs, "non-const output")):
            try:
                ue.register_mixin_profile(cls, "Invalid", profile)
            except Exception as error:
                check(message in str(error), "wrong registration rejection: " + str(error))
                evidence["rejected"].append({"profile": profile.__name__, "reason": str(error)})
            else:
                raise AssertionError("invalid profile was registered")
            check(obj.call_function("AddIntegers", 3, 4) == 17, "rejection changed the active router")
        ue.set_mixin_profile(obj, "Fallback")
        echoed = obj.call_function("EchoStruct", value)
        check((echoed.Count, echoed.Label, echoed.Vector) == (7, "fixture", value.Vector), "native const-struct fallback differs")
        check(obj.call_function("AddIntegers", 3, 4) == 7, "native return fallback differs")
        evidence["supported"].append("missing-method-native-fallback")
        ue.unregister_mixin(cls)
        registered.remove(cls)
        check(obj.find_function("EchoStruct") == original, "original function identity was not restored")
        check(obj.get_class() == cls and obj.call_function("AddIntegers", 3, 4) == 7, "original class/function not restored")
        evidence["supported"].append("unregister-restoration")
        library_bp = ue.create_blueprint(KismetSystemLibrary, "/Game/UEPValidation/StaticSignature_" + suffix)
        ue.compile_blueprint(library_bp)
        try:
            ue.register_mixin_profile(library_bp.GeneratedClass, "Static", StaticFunction)
        except Exception as error:
            check("static, RPC, and delegate" in str(error), "wrong static rejection: " + str(error))
            evidence["rejected"].append({"profile": "StaticFunction", "reason": str(error)})
        else:
            registered.append(library_bp.GeneratedClass)
            raise AssertionError("static function was registered")
        return evidence
    finally:
        for target in registered:
            ue.unregister_mixin(target)


prefix = "-UEPMixinSignatureResult="
result = next((argument[len(prefix):] for argument in sys.argv if argument.startswith(prefix)), None)
if result is None:
    raise RuntimeError(prefix + "<path> is required")
try:
    report = validate()
except Exception:
    report = {"status": "failed", "error": traceback.format_exc()}
Path(result).write_text(json.dumps(report, indent=2), encoding="utf-8")
ue.log("UEP_MIXIN_SIGNATURE_" + report["status"].upper())
if report["status"] != "passed":
    raise RuntimeError(report["error"])
