"""Negative evidence must include real native flags, recovery and clean exit."""
import copy
import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
PATH = ROOT / 'Validation/UEP58Host/Tests/mixin_rejection_contract.py'
spec = importlib.util.spec_from_file_location('native_mixin_rejection_contract', PATH)
contract = importlib.util.module_from_spec(spec)
spec.loader.exec_module(contract)


def fixture():
    rows = []
    for kind, name, flags in [('rpc', 'ServerRestartPlayer', 0x40), ('delegate', 'RejectedDelegate__DelegateSignature', 0x100000), ('latent', 'RejectedLatent', 0)]:
        rows.append(dict(kind=kind, name=name, original=dict(flags=flags), rejected=True,
                         same_class=True, original_function_unchanged=True, reflected_abi_unchanged=True,
                         active_valid_router_still_usable=True, rejected_callback_calls=0,
                         latent_metadata_present=kind == 'latent',
                         reason='latent functions are outside' if kind == 'latent' else 'static, RPC, and delegate functions are outside'))
    report = dict(status='passed', error=None, cases=rows, invalid_callback_calls=0,
                  original_valid_functions_restored=True, original_native_return_restored=True,
                  test_owned_transient_blueprint_classes=2, temporary_roots_created=3, temporary_roots_removed=3,
                  production_classes_modified=False, packages_saved=False, rpc_called_or_network_execution_tested=False,
                  editor_latent_metadata_rejection_tested=True, cooked_latent_rejection_tested=False,
                  packaged_runtime=False, full_acceptance=False)
    return report, 'UEP_MIXIN_REJECTION_PASSED\nGoodbye Python\nLog file closed'


class MixinRejectionContractTests(unittest.TestCase):
    def test_all_three_native_rejection_families_and_recovery_are_required(self):
        report, log = fixture()
        self.assertEqual(contract.validate(report, log)['native_rejection_families'], 3)
        for change in ('missing', 'reordered', 'status'):
            changed = copy.deepcopy(report)
            if change == 'missing': changed['cases'].pop()
            if change == 'reordered': changed['cases'].reverse()
            if change == 'status': changed['status'] = 'failed'
            with self.subTest(change=change), self.assertRaises(ValueError): contract.validate(changed, log)

    def test_flag_labels_do_not_replace_actual_native_function_flags(self):
        for index in (0, 1):
            report, log = fixture()
            report['cases'][index]['original']['flags'] = 0
            with self.assertRaises(ValueError): contract.validate(report, log)
        report, log = fixture()
        report['cases'][0]['name'] = 'OrdinaryFunction'
        with self.assertRaises(ValueError): contract.validate(report, log)

    def test_partial_router_corruption_or_callback_execution_fails(self):
        for field in ('same_class', 'original_function_unchanged', 'reflected_abi_unchanged', 'active_valid_router_still_usable'):
            report, log = fixture()
            report['cases'][0][field] = False
            with self.subTest(field=field), self.assertRaises(ValueError): contract.validate(report, log)
        report, log = fixture()
        report['cases'][1]['rejected_callback_calls'] = 1
        with self.assertRaises(ValueError): contract.validate(report, log)

    def test_latent_metadata_and_exact_rejection_reason_must_be_observed(self):
        for field, value in (('latent_metadata_present', False), ('reason', 'some unrelated failure')):
            report, log = fixture()
            report['cases'][2][field] = value
            with self.assertRaises(ValueError): contract.validate(report, log)

    def test_original_function_and_temporary_root_cleanup_are_required(self):
        for field, value in (('original_valid_functions_restored', False), ('original_native_return_restored', False),
                             ('temporary_roots_removed', 2), ('invalid_callback_calls', 1)):
            report, log = fixture()
            report[field] = value
            with self.subTest(field=field), self.assertRaises(ValueError): contract.validate(report, log)

    def test_editor_fixture_cannot_claim_cooked_metadata_or_network_support(self):
        for field in ('production_classes_modified', 'packages_saved', 'rpc_called_or_network_execution_tested',
                      'cooked_latent_rejection_tested', 'packaged_runtime', 'full_acceptance'):
            report, log = fixture()
            report[field] = True
            with self.subTest(field=field), self.assertRaises(ValueError): contract.validate(report, log)

    def test_success_markers_cannot_hide_unexpected_native_errors(self):
        report, log = fixture()
        for failure in ('Traceback', 'Ensure condition failed', 'Fatal error', 'LogPython: Error: broken'):
            with self.assertRaises(ValueError): contract.validate(report, log + '\n' + failure)

    def test_native_shutdown_order_and_completion_are_mandatory(self):
        report, log = fixture()
        for changed in (log.replace('Goodbye Python', ''), log.replace('UEP_MIXIN_REJECTION_PASSED', ''),
                        'Goodbye Python\nUEP_MIXIN_REJECTION_PASSED\nLog file closed'):
            with self.assertRaises(ValueError): contract.validate(report, changed)
