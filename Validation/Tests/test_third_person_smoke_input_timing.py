"""A pre-input render hitch must not consume the movement observation window."""
import ast
from pathlib import Path
from types import SimpleNamespace
import unittest


SOURCE = Path(__file__).resolve().parents[2] / 'Demos/UEPPythonThirdPerson/Mixin/Content/Scripts/uep_third_person_mixin/smoke.py'


class Location:
    def __sub__(self, other):
        return self

    def length(self):
        return 0.0


class ThirdPersonSmokeInputTimingTests(unittest.TestCase):
    def test_initial_hitch_does_not_expire_newly_pressed_movement(self):
        tree = ast.parse(SOURCE.read_text(encoding='utf-8-sig'))
        smoke_class = next(node for node in tree.body if isinstance(node, ast.ClassDef) and node.name == 'MixinThirdPersonSmoke')
        tick = next(node for node in smoke_class.body if isinstance(node, ast.FunctionDef) and node.name == 'tick')
        pawn = SimpleNamespace(get_actor_location=lambda: Location())
        namespace = {'gameplay_objects': lambda: (object(), object(), object(), pawn),
                     'is_valid': lambda value: value is not None, 'PRESSED': 0}
        exec(compile(ast.Module(body=[tick], type_ignores=[]), str(SOURCE), 'exec'), namespace)
        for phase in ('profile_fallback_move', 'moving'):
            with self.subTest(phase=phase):
                probe = SimpleNamespace(elapsed=0.0, phase_elapsed=0.0, phase_ticks=0,
                    runtime=SimpleNamespace(last_error=None), phase=phase, held_keys=set(), start_location=Location())
                probe._set_key = lambda controller, key, event, amount: probe.held_keys.add(key)
                self.assertTrue(namespace['tick'](probe, 1.5))
                self.assertEqual(probe.phase, phase)
                self.assertEqual(probe.held_keys, {'W'})
                self.assertEqual(probe.phase_elapsed, 0.0)
                self.assertEqual(probe.phase_ticks, 0)
