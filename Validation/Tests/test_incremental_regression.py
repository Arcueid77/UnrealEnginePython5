"""Incremental selection and real CLI isolation using tiny disposable fixtures."""
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

VALIDATION = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(VALIDATION))
from uep_test_scope import changed_paths, plan

SCRIPTS = "Demos/UEPLyraIntegration/Overlay/Content/Scripts/"
TESTS = "Demos/UEPLyraIntegration/Tests/"


class IncrementalRegressionTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(); self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.write(SCRIPTS+"feature/__init__.py", "")
        self.write(SCRIPTS+"feature/base.py", "value = 1\n")
        self.write(SCRIPTS+"feature/child.py", "from .base import value\n")
        self.write(SCRIPTS+"other.py", "value = 2\n")
        self.write(TESTS+"test_child.py", "from feature.child import value\n")
        self.write(TESTS+"test_other.py", "import other\n")
    def write(self, name, text):
        path = self.root/name; path.parent.mkdir(parents=True, exist_ok=True); path.write_text(text, encoding="utf-8")
    def test_leaf_change_excludes_unrelated_test(self):
        result = plan(self.root, [SCRIPTS+"feature/child.py"])
        self.assertEqual(result["selected_test_files"], [TESTS+"test_child.py"])
        self.assertEqual(result["mode"], "incremental")
    def test_staged_scope_includes_committed_but_unlinked_examples_changes(self):
        seen = []
        def git(command, **kwargs):
            seen.append(command)
            if "rev-parse" in command: return "examples-base\n"
            return "feature.py\0" if command[2].endswith("Demos") else "Validation/runner.py\0Demos\0"
        with patch("uep_test_scope.subprocess.check_output", side_effect=git):
            self.assertEqual(changed_paths(self.root, staged=True), ["Demos/feature.py", "Validation/runner.py"])
        self.assertTrue(any(command[2].endswith("Demos") and "--cached" in command and "examples-base" in command for command in seen))
    def test_base_change_reaches_relative_import_and_its_tests(self):
        result = plan(self.root, [SCRIPTS+"feature/base.py"])
        self.assertEqual(result["selected_test_files"], [TESTS+"test_child.py"])
        self.assertEqual(result["unmapped_changed_files"], [])
    def test_package_initializer_reaches_importing_tests(self):
        self.assertEqual(plan(self.root, [SCRIPTS+"feature/__init__.py"])["selected_test_files"], [TESTS+"test_child.py"])
    def test_literal_module_loader_and_python_file_reference(self):
        self.write(TESTS+"test_dynamic.py", 'module = "feature.base"\nfile = "other.py"\n')
        result = plan(self.root, [SCRIPTS+"other.py"])
        self.assertEqual(result["selected_test_files"], [TESTS+"test_dynamic.py", TESTS+"test_other.py"])
        self.assertIn(TESTS+"test_dynamic.py", plan(self.root, [SCRIPTS+"feature/base.py"])["selected_test_files"])
    def test_deleted_module_still_selects_original_consumers(self):
        (self.root/(SCRIPTS+"feature/base.py")).unlink()
        self.assertEqual(plan(self.root, [SCRIPTS+"feature/base.py"])["selected_test_files"], [TESTS+"test_child.py"])
    def test_asset_and_manifest_literal_dependencies(self):
        self.write(SCRIPTS+"feature/base.py", 'asset = "Content/Effects/B_Footstep.uasset"\n')
        self.assertEqual(plan(self.root, ["Demos/UEPLyraIntegration/Overlay/Content/Effects/B_Footstep.uasset"])["selected_test_files"], [TESTS+"test_child.py"])
        self.write(TESTS+"test_manifest.py", 'file = "batches.json"\n')
        self.assertEqual(plan(self.root, ["Demos/UEPLyraIntegration/Migration/batches.json"])["selected_test_files"], [TESTS+"test_manifest.py"])
    def test_unknown_code_dependency_requires_explicit_scope(self):
        result = plan(self.root, ["Content/Unmapped.uasset"])
        self.assertEqual(result["status"], "scope_required")
        self.assertEqual(result["selected_test_files"], [])
    def test_explicit_patterns_extend_scope_and_typos_fail(self):
        result = plan(self.root, [SCRIPTS+"feature/child.py"], patterns=["test_other.py"])
        self.assertEqual(len(result["selected_test_files"]), 2)
        with self.assertRaises(ValueError): plan(self.root, [], patterns=["test_missing_*.py"])
    def test_documents_and_empty_changes_do_not_trigger_full_suite(self):
        for changes in ([], ["README.md"]):
            result = plan(self.root, changes)
            self.assertEqual(result["status"], "ready"); self.assertFalse(result["selected_test_files"])
            self.assertFalse(result["full_regression_requested"])
    def test_full_mode_requires_explicit_request(self):
        self.assertEqual(len(plan(self.root, [], full=True)["selected_test_files"]), 2)
        self.assertEqual(plan(self.root, [], full=True)["mode"], "full")
    def test_unaffected_syntax_error_does_not_become_full_regression(self):
        self.write(SCRIPTS+"other.py", "def broken(\n")
        result = plan(self.root, [SCRIPTS+"feature/child.py"])
        self.assertEqual(result["selected_test_files"], [TESTS+"test_child.py"])
        self.assertEqual(result["unparsed_unaffected_files"], [SCRIPTS+"other.py"])
        with self.assertRaises(SyntaxError): plan(self.root, [SCRIPTS+"other.py"])
    def run_cli(self, *options, changed=None):
        for name in ("Run-UEPLyraHostTests.py", "uep_test_scope.py"):
            destination = self.root/"Validation"/name; destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(VALIDATION/name, destination)
        self.write(TESTS+"test_child.py", "import unittest\nclass Selected(unittest.TestCase):\n def test_selected(self): self.assertTrue(True)\n")
        self.write(TESTS+"test_other.py", "import unittest\nclass Unrelated(unittest.TestCase):\n def test_unrelated(self): self.fail('unrelated failure must not run incrementally')\n")
        self.write(".build/changes.json", json.dumps(changed if changed is not None else [TESTS+"test_child.py"]))
        result = subprocess.run([sys.executable, "-B", str(self.root/"Validation/Run-UEPLyraHostTests.py"),
            "--result", str(self.root/".build/result.json"), "--changes-file", str(self.root/".build/changes.json"), *options], capture_output=True, text=True)
        return result, json.loads((self.root/".build/result.json").read_text())
    def test_cli_runs_one_selected_test_and_skips_unrelated_failure(self):
        process, result = self.run_cli()
        self.assertEqual(process.returncode, 0, process.stderr); self.assertEqual(result["tests_run"], 1)
        self.assertEqual(result["selection"]["selected_test_files"], [TESTS+"test_child.py"])
    def test_cli_explicit_full_mode_detects_unrelated_fixture_failure(self):
        process, result = self.run_cli("--all")
        self.assertEqual(process.returncode, 1); self.assertEqual(result["tests_run"], 2)
        self.assertEqual(result["selection"]["mode"], "full")
    def test_cli_unknown_scope_fails_without_silently_running_all(self):
        process, result = self.run_cli(changed=["Content/Unmapped.uasset"])
        self.assertEqual(process.returncode, 2); self.assertEqual(result["tests_run"], 0)
        self.assertEqual(result["selection"]["status"], "scope_required")
