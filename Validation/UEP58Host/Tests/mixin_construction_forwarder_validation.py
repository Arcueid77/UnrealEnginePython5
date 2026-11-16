"""Explicit child Parent construction -> virtual helper -> parent Mixin router."""

import json
from pathlib import Path
import sys
import traceback
import uuid

import unreal_engine as ue
from unreal_engine.classes import Actor, KismetMathLibrary, UEPValidationObject


HELPER = "UEPConstructionBody"


def check(condition, message):
    if not condition:
        raise AssertionError(message)


def connect(source, source_pin, target, target_pin):
    source.node_find_pin(source_pin).make_link_to(target.node_find_pin(target_pin))


class PythonProfile:
    def Construction(self):
        self.set_property("PythonCalls", self.PythonCalls + 1)

    Construction.override = HELPER


class FallbackProfile:
    def Construction(self):
        self.call_mixin_original(HELPER)

    Construction.override = HELPER


def spawn(world, cls, profile):
    transform = ue.FTransform()
    statics = ue.find_class("GameplayStatics").get_cdo()
    actor = statics.call_function("BeginDeferredActorSpawnFromClass", world, cls, transform, 1, None)
    ue.set_mixin_profile(actor, profile)
    statics.call_function("FinishSpawningActor", actor, transform)
    return actor


def validate():
    suffix = uuid.uuid4().hex
    parent = ue.create_blueprint(Actor, "/Game/UEPValidation/ConstructionParent_" + suffix)
    for name in ("BlueprintCalls", "PythonCalls"):
        ue.blueprint_add_member_variable(parent, name, "int")
    ue.compile_blueprint(parent)
    graph = next(g for g in ue.blueprint_get_all_graphs(parent) if g.get_name() == "UserConstructionScript")
    entry = next(node for node in graph.Nodes if node.get_class().get_name() == "K2Node_FunctionEntry")
    entry.node_find_pin("then").break_all_pin_links(True)
    read = graph.graph_add_node_variable_get("BlueprintCalls")
    add = graph.graph_add_node_call_function(KismetMathLibrary.Add_IntInt)
    add.node_find_pin("B").default_value = "1"
    write = graph.graph_add_node_variable_set("BlueprintCalls")
    connect(entry, "then", write, "execute")
    connect(read, "BlueprintCalls", add, "A")
    connect(add, "ReturnValue", write, "BlueprintCalls")
    ue.compile_blueprint(parent)
    original_node_count = len(graph.Nodes)
    helper = ue.blueprint_extract_construction_helper(parent, HELPER)
    ue.compile_blueprint(parent)
    check(len(helper.Nodes) == original_node_count, "original BP body was not preserved")
    check(len(graph.Nodes) == 2, "construction is not a thin two-node forwarder")
    child = ue.create_blueprint(parent.GeneratedClass, "/Game/UEPValidation/ConstructionChild_" + suffix)
    ue.compile_blueprint(child)
    child_graph = next(g for g in ue.blueprint_get_all_graphs(child) if g.get_name() == "UserConstructionScript")
    parents = [node for node in child_graph.Nodes if node.get_class().get_name() == "K2Node_CallParentFunction"]
    check(len(parents) == 1, "fixture must contain a real explicit Parent construction call")
    # Negative authoring operations must leave the original forwarder unchanged.
    rejected = []
    for name in (HELPER, "UserConstructionScript", "Bad/Name", ""):
        try:
            ue.blueprint_extract_construction_helper(parent, name)
        except ValueError:
            rejected.append(name)
        else:
            raise AssertionError("invalid/duplicate helper was accepted: " + name)
    non_actor = ue.create_blueprint(UEPValidationObject, "/Game/UEPValidation/ConstructionInvalid_" + suffix)
    ue.compile_blueprint(non_actor)
    try:
        ue.blueprint_extract_construction_helper(non_actor, HELPER)
    except TypeError:
        rejected.append("non-actor")
    else:
        raise AssertionError("non-Actor helper was accepted")
    actors = []
    ue.allow_actor_script_execution_in_editor(True)
    try:
        ue.register_mixin_profile(parent.GeneratedClass, "Python", PythonProfile, make_default=True)
        ue.register_mixin_profile(parent.GeneratedClass, "BlueprintFallback", FallbackProfile)
        world = ue.get_editor_world()
        candidate = spawn(world, child.GeneratedClass, "Python")
        baseline = spawn(world, child.GeneratedClass, "BlueprintFallback")
        actors.extend((candidate, baseline))
        check((candidate.PythonCalls, candidate.BlueprintCalls) == (1, 0), "Parent call bypassed Python or ran BP too")
        check((baseline.PythonCalls, baseline.BlueprintCalls) == (0, 1), "Parent fallback did not run original body once")
        check(candidate.get_class() == baseline.get_class() == child.GeneratedClass, "child class changed")
        ue.set_mixin_profile(candidate, "BlueprintFallback")
        candidate.call_function("UserConstructionScript")
        check((candidate.PythonCalls, candidate.BlueprintCalls) == (1, 1), "same child profile switch bypassed helper")
        ue.unregister_mixin(parent.GeneratedClass)
        candidate.call_function("UserConstructionScript")
        check((candidate.PythonCalls, candidate.BlueprintCalls) == (1, 2), "unregister did not restore BP helper")
        return {"status": "passed", "explicit_parent_call": True, "virtual_helper": True,
                "related_child_router_used": False, "same_class": True, "no_bp_fallthrough": True,
                "original_body_preserved": True, "profile_round_trip": True, "restore": True,
                "construction_nodes": len(graph.Nodes), "body_nodes": len(helper.Nodes), "rejected": rejected}
    finally:
        ue.unregister_all_mixins()
        for actor in actors:
            actor.actor_destroy()
        ue.allow_actor_script_execution_in_editor(False)


prefix = "-UEPConstructionForwarderResult="
result = next(value[len(prefix):] for value in sys.argv if value.startswith(prefix))
try:
    report = validate()
except Exception:
    report = {"status": "failed", "error": traceback.format_exc()}
Path(result).write_text(json.dumps(report, indent=2), encoding="utf-8")
ue.log("UEP_CONSTRUCTION_FORWARDER_" + report["status"].upper())
if report["status"] != "passed":
    raise RuntimeError(report["error"])
