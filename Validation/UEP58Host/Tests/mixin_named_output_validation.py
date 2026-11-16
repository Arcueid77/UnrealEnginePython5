"""Opt-in named outputs through precompiled BP calls and native entry."""
import json
from pathlib import Path
import sys
import traceback
import uuid
import unreal_engine as ue
from unreal_engine.classes import Actor, KismetMathLibrary, K2Node_FunctionResult, UEPValidationObject
from unreal_engine.structs import EdGraphPinType


def check(value, reason):
    if not value:
        raise AssertionError(reason)


def connect(source, source_pin, target, target_pin):
    source.node_find_pin(source_pin).connect(target.node_find_pin(target_pin))


def target_blueprint(path):
    bp = ue.create_blueprint(Actor, path)
    for name in ("BlueprintCalls", "PythonCalls"):
        ue.blueprint_add_member_variable(bp, name, "int")
    ue.compile_blueprint(bp)
    graph = ue.blueprint_add_function(bp, "Command")
    entry = graph.Nodes[0]
    entry.node_create_pin(1, EdGraphPinType(PinCategory="int"), "Amount")
    read = graph.graph_add_node_variable_get("BlueprintCalls")
    add = graph.graph_add_node_call_function(KismetMathLibrary.Add_IntInt)
    add.node_find_pin("B").default_value = "1"
    write = graph.graph_add_node_variable_set("BlueprintCalls")
    result = graph.graph_add_node(K2Node_FunctionResult)
    result.node_create_pin(0, EdGraphPinType(PinCategory="int"), "Result")
    result.node_create_pin(0, EdGraphPinType(PinCategory="bool"), "Accepted")
    result.node_find_pin("Accepted").default_value = "true"
    connect(entry, "then", write, "execute")
    connect(read, "BlueprintCalls", add, "A")
    connect(add, "ReturnValue", write, "BlueprintCalls")
    connect(write, "then", result, "execute")
    connect(entry, "Amount", result, "Result")
    ue.compile_blueprint(bp)
    check(int(bp.Status) != 2, "named-output target did not compile")
    return bp


def caller_blueprint(path, cls):
    bp = ue.create_blueprint(Actor, path)
    ue.blueprint_add_member_variable(bp, "Target", EdGraphPinType(PinCategory="object", PinSubCategoryObject=cls))
    ue.blueprint_add_member_variable(bp, "Result", "int")
    for name in ("Accepted", "SentinelA", "SentinelB"):
        ue.blueprint_add_member_variable(bp, name, "bool")
    ue.compile_blueprint(bp)
    bp.GeneratedClass.get_cdo().set_property("SentinelA", True)
    bp.GeneratedClass.get_cdo().set_property("SentinelB", True)
    graph = ue.blueprint_add_function(bp, "Dispatch")
    entry, owner = graph.Nodes[0], graph.graph_add_node_variable_get("Target")
    call = graph.graph_add_node_call_function(cls.Command)
    call.node_find_pin("Amount").default_value = "7"
    write_int = graph.graph_add_node_variable_set("Result")
    write_bool = graph.graph_add_node_variable_set("Accepted")
    connect(entry, "then", call, "execute")
    connect(owner, "Target", call, "self")
    connect(call, "then", write_int, "execute")
    connect(call, "Result", write_int, "Result")
    connect(write_int, "then", write_bool, "execute")
    connect(call, "Accepted", write_bool, "Accepted")
    ue.compile_blueprint(bp)
    check(int(bp.Status) != 2, "named-output caller did not compile")
    return bp


class PythonProfile:
    def Command(self, Amount):
        self.set_property("PythonCalls", self.get_property("PythonCalls")+1)
        return {"Result": Amount*3, "Accepted": False}
    Command.uep_named_outputs = True


class OriginalProfile:
    def Command(self, Amount):
        values = self.call_mixin_original("Command", Amount)
        check(type(values) is tuple and len(values) == 2, "explicit original named shape differs")
        return {"Result": values[0], "Accepted": values[1]}
    Command.uep_named_outputs = True


class FallbackProfile:
    pass


