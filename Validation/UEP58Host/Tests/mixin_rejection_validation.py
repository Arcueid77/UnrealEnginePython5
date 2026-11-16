"""Real native registration rejection for RPC, delegate and latent functions."""
import json
from pathlib import Path
import sys
import traceback
import uuid

import unreal_engine as ue
from unreal_engine import FVector
from unreal_engine.classes import PlayerController, UEPValidationObject

NET, DELEGATE, MULTICAST = 0x40, 0x100000, 0x10000
_invalid_calls = []


def require(value, message):
    if not value:
        raise AssertionError(message)


class ObjectProfile:
    def AddIntegers(self, A, B):
        return self.call_mixin_original('AddIntegers', A, B) + 10


class ControllerProfile:
    def K2_GetActorLocation(self):
        return FVector(11, 22, 33)


def forbidden(self):
    _invalid_calls.append(self.get_path_name())
    raise AssertionError('Rejected callback must never run')


def reject(cls, obj, name, kind, reason, recovery):
    before = obj.find_function(name)
    descriptor = ue.describe_function(cls, name)
    flags = int(descriptor['flags'])
    if kind == 'rpc': require(flags & NET, 'Actual native RPC flag absent')
    if kind == 'delegate': require(flags & (DELEGATE | MULTICAST), 'Actual compiled delegate-signature flag absent')
    if kind == 'latent': require(before.has_metadata('Latent'), 'Actual editor latent metadata absent')
    before_class = obj.get_class()
    profile = type('Rejected_' + kind, (), {name: forbidden})
    try:
        ue.register_mixin_profile(cls, 'Rejected', profile)
    except TypeError as error:
        require(reason in str(error), 'Wrong native rejection boundary: ' + str(error))
        diagnostic = str(error)
    else:
        raise AssertionError('Unsupported function was registered: ' + name)
    require(obj.find_function(name) == before and obj.get_class() == before_class,
            'Rejected registration changed original function or UObject class')
    require(ue.describe_function(cls, name) == descriptor, 'Rejected registration changed reflected ABI/flags')
    require(recovery(), 'Active valid router did not recover after native rejection')
    require(not _invalid_calls, 'Rejected callback executed')
    return dict(kind=kind, name=name, original=descriptor, rejected=True, reason=diagnostic,
                same_class=True, original_function_unchanged=True, reflected_abi_unchanged=True,
                active_valid_router_still_usable=True, rejected_callback_calls=0,
                latent_metadata_present=kind == 'latent')


def validate():
    suffix = uuid.uuid4().hex
    # Blueprint compilation can collect unrooted native test objects.
    roots = []
    obj_bp = ue.create_blueprint(UEPValidationObject, '/Game/UEPValidation/Reject_' + suffix)
    obj_bp.add_to_root(); roots.append(obj_bp)
    ue.blueprint_add_event_dispatcher(obj_bp, 'RejectedDelegate')
    ue.blueprint_add_function(obj_bp, 'RejectedLatent')
    ue.compile_blueprint(obj_bp)
    controller_bp = ue.create_blueprint(PlayerController, '/Game/UEPValidation/RejectRPC_' + suffix)
    controller_bp.add_to_root(); roots.append(controller_bp)
    ue.compile_blueprint(controller_bp)
    obj_class = obj_bp.GeneratedClass
    obj = ue.new_object(obj_class)
    obj.add_to_root(); roots.append(obj)
    latent = obj.find_function('RejectedLatent')
    latent.set_metadata('Latent', 'true')
    controller_class = controller_bp.GeneratedClass
    controller = controller_class.get_cdo()
    originals = [(obj, 'AddIntegers', obj.find_function('AddIntegers')),
                 (controller, 'K2_GetActorLocation', controller.find_function('K2_GetActorLocation'))]
    registered = []
    rows = []
    try:
        ue.register_mixin_profile(obj_class, 'Python', ObjectProfile, make_default=True)
        registered.append(obj_class)
        ue.register_mixin_profile(controller_class, 'Python', ControllerProfile, make_default=True)
        registered.append(controller_class)
        object_ready = lambda: obj.call_function('AddIntegers', 3, 4) == 17
        controller_ready = lambda: controller.call_function('K2_GetActorLocation') == FVector(11, 22, 33)
        require(object_ready() and controller_ready(), 'Positive native routers not installed')
        rows.append(reject(controller_class, controller, 'ServerRestartPlayer', 'rpc',
                           'static, RPC, and delegate functions are outside', controller_ready))
        rows.append(reject(obj_class, obj, 'RejectedDelegate__DelegateSignature', 'delegate',
                           'static, RPC, and delegate functions are outside', object_ready))
        rows.append(reject(obj_class, obj, 'RejectedLatent', 'latent',
                           'latent functions are outside', object_ready))
    finally:
        for cls in reversed(registered):
            ue.unregister_mixin(cls)
    require(all(obj.find_function(name) == original for obj, name, original in originals), 'Original valid function identities not restored')
    require(obj.call_function('AddIntegers', 3, 4) == 7, 'Original valid native return not restored')
    require(controller.call_function('K2_GetActorLocation') != FVector(11, 22, 33), 'Original native Actor location not restored')
    for value in reversed(roots):
        value.remove_from_root()
    return dict(status='passed', error=None, cases=rows, invalid_callback_calls=0,
                original_valid_functions_restored=True, original_native_return_restored=True,
                test_owned_transient_blueprint_classes=2, production_classes_modified=False,
                temporary_roots_created=3, temporary_roots_removed=3,
                packages_saved=False, rpc_called_or_network_execution_tested=False,
                editor_latent_metadata_rejection_tested=True, cooked_latent_rejection_tested=False,
                packaged_runtime=False, full_acceptance=False)


result = Path(next(a.split('=', 1)[1] for a in sys.argv if a.startswith('-UEPMixinRejectionResult=')))
try:
    report = validate()
except Exception:
    report = dict(status='failed', error=traceback.format_exc(), invalid_callback_calls=len(_invalid_calls))
result.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
ue.log('UEP_MIXIN_REJECTION_' + report['status'].upper())
if report['status'] != 'passed':
    raise RuntimeError(report['error'])
