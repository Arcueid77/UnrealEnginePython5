"""Report after a deliberately failing ue_site dependency import."""

import json
from pathlib import Path
import sys

import unreal_engine as ue
from uep_runtime import SubscriptionScope


prefix = "-UEPBootstrapResult="
result = next((value[len(prefix):] for value in sys.argv if value.startswith(prefix)), None)
if result is None:
    raise RuntimeError(prefix + "<path> is required")
scope = SubscriptionScope()
scope.close()
Path(result).write_text(json.dumps({"status": "passed", "helper_imported": True,
                                   "expected_missing_dependency": "uep_validation_expected_missing_dependency"}), encoding="utf-8")
ue.log("UEP_BOOTSTRAP_DEPENDENCY_PASSED")
