"""Run Examples policy tests with workspace-owned temporary/evidence paths."""

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest
from uep_test_scope import TEST_ROOTS, changed_paths, plan


parser = argparse.ArgumentParser()
parser.add_argument("--result", required=True)
parser.add_argument("--all", action="store_true", help="Explicit full host regression")
parser.add_argument("--test-pattern", action="append", default=[], help="Add affected test files, e.g. test_footstep_*.py")
parser.add_argument("--changes-file", help="JSON array of repository-relative changed paths from an isolated index")
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
build = (repo / ".build").resolve()
result_path = Path(args.result).resolve()
result_path.relative_to(build)  # Evidence stays inside the permitted workspace.
temporary_root = build / "HostTestTemp"
temporary_root.mkdir(parents=True, exist_ok=True)
tempfile.tempdir = str(temporary_root)
changed = json.loads(Path(args.changes_file).read_text(encoding="utf-8-sig")) if args.changes_file else changed_paths(repo)
selection = plan(repo, changed, patterns=args.test_pattern, full=args.all)
if selection["status"] != "ready":
    report = dict(schema_version=2, status="failed", tests_run=0, failures=0, errors=0, skipped=0,
        runtime_acceptance=False, selection=selection,
        error="No affected tests could be identified; add --test-pattern for the changed feature or explicitly request --all.")
    result_path.parent.mkdir(parents=True, exist_ok=True)
    result_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(report["error"], file=sys.stderr); sys.exit(2)
suite = unittest.TestSuite()
if args.all:
    for root in TEST_ROOTS:
        path = repo/root
        if path.exists(): suite.addTests(unittest.TestLoader().discover(str(path), pattern="test_*.py", top_level_dir=str(path)))
else:
    for name in selection["selected_test_files"]:
        path = repo/name
        suite.addTests(unittest.TestLoader().discover(str(path.parent), pattern=path.name, top_level_dir=str(path.parent)))
result = unittest.TextTestRunner(verbosity=1).run(suite)
report = {"schema_version": 2, "status": "passed" if result.wasSuccessful() else "failed",
          "tests_run": result.testsRun, "failures": len(result.failures), "errors": len(result.errors),
          "skipped": len(result.skipped), "runtime_acceptance": False,
          "temporary_root": str(temporary_root), "selection": selection,
          "failed_cases": [test.id() for test, trace in result.failures + result.errors]}
result_path.parent.mkdir(parents=True, exist_ok=True)
result_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
sys.exit(not result.wasSuccessful())