class MixedNativeOutputs:
    def ComputeOutputs(self, Input):
        return {"ReturnValue": False, "Doubled": Input*5, "Label": "Python:"+str(Input)}
    ComputeOutputs.uep_named_outputs = True


class InvalidMarker:
    def Command(self, Amount):
        return {"Result": Amount, "Accepted": True}
    Command.uep_named_outputs = 1


def validate():
    suffix = uuid.uuid4().hex
    bp = target_blueprint("/Game/UEPValidation/NamedTarget_"+suffix)
    caller_bp = caller_blueprint("/Game/UEPValidation/NamedCaller_"+suffix, bp.GeneratedClass)
    native_bp = ue.create_blueprint(UEPValidationObject, "/Game/UEPValidation/NamedNative_"+suffix)
    ue.compile_blueprint(native_bp)
    world = ue.get_editor_world()
    ue.allow_actor_script_execution_in_editor(True)
    actors, registrations = [], []
    report = {"status": "passed", "cases": [], "same_class": True, "full_acceptance": False,
              "packed_bool_layout_explicitly_proven": False}
    try:
        target, caller = world.actor_spawn(bp.GeneratedClass), world.actor_spawn(caller_bp.GeneratedClass)
        actors += [target, caller]
        caller.set_property("Target", target)
        caller.call_function("Dispatch")
        check(target.BlueprintCalls == 1 and caller.Result == 7 and caller.Accepted,
              "original precompiled BP failed: "+repr((target.BlueprintCalls, caller.Result, caller.Accepted, caller.Target)))
        ue.register_mixin_profile(bp.GeneratedClass, "Python", PythonProfile, make_default=True)
        registrations.append(bp.GeneratedClass)
        ue.register_mixin_profile(bp.GeneratedClass, "Original", OriginalProfile)
        # A nonmatching helper keeps this profile valid; Command is absent so
        # its routing must really use the preserved original, not Python.
        class MissingCommand:
            def BeginPlay(self):
                self.call_mixin_original("ReceiveBeginPlay")
            BeginPlay.override = "ReceiveBeginPlay"
        ue.register_mixin_profile(bp.GeneratedClass, "Fallback", MissingCommand)
        for index in range(3):
            caller.call_function("Dispatch")
            check(caller.Result == 21 and caller.Accepted is False and caller.SentinelA and caller.SentinelB,
                  "precompiled BP output/bool/sentinel differs")
        check(target.PythonCalls == 3 and target.BlueprintCalls == 1, "Python dispatch also executed original BP")
        report["cases"].append("precompiled-bp-multiple-outputs")
        values = ue.call_function_by_class(target, bp.GeneratedClass, "Command", {"Amount": 11})
        check(values == {"Result": 33, "Accepted": False}, "native ProcessEvent outputs differ: "+repr(values))
        caller.call_function("Dispatch")
        check(caller.Result == 21 and not caller.Accepted, "BP call after native entry has stale output address")
        report["cases"].append("native-entry-then-bp-repeat")
        ue.set_mixin_profile(target, "Original")
        caller.call_function("Dispatch")
        check(caller.Result == 7 and caller.Accepted and target.BlueprintCalls == 2, "explicit original output propagation differs")
        report["cases"].append("explicit-original-named-outputs")
        ue.set_mixin_profile(target, "Fallback")
        caller.call_function("Dispatch")
        check(caller.Result == 7 and caller.Accepted and target.BlueprintCalls == 3, "missing-method BP fallback named outputs differ")
        check(ue.call_function_by_class(target, bp.GeneratedClass, "Command", {"Amount": 13}) == {"Result": 13, "Accepted": True}, "native-entry fallback differs")
        report["cases"].append("missing-method-original-bp-and-native-entry")
        try:
            ue.register_mixin_profile(bp.GeneratedClass, "InvalidMarker", InvalidMarker)
        except TypeError as error:
            check("uep_named_outputs must be bool" in str(error), "unexpected marker rejection")
        else:
            raise AssertionError("integer opt-in marker accepted")
        report["cases"].append("invalid-marker-fail-closed")
        native = ue.new_object(native_bp.GeneratedClass)
        ue.register_mixin_profile(native_bp.GeneratedClass, "Python", MixedNativeOutputs, make_default=True)
        registrations.append(native_bp.GeneratedClass)
        values = ue.call_function_by_class(native, native_bp.GeneratedClass, "ComputeOutputs", {"Input": 4})
        check(values == {"ReturnValue": False, "Doubled": 20, "Label": "Python:4"}, "return+named native signature differs: "+repr(values))
        report["cases"].append("native-signature-return-plus-named-outputs")
        for cls in registrations:
            ue.unregister_mixin(cls)
        registrations.clear()
        caller.call_function("Dispatch")
        check(caller.Result == 7 and caller.Accepted and target.get_class() == bp.GeneratedClass, "unregister original/class restoration differs")
        report["cases"].append("unregister-same-class-restoration")
        return report
    finally:
        for cls in registrations:
            ue.unregister_mixin(cls)
        for actor in actors:
            if actor.is_valid():
                actor.actor_destroy()


