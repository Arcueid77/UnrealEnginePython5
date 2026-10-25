"""Pure post-exit gate; metadata alone cannot prove native flag rejection."""
import argparse
import json
from pathlib import Path
import re

PLAN = ('rpc', 'delegate', 'latent')


def require(value, message):
    if not value:
        raise ValueError(message)


def validate(report, log):
    require(report['status'] == 'passed' and report['error'] is None and [row['kind'] for row in report['cases']] == list(PLAN),
            'Complete native RPC/delegate/latent rejection matrix required')
    for row in report['cases']:
        for flag in ('rejected', 'same_class', 'original_function_unchanged', 'reflected_abi_unchanged', 'active_valid_router_still_usable'):
            require(row[flag] is True, 'Unsupported registration corrupted active/original native state')
        flags = row['original']['flags']
        require(row['rejected_callback_calls'] == 0, 'Unsupported callback ran')
        if row['kind'] == 'rpc': require(flags & 0x40 and row['name'] == 'ServerRestartPlayer', 'Real native RPC function required')
        if row['kind'] == 'delegate': require(flags & (0x100000 | 0x10000), 'Real compiled delegate signature required')
        if row['kind'] == 'latent': require(row['latent_metadata_present'] and 'latent functions are outside' in row['reason'], 'Actual latent metadata rejection missing')
        else: require('static, RPC, and delegate functions are outside' in row['reason'], 'Actual native flag rejection missing')
    require(report['invalid_callback_calls'] == 0 and report['original_valid_functions_restored'] and
            report['original_native_return_restored'] and report['test_owned_transient_blueprint_classes'] == 2,
            'Native rejection recovery/restoration missing')
    require(report['temporary_roots_created'] == report['temporary_roots_removed'] == 3, 'Test-owned native roots leaked')
    for flag in ('production_classes_modified', 'packages_saved', 'rpc_called_or_network_execution_tested',
                 'cooked_latent_rejection_tested', 'packaged_runtime', 'full_acceptance'):
        require(report[flag] is False, 'Unsupported native rejection scope claim: ' + flag)
    require(report['editor_latent_metadata_rejection_tested'], 'Editor latent rejection boundary missing')
    require(not any(t in log for t in ('Traceback', 'Ensure condition failed', 'Fatal error')) and
            not re.search(r'Log\w+:\s*Error:', log), 'Unexpected native rejection diagnostic')
    marks = ('UEP_MIXIN_REJECTION_PASSED', 'Goodbye Python', 'Log file closed')
    require(all(m in log for m in marks) and log.index(marks[0]) < log.index(marks[1]) < log.rindex(marks[2]),
            'Native rejection process did not shut down in order')
    return dict(status='passed', native_rejection_families=3, active_router_recovery_cases=3,
                original_functions_restored=True, current_editor_runtime=True, cooked_latent_rejection_tested=False,
                full_acceptance=False)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--report', required=True)
    parser.add_argument('--log', required=True)
    args = parser.parse_args()
    print(json.dumps(validate(json.loads(Path(args.report).read_text(encoding='utf-8-sig')),
                              Path(args.log).read_text(encoding='utf-8-sig'))))
