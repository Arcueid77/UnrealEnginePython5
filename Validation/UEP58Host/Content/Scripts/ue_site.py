"""Opt-in Editor lifecycle tests; ordinary validation startup has no side effects."""

import importlib.util
import sys

if "-UEPBootstrapMissingDependency" in sys.argv:
    import uep_validation_expected_missing_dependency


for argument in sys.argv:
    if argument.startswith("-UEPPIEScript="):
        path = argument.split("=", 1)[1].strip('"')
        spec = importlib.util.spec_from_file_location("uep_pie_validation", path)
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        spec.loader.exec_module(module)
        break
