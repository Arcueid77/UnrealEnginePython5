"""Verify Python bodies through a caller BP compiled before registration."""

import json
from pathlib import Path
import sys
import traceback
import uuid

import unreal_engine as ue
from unreal_engine.classes import Actor, KismetMathLibrary, K2Node_FunctionResult
from unreal_engine.structs import EdGraphPinType


def connect(source, source_pin, target, target_pin):
    source.node_find_pin(source_pin).make_link_to(target.node_find_pin(target_pin))


def check(condition, message):
    if not condition:
        raise AssertionError(message)


def target_blueprint(path):
    blueprint = ue.create_blueprint(Actor, path)
    for name in ("BlueprintCalls", "PythonCalls"):
        ue.blueprint_add_member_variable(blueprint, name, "int")
    ue.compile_blueprint(blueprint)
    graph = ue.blueprint_add_function(blueprint, "Command")
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
    ue.compile_blueprint(blueprint)
    return blueprint


def caller_blueprint(path, target_class):
    blueprint = ue.create_blueprint(Actor, path)
    ue.blueprint_add_member_variable(blueprint, "Target", EdGraphPinType(PinCategory="object", PinSubCategoryObject=target_class))
    ue.blueprint_add_member_variable(blueprint, "Result", "int")
    ue.blueprint_add_member_variable(blueprint, "Accepted", "bool")
    ue.compile_blueprint(blueprint)
    graph = ue.blueprint_add_function(blueprint, "Dispatch")
    entry = graph.Nodes[0]
    target = graph.graph_add_node_variable_get("Target")
    call = graph.graph_add_node_call_function(target_class.Command)
    call.node_find_pin("Amount").default_value = "7"
    write_result = graph.graph_add_node_variable_set("Result")
    write_accepted = graph.graph_add_node_variable_set("Accepted")
    connect(entry, "then", call, "execute")
    connect(target, "Target", call, "self")
    connect(call, "then", write_result, "execute")
    connect(call, "Result", write_result, "Result")
    connect(write_result, "then", write_accepted, "execute")
    connect(call, "Accepted", write_accepted, "Accepted")
    ue.compile_blueprint(blueprint)
    return blueprint


def validate():
    suffix = uuid.uuid4().hex
    bp = target_blueprint("/Game/UEPValidation/BodyTarget_" + suffix)
    caller_bp = caller_blueprint("/Game/UEPValidation/BodyCaller_" + suffix, bp.GeneratedClass)
    world = ue.get_editor_world()
    actors = []
    ue.allow_actor_script_execution_in_editor(True)
    try:
        target = world.actor_spawn(bp.GeneratedClass)
        caller = world.actor_spawn(caller_bp.GeneratedClass)
        actors.extend((target, caller))
        caller.set_property("Target", target)
        caller.call_function("Dispatch")
        check(target.BlueprintCalls == 1 and caller.Result == 7 and caller.Accepted, "original BP call did not work")

        def body(context, arguments):
            context.set_property("PythonCalls", context.PythonCalls + 1)
            return {"Result": arguments["Amount"] * 3, "Accepted": False}

        signature_before = ue.describe_function(bp.GeneratedClass, "Command")
        ue.register_blueprint_script(bp.GeneratedClass, "Command", body)
        caller.call_function("Dispatch")
        check(target.BlueprintCalls == 1 and target.PythonCalls == 1, "precompiled caller did not replace the BP body")
        check(caller.Result == 21 and not caller.Accepted, "BP outputs did not propagate from Python")
        outputs = ue.call_function_by_class(target, bp.GeneratedClass, "Command", {"Amount": 11})
        check(outputs == {"Result": 33, "Accepted": False}, "ProcessEvent outputs differ from the BP call: " + repr(outputs))
        repeated_outputs = ue.call_function_by_class(target, bp.GeneratedClass, "Command", {"Amount": -2})
        check(repeated_outputs == {"Result": -6, "Accepted": False}, "repeated ProcessEvent retained stale output values")
        caller.call_function("Dispatch")
        check(caller.Result == 21 and not caller.Accepted, "BP output addresses changed after native entry")
        check(target.BlueprintCalls == 1, "ProcessEvent also executed the original Blueprint body")
        registered = ue.get_registered_blueprint_scripts()
        check(len(registered) == 1 and registered[0]["calls"] == 4, "script call evidence is missing")
        check(target.get_class() == bp.GeneratedClass, "target class identity changed")
        ue.unregister_all_blueprint_scripts()
        check(ue.describe_function(bp.GeneratedClass, "Command") == signature_before, "function signature/flags were not restored")
        caller.call_function("Dispatch")
        check(target.BlueprintCalls == 2 and caller.Result == 7 and caller.Accepted, "original BP body was not restored")
        original_outputs = ue.call_function_by_class(target, bp.GeneratedClass, "Command", {"Amount": 13})
        check(original_outputs == {"Result": 13, "Accepted": True}, "original ProcessEvent outputs were not restored")
        check(target.BlueprintCalls == 3, "restored native entry did not execute BP exactly once")
        return {"status": "passed", "precompiled_caller": True, "output_parameters": outputs,
                "repeated_output_parameters": repeated_outputs, "restored_outputs": original_outputs,
                "class_identity_preserved": True, "no_blueprint_fallthrough": True, "registrations": registered}
    finally:
        ue.unregister_all_blueprint_scripts()
        for actor in reversed(actors):
            actor.actor_destroy()
        ue.allow_actor_script_execution_in_editor(False)


prefix = "-UEPBlueprintScriptBodyResult="
result_path = next((argument[len(prefix):] for argument in sys.argv if argument.startswith(prefix)), None)
if not result_path:
    raise RuntimeError(prefix + "<path> is required")
try:
    report = validate()
except Exception:
    report = {"status": "failed", "error": traceback.format_exc()}
Path(result_path).write_text(json.dumps(report, indent=2), encoding="utf-8")
ue.log("UEP_BLUEPRINT_SCRIPT_BODY_" + report["status"].upper())
if report["status"] != "passed":
    raise RuntimeError(report["error"])
