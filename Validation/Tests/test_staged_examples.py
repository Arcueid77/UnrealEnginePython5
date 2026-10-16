"""Index isolation tests; no native runtime or private-source reads."""
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

FILE = Path(__file__).resolve().parents[1] / "Inspect-UEPStagedExamples.py"
SPEC = importlib.util.spec_from_file_location("staged_examples_checker", FILE)
CHECKER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECKER)


class IndexScopeTests(unittest.TestCase):
    def inspect(self, *, all_index=False, broken=False):
        seen = []
        def git(command, **kwargs):
            values = command[3:]
            if values[0] == "ls-files":
                return "selected.py\nexisting.py\n.nepy/private.py\n"
            if values[0] == "diff":
                return "selected.py\n"
            seen.append(values[1])
            if values[1] == ":existing.py" and broken:
                return "def broken(\n"
            return "value = 1\n"
        with patch.object(CHECKER.subprocess, "check_output", side_effect=git), \
             patch.object(Path, "rglob", return_value=iter(())):
            result = CHECKER.inspect(Path("F:/index-scope-fixture"), all_index=all_index)
        return result, seen

    def test_default_checks_only_selected_index_files(self):
        result, seen = self.inspect(broken=True)
        self.assertEqual(result["checked_scope"], "staged_changes")
        self.assertEqual(seen, [":selected.py"])

    def test_all_index_checks_previously_committed_files(self):
        result, seen = self.inspect(all_index=True)
        self.assertEqual(result["checked_scope"], "all_index")
        self.assertEqual(result["staged_python_files"], 2)
        self.assertEqual(set(seen), {":selected.py", ":existing.py"})

    def test_all_index_rejects_syntax_error_outside_selected_batch(self):
        with self.assertRaises(SyntaxError):
            self.inspect(all_index=True, broken=True)
