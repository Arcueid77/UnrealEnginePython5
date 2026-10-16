"""Native reflected multicast property, Python broadcast and unsubscribe."""
import json
from pathlib import Path
import sys
import traceback

import unreal_engine as ue
from unreal_engine.classes import UEPValidationObject


def check(value, message):
    if not value:
        raise AssertionError(message)


def validate():
    obj = ue.new_object(UEPValidationObject)
    obj.broadcast("OnSignal", 7)  # An empty invocation list is valid too.
    signals = []
    callback = signals.append
    obj.bind_event("OnSignal", callback)
    try:
        obj.call_function("BroadcastSignal", 11)
        obj.broadcast("OnSignal", 22)
        check(signals == [11, 22], "native/Python broadcasts did not reach the same native delegate")
        try:
            obj.broadcast("OnSignal", object())
        except TypeError:
            pass
        else:
            raise AssertionError("invalid multicast parameter was accepted")
        check(signals == [11, 22], "rejected parameters delivered a callback")
        obj.broadcast("OnSignal", 33)
        check(signals == [11, 22, 33], "broadcast did not recover after rejection")
    finally:
        obj.unbind_event("OnSignal", callback)
    obj.broadcast("OnSignal", 44)
    check(signals == [11, 22, 33], "unsubscribed callback received another broadcast")
    return {"status": "passed", "signals": signals, "empty_delegate": True,
            "rejected_parameter": True, "recovery": True, "no_late_delivery": True,
            "full_acceptance": False}


prefix = "-UEPDelegateBroadcastResult="
result = next(value[len(prefix):] for value in sys.argv if value.startswith(prefix))
try:
    report = validate()
except Exception:
    report = {"status": "failed", "error": traceback.format_exc()}
Path(result).write_text(json.dumps(report, indent=2), encoding="utf-8")
ue.log("UEP_DELEGATE_BROADCAST_" + report["status"].upper())
if report["status"] != "passed":
    raise RuntimeError(report["error"])
