"""Three real PIE sessions in one Editor, with placed/spawned routed Actors.

Loaded by the validation host's opt-in ue_site hook. No asset is saved. Uses
the native LevelEditorSubsystem to end PIE and native UE GC between sessions.
"""

import gc
import json
from pathlib import Path
import sys
import time
import traceback
import uuid

import unreal_engine as ue
from unreal_engine.classes import KismetSystemLibrary, UEPValidationActor, UEPValidationObject
from unreal_engine.structs import EdGraphPinType
from uep_runtime import SubscriptionScope


def argument(name):
    prefix = "-" + name + "="
    return next((value[len(prefix):].strip('"') for value in sys.argv if value.startswith(prefix)), None)


def check(condition, message):
    if not condition:
        raise AssertionError(message)


def valid(obj):
    try:
        return obj is not None and obj.is_valid()
    except Exception:
        return False


class PIEValidation:
    def __init__(self):
        self.result = Path(argument("UEPPIEResult"))
        self.started = time.monotonic()
        self.phase = "startup"
        self.phase_started = self.started
        self.cycle = 0
        self.events = []
        self.scopes = []
        self.sessions = []
        self.actors = []
        self.placed = None
        self.blueprint = None
        self.cls = None
        self.original = None
        self.registered = False
        self.subsystem = None
        self.finished = False

    def transition(self, phase):
        self.phase = phase
        self.phase_started = time.monotonic()

    def record(self, actor, event):
        world = actor.get_world()
        self.events.append({"cycle": self.cycle, "event": event,
                            "actor": actor.get_path_name(), "world": world.get_path_name(),
                            "world_type": world.get_world_type()})

    def profile(self):
        owner = self

        class LifecycleProfile:
            def UserConstructionScript(self):
                owner.record(self, "construction")

            def ReceiveBeginPlay(self):
                owner.record(self, "begin")
                source = ue.new_object(UEPValidationObject, self)
                self.SignalSource = source  # Reflected UPROPERTY owns the native object.
                scope = SubscriptionScope()
                calls = []
                scope.bind_event(source, "OnSignal", calls.append)
                source.call_function("BroadcastSignal", 77)
                check(calls == [77], "native delegate did not enter Python")
                self._pie_scope = scope
                self._pie_signal_calls = calls
                owner.scopes.append(scope)
                owner.actors.append(self)

            def ReceiveEndPlay(self, EndPlayReason):
                owner.record(self, "end")
                self._pie_scope.close()
                self.SignalSource.call_function("BroadcastSignal", 88)
                check(self._pie_signal_calls == [77], "closed scope received a native callback")

            def __uep_mixin_teardown__(self):
                scope = getattr(self, "_pie_scope", None)
                if scope is not None:
                    scope.close()

        return LifecycleProfile

    def setup(self):
        import unreal
        native = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
        self.subsystem = ue.find_object(native.get_path_name())
        self.blueprint = ue.create_blueprint(UEPValidationActor,
                                            "/Game/UEPValidation/TransientPIE_" + uuid.uuid4().hex)
        ue.blueprint_add_member_variable(self.blueprint, "SignalSource",
                                         EdGraphPinType(PinCategory="object", PinSubCategoryObject=UEPValidationObject))
        ue.compile_blueprint(self.blueprint)
        self.cls = self.blueprint.GeneratedClass
        self.placed = ue.get_editor_world().actor_spawn(self.cls)
        self.original = self.placed.find_function("UserConstructionScript")
        self.start_session()

    def start_session(self):
        self.cycle += 1
        ue.register_mixin_profile(self.cls, "Python", self.profile(), make_default=True)
        self.registered = True
        self.actors = []
        self.scopes = []
        ue.request_play_session(True, False)
        self.transition("begin")

    def tick(self, delta):
        try:
            if time.monotonic() - self.started > 150:
                raise TimeoutError("PIE lifecycle timeout in " + self.phase)
            if self.phase == "startup":
                if time.monotonic() - self.phase_started > 3:
                    self.setup()
            elif self.phase == "begin":
                current = [item for item in self.events if item["cycle"] == self.cycle and item["event"] == "begin"]
                if current:
                    check(len(current) == 1, "expected exactly one placed Actor at PIE start")
                    world = self.actors[0].get_world()
                    check(world.get_world_type() == 3, "BeginPlay did not run in a PIE world")
                    world.actor_spawn(self.cls)
                    self.transition("running")
            elif self.phase == "running":
                current = [item for item in self.events if item["cycle"] == self.cycle]
                begins = [item for item in current if item["event"] == "begin"]
                if len(begins) == 2 and time.monotonic() - self.phase_started > 0.5:
                    check(len({item["actor"] for item in begins}) == 2, "placed/spawned actors were not distinct")
                    spawned = begins[1]["actor"]
                    check(any(item["event"] == "construction" and item["actor"] == spawned for item in current),
                          "spawned Actor did not enter Python construction")
                    check(all(actor.get_class() == self.cls for actor in self.actors), "PIE changed routed Actor class")
                    self.subsystem.call_function("EditorRequestEndPlay")
                    self.transition("end")
            elif self.phase == "end":
                if not self.subsystem.call_function("IsInPlayInEditor"):
                    current = [item for item in self.events if item["cycle"] == self.cycle]
                    ends = [item for item in current if item["event"] == "end"]
                    check(len(ends) == 2, "EndPlay did not reach both Python Actors")
                    check(len(self.scopes) == 2 and all(scope.closed and scope.count == 0 for scope in self.scopes),
                          "PIE left a subscription active")
                    check(ue.unregister_mixin(self.cls), "PIE router did not unregister")
                    self.registered = False
                    check(self.placed.find_function("UserConstructionScript") == self.original,
                          "original function was not restored")
                    KismetSystemLibrary.get_cdo().call_function("CollectGarbage")
                    self.transition("gc")
            elif self.phase == "gc" and time.monotonic() - self.phase_started > 0.5:
                gc.collect()
                ue.py_gc()
                check(not any(valid(actor) for actor in self.actors), "PIE native Actors survived teardown/GC")
                self.sessions.append({"cycle": self.cycle, "placed_and_spawned": True,
                                      "construction": True, "begin_end_counts": [2, 2],
                                      "closed_scopes": len(self.scopes), "native_gc_collected": True,
                                      "router_restored": True})
                if self.cycle < 3:
                    self.start_session()
                else:
                    self.finish()
            return not self.finished
        except Exception:
            self.finish(traceback.format_exc())
            return False

    def finish(self, error=None):
        self.finished = True
        try:
            if self.subsystem is not None and self.subsystem.call_function("IsInPlayInEditor"):
                self.subsystem.call_function("EditorRequestEndPlay")
            for scope in self.scopes:
                scope.close()
            if self.registered:
                ue.unregister_mixin(self.cls)
            if valid(self.placed):
                self.placed.actor_destroy()
        except Exception:
            error = (error or "") + "\nCleanup: " + traceback.format_exc()
        report = {"schema_version": 1, "status": "failed" if error else "passed",
                  "same_editor_process": True, "sessions": self.sessions,
                  "events": self.events, "error": error}
        self.result.parent.mkdir(parents=True, exist_ok=True)
        self.result.write_text(json.dumps(report, indent=2), encoding="utf-8")
        if error:
            ue.log_error("UEP_MIXIN_PIE_FAILED " + error)
        else:
            ue.log("UEP_MIXIN_PIE_PASSED")
        ue.console_exec("QUIT_EDITOR")


validation = PIEValidation()
ticker = ue.add_ticker(validation.tick)
