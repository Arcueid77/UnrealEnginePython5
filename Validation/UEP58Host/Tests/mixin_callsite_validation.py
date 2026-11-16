"""A precompiled caller Blueprint routes to two existing same-class Actors.

Runs with the Py commandlet. Only in-memory fixture Blueprints are compiled;
no reference assets, Engine sources or package files are modified.
"""

import json
from pathlib import Path
import sys
import traceback
import uuid

import unreal_engine as ue
from unreal_engine.classes import Actor, KismetMathLibrary
from unreal_engine.structs import EdGraphPinType


def check(condition, message):
    if not condition:
        raise AssertionError(message)


def connect(source, source_pin, target, target_pin):
    source.node_find_pin(source_pin).make_link_to(target.node_find_pin(target_pin))


def compile_fixture(blueprint):
    ue.compile_blueprint(blueprint)
    check(blueprint.GeneratedClass is not None, "fixture has no generated class")


def create_target(path):
    blueprint = ue.create_blueprint(Actor, path)
    for name in ("BlueprintCalls", "PythonCalls", "LastRoute"):
        ue.blueprint_add_member_variable(blueprint, name, "int")
    compile_fixture(blueprint)
    graph = ue.blueprint_add_function(blueprint, "RunCommand")
    entry = graph.Nodes[0]
    read_count = graph.graph_add_node_variable_get("BlueprintCalls")
    add = graph.graph_add_node_call_function(KismetMathLibrary.Add_IntInt)
    add.node_find_pin("B").default_value = "1"
    write_count = graph.graph_add_node_variable_set("BlueprintCalls")
    write_route = graph.graph_add_node_variable_set("LastRoute")
    write_route.node_find_pin("LastRoute").default_value = "1"
    connect(entry, "then", write_count, "execute")
    connect(read_count, "BlueprintCalls", add, "A")
    connect(add, "ReturnValue", write_count, "BlueprintCalls")
    connect(write_count, "then", write_route, "execute")
    compile_fixture(blueprint)
    return blueprint


def create_caller(path, target_class):
    blueprint = ue.create_blueprint(Actor, path)
    ue.blueprint_add_member_variable(
        blueprint, "Target", EdGraphPinType(PinCategory="object", PinSubCategoryObject=target_class)
    )
    compile_fixture(blueprint)
    graph = ue.blueprint_add_function(blueprint, "Dispatch")
    entry = graph.Nodes[0]
    target = graph.graph_add_node_variable_get("Target")
    call = graph.graph_add_node_call_function(target_class.RunCommand)
    connect(entry, "then", call, "execute")
    connect(target, "Target", call, "self")
    compile_fixture(blueprint)
    return blueprint


class PythonCommandProfile:
    def RunCommand(self):
        # This fixture runs in an Editor world. Attribute assignment emits
        # PostEditChange and may rerun construction; runtime-style reflected
        # writes avoid turning this dispatch test into an editor-edit test.
        self.set_property("PythonCalls", self.get_property("PythonCalls") + 1)
        self.set_property("LastRoute", 2)


class MissingCommandProfile:
    # Profiles need at least one reflected method. This unused inherited event
    # deliberately does NOT implement the union's RunCommand method.
    def ReceiveBeginPlay(self):
        self.call_mixin_original("ReceiveBeginPlay")


def snapshot(actor):
    return {
        "class": actor.get_class().get_path_name(),
        "actor": actor.get_path_name(),
        "blueprint_calls": actor.get_property("BlueprintCalls"),
        "python_calls": actor.get_property("PythonCalls"),
        "last_route": actor.get_property("LastRoute"),
    }


def validate():
    suffix = uuid.uuid4().hex
    target_bp = create_target("/Game/UEPValidation/TransientTarget_" + suffix)
    target_class = target_bp.GeneratedClass
    # Compile before injection: do not manufacture a callsite already pointing
    # at a Python function and mistake that for replacement of an existing BP.
    caller_bp = create_caller("/Game/UEPValidation/TransientCaller_" + suffix, target_class)
    world = ue.get_editor_world()
    actors = []
    evidence = {"caller_compiled_before_registration": True, "phases": []}
    registered = False
    ue.allow_actor_script_execution_in_editor(True)
    try:
        for cls in (target_class, target_class, caller_bp.GeneratedClass):
            actors.append(world.actor_spawn(cls))
        first, second, caller = actors

        def dispatch_both(phase, expected):
            for actor in (first, second):
                caller.set_property("Target", actor)
                check(caller.get_property("Target") == actor, "caller reference did not bind")
                caller.call_function("Dispatch")  # Only the caller entry is invoked from Python.
            actual = [snapshot(first), snapshot(second)]
            check(first.get_class() == target_class == second.get_class(), "target class changed")
            check(
                [(item["blueprint_calls"], item["python_calls"], item["last_route"]) for item in actual] == expected,
                phase + ": " + repr(actual),
            )
            evidence["phases"].append({"name": phase, "targets": actual})

        dispatch_both("original", [(1, 0, 1), (1, 0, 1)])
        ue.register_mixin_profile(target_class, "Python", PythonCommandProfile, make_default=True)
        registered = True
        ue.register_mixin_profile(target_class, "Missing", MissingCommandProfile)
        ue.set_mixin_profile(first, "Python")
        ue.set_mixin_profile(second, "Missing")
        dispatch_both("mixed", [(1, 1, 2), (2, 0, 1)])
        # The union includes this parameterless native event via Missing's
        # profile, but Python omits it. Its original has no parameter/local
        # storage, unlike the RunCommand graph, and must not allocate null.
        first.call_function("ReceiveBeginPlay")
        evidence["zero_parameter_native_fallback"] = True
        # Repeated calls must not fall through to the BP after Python success.
        dispatch_both("mixed_again", [(1, 2, 2), (3, 0, 1)])
        ue.set_mixin_profile(first, "Missing")
        ue.set_mixin_profile(second, "Python")
        dispatch_both("profiles_swapped", [(2, 2, 1), (3, 1, 2)])
        check(ue.unregister_mixin(target_class), "router was not unregistered")
        registered = False
        dispatch_both("restored", [(3, 2, 1), (4, 1, 1)])
        evidence["same_class"] = True
        evidence["restoration_passed"] = True
        evidence["caller_class"] = caller_bp.GeneratedClass.get_path_name()
        return evidence
    finally:
        if registered:
            ue.unregister_mixin(target_class)
        for actor in reversed(actors):
            actor.actor_destroy()
        ue.allow_actor_script_execution_in_editor(False)


result_path = next((argument.split("=", 1)[1].strip('"') for argument in sys.argv if argument.startswith("-UEPMixinCallsiteResult=")), None)
if not result_path:
    raise RuntimeError("-UEPMixinCallsiteResult=<path> is required")

report = {
    "schema_version": 1,
    "status": "failed",
    "engine_version": [ue.ENGINE_MAJOR_VERSION, ue.ENGINE_MINOR_VERSION],
    "python_version": sys.version.split()[0],
    "fixture_scope": "in-memory Editor Actors and precompiled Blueprint callsite",
    "assets_saved": False,
}
try:
    report["evidence"] = validate()
    report["status"] = "passed"
    ue.log("UEP_MIXIN_CALLSITE_PASSED")
except Exception:
    report["error"] = traceback.format_exc()
    ue.log_error("UEP_MIXIN_CALLSITE_FAILED " + report["error"])
finally:
    Path(result_path).write_text(json.dumps(report, indent=2), encoding="utf-8")
if report["status"] != "passed":
    raise RuntimeError(report["error"])
