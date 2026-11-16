"""Soft-class input strings remain lazy and malformed object paths fail."""

import json
from pathlib import Path
import sys
import traceback

import unreal_engine as ue


def check(condition, message):
    if not condition:
        raise AssertionError(message)


def loaded_object(path):
    try:
        return ue.find_object(path)
    except Exception as error:
        check("unable to find object" in str(error), "unexpected object lookup failure: " + str(error))
        return None


def validate():
    library = ue.find_class("KismetSystemLibrary").get_cdo()
    unloaded = "/Game/UEPValidation/Lazy_Unloaded.Lazy_Unloaded_C"
    check(loaded_object(unloaded) is None, "unloaded fixture path already exists")
    value = library.call_function("Conv_SoftClassReferenceToString", unloaded)
    check(str(value) == unloaded and loaded_object(unloaded) is None, "soft class conversion loaded or changed path")
    native = library.call_function("Conv_SoftClassReferenceToString", "/Script/Engine.Actor")
    check(str(native) == "/Script/Engine.Actor", "native soft class path differs")
    check(str(library.call_function("Conv_SoftClassReferenceToString", "")) == "", "empty soft class is not null")
    rejected = []
    for path in ("not-a-path", "/Game/NoAssetName", "relative.Asset_C", "/Game/Invalid Name.Invalid Name_C", "/Script/Engine.Actor\0suffix"):
        try:
            library.call_function("Conv_SoftClassReferenceToString", path)
        except TypeError:
            rejected.append(path)
        else:
            raise AssertionError("invalid soft class path accepted: " + path)
    loaded = library.call_function("Conv_SoftClassReferenceToString", ue.find_class("Actor"))
    check(str(loaded) == "/Script/Engine.Actor", "existing loaded UClass input compatibility changed")
    return {"status": "passed", "lazy_path": str(value), "no_load": True,
            "native_class": str(native), "empty_null": True, "loaded_class_compatible": True, "rejected": rejected}


prefix = "-UEPSoftClassPathResult="
result = next(value[len(prefix):] for value in sys.argv if value.startswith(prefix))
try:
    report = validate()
except Exception:
    report = {"status": "failed", "error": traceback.format_exc()}
Path(result).write_text(json.dumps(report, indent=2), encoding="utf-8")
ue.log("UEP_SOFT_CLASS_PATH_" + report["status"].upper())
if report["status"] != "passed":
    raise RuntimeError(report["error"])
