"""Reject a pre-quit pass when final gameplay/image evidence is incomplete."""
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import types
import unittest
from unittest.mock import patch


SOURCE = (Path(__file__).resolve().parents[2] / "Demos/UEPPythonThirdPerson/Overlay/Content/Scripts/uep_third_person/visible_validation.py")


class ThirdPersonVisibleShutdownTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.logs = []
        ue = types.ModuleType("unreal_engine")
        ue.log = lambda value: self.logs.append(("log", value))
        ue.log_error = lambda value: self.logs.append(("error", value))
        classes = types.ModuleType("unreal_engine.classes")
        classes.KismetSystemLibrary = object()
        utils = types.ModuleType("third_person_visible_test.utils")
        utils.command_line_value = lambda flag: None
        utils.gameplay_objects = lambda: ()
        utils.is_valid = lambda value: False
        package = types.ModuleType("third_person_visible_test")
        package.__path__ = []
        with patch.dict(sys.modules, {"unreal_engine": ue, "unreal_engine.classes": classes,
                "third_person_visible_test": package, "third_person_visible_test.utils": utils}):
            spec = importlib.util.spec_from_file_location("third_person_visible_test.visible_validation", SOURCE)
            self.module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(self.module)

    def make_probe(self, smoke=None):
        smoke = smoke if smoke is not None else dict(status="passed", error=None,
            teardown=dict(runtime_active=False, session_released=True))
        result_path = self.directory / "smoke.json"
        result_path.write_text(json.dumps(smoke), encoding="utf-8")
        # Do not install a process-exit handler in the test interpreter.
        probe = self.module.VisibleValidation.__new__(self.module.VisibleValidation)
        probe.smoke = types.SimpleNamespace(result_path=result_path)
        probe.directory, probe.frames, probe.errors = self.directory, [], []
        for phase in ("moving", "looking", "jumping"):
            image = self.directory / (phase + ".png")
            image.write_bytes(b"\x89PNG\r\n\x1a\nfixture-header-only")
            probe.frames.append(dict(phase=phase, image=str(image)))
        return probe

    def assert_rejected(self, probe):
        probe.write()
        report = json.loads((self.directory / "visible.json").read_text(encoding="utf-8"))
        self.assertEqual(report["status"], "failed")
        self.assertNotIn(("log", "UEP_THIRD_PERSON_VISIBLE_SHUTDOWN_PASSED"), self.logs)
        self.assertIn(("error", "UEP_THIRD_PERSON_VISIBLE_SHUTDOWN_FAILED"), self.logs)

    def test_complete_gameplay_cleanup_and_images_emit_final_marker(self):
        self.make_probe().write()
        self.assertEqual(self.logs, [("log", "UEP_THIRD_PERSON_VISIBLE_SHUTDOWN_PASSED")])

    def test_prequit_pass_does_not_override_missing_or_failed_teardown(self):
        for smoke in (dict(status="failed"), dict(status="passed"),
                dict(status="passed", teardown=dict(runtime_active=True, session_released=True)),
                dict(status="passed", teardown=dict(runtime_active=False, session_released=False)),
                dict(status="passed", error="late failure", teardown=dict(runtime_active=False, session_released=True))):
            with self.subTest(smoke=smoke):
                self.logs.clear()
                self.assert_rejected(self.make_probe(smoke))

    def test_missing_rendered_frame_blocks_final_marker(self):
        probe = self.make_probe()
        Path(probe.frames[0]["image"]).unlink()
        self.assert_rejected(probe)

    def test_incomplete_phase_capture_blocks_final_marker(self):
        probe = self.make_probe()
        probe.frames.pop()
        self.assert_rejected(probe)

    def test_state_name_alone_does_not_prove_native_animation_playback(self):
        for asset, position, playing in ((None, 0.0, True), ("BS_Idle_Walk_Run.BS_Idle_Walk_Run", 0.0, True),
                ("BS_Idle_Walk_Run.BS_Idle_Walk_Run", float("nan"), True),
                ("BS_Idle_Walk_Run.BS_Idle_Walk_Run", 0.2, False)):
            with self.subTest(asset=asset, position=position, playing=playing):
                self.logs.clear()
                probe = self.make_probe()
                probe.frames[0].update(animation_instance="AnimSingleNodeInstance", animation_asset=asset,
                    animation_position=position, animation_playing=playing)
                self.assert_rejected(probe)


if __name__ == "__main__":
    unittest.main()