def validate_negative():
    bp = target_blueprint("/Game/UEPValidation/NamedNegative_"+uuid.uuid4().hex)
    world = ue.get_editor_world()
    ue.allow_actor_script_execution_in_editor(True)
    target = world.actor_spawn(bp.GeneratedClass)
    report = {"status": "passed", "cases": [], "expected_errors": [], "full_acceptance": False}
    selector = {"result": 42}
    class Broken:
        def Command(self, Amount):
            return selector["result"]
        Command.uep_named_outputs = True
    try:
        ue.register_mixin_profile(bp.GeneratedClass, "Broken", Broken, make_default=True)
        ue.register_mixin_profile(bp.GeneratedClass, "Python", PythonProfile)
        for name, value, reason in (("wrong-dictionary-type", 42, "named mixin outputs require a dictionary"),
                                    ("missing-second-output", {"Result": 77}, "named mixin output omitted Command.Accepted"),
                                    ("extra-key-after-conversion", {"Result": 77, "Accepted": False, "Extra": 1},
                                     "named mixin output dictionary has unexpected keys")):
            selector["result"] = value
            outputs = ue.call_function_by_class(target, bp.GeneratedClass, "Command",
                {"Amount": 9, "Result": 123, "Accepted": True})
            check(outputs == {"Result": 123, "Accepted": True}, "bad named outputs partially mutated caller storage: "+repr(outputs))
            check(target.BlueprintCalls == 0, "bad Python outputs silently ran original BP")
            report["cases"].append(name)
            report["expected_errors"].append(reason)
        ue.set_mixin_profile(target, "Python")
        outputs = ue.call_function_by_class(target, bp.GeneratedClass, "Command", {"Amount": 9})
        check(outputs == {"Result": 27, "Accepted": False}, "named output recovery failed")
        report["cases"].append("valid-profile-recovery")
        ue.unregister_mixin(bp.GeneratedClass)
        outputs = ue.call_function_by_class(target, bp.GeneratedClass, "Command", {"Amount": 9})
        check(outputs == {"Result": 9, "Accepted": True} and target.BlueprintCalls == 1, "original restoration after failed outputs differs")
        report["cases"].append("original-restoration-after-rejection")
        return report
    finally:
        ue.unregister_mixin(bp.GeneratedClass)
        if target.is_valid():
            target.actor_destroy()


result = next((arg.split("=", 1)[1] for arg in sys.argv if arg.startswith("-UEPMixinNamedOutputResult=")), None)
if result is None:
    raise RuntimeError("UEPMixinNamedOutputResult required")
try:
    report = validate_negative() if "-UEPNamedOutputNegative" in sys.argv else validate()
except Exception:
    report = {"status": "failed", "error": traceback.format_exc()}
Path(result).write_text(json.dumps(report, indent=2), encoding="utf-8")
ue.log("UEP_MIXIN_NAMED_OUTPUT_"+report["status"].upper())
if report["status"] != "passed":
    raise RuntimeError(report["error"])
