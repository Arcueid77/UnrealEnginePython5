"""Run Examples policy tests with workspace-owned temporary/evidence paths."""

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


parser = argparse.ArgumentParser()
parser.add_argument("--result", required=True)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
build = (repo / ".build").resolve()
result_path = Path(args.result).resolve()
result_path.relative_to(build)  # Evidence stays inside the permitted workspace.
temporary_root = build / "HostTestTemp"
temporary_root.mkdir(parents=True, exist_ok=True)
tempfile.tempdir = str(temporary_root)
suite = unittest.defaultTestLoader.discover(str(repo / "Demos/UEPLyraIntegration/Tests"), pattern="test_*.py")
result = unittest.TextTestRunner(verbosity=1).run(suite)
report = {"schema_version": 1, "status": "passed" if result.wasSuccessful() else "failed",
          "tests_run": result.testsRun, "failures": len(result.failures), "errors": len(result.errors),
          "skipped": len(result.skipped), "runtime_acceptance": False,
          "temporary_root": str(temporary_root),
          "failed_cases": [test.id() for test, trace in result.failures + result.errors]}
result_path.parent.mkdir(parents=True, exist_ok=True)
result_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
sys.exit(not result.wasSuccessful())
