"""Select native fixtures without invoking the staging/launching driver."""
import json
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[2]
HELPER = ROOT / 'Validation/UEPCallMatrixCases.ps1'


class CallMatrixSelectionTests(unittest.TestCase):
    def query(self, arguments=''):
        command = ". '" + str(HELPER).replace("'", "''") + "'; @(Get-UEPCallMatrixCases " + arguments + ') | ConvertTo-Json -Depth 5 -Compress'
        return subprocess.run(['pwsh', '-NoProfile', '-Command', command], capture_output=True, text=True)

    def test_default_keeps_all_eleven_original_cases_in_original_order(self):
        result = self.query()
        self.assertEqual(result.returncode, 0, result.stderr)
        names = [row['name'] for row in json.loads(result.stdout)]
        self.assertEqual(names, ['delegate-broadcast', 'signature-standalone', 'signature-shared', 'callsite',
                                'experimental-body', 'named-outputs', 'named-outputs-negative', 'inherited-selector',
                                'construction-forwarder', 'soft-class-path', 'mixin-exception'])

    def test_explicit_subset_does_not_expand_to_other_fixtures(self):
        result = self.query("-TestName @('signature-standalone','delegate-broadcast')")
        self.assertEqual(result.returncode, 0, result.stderr)
        rows = json.loads(result.stdout)
        self.assertEqual([row['name'] for row in rows], ['delegate-broadcast', 'signature-standalone'])
        self.assertEqual([row['script'] for row in rows], ['delegate_broadcast_validation.py', 'mixin_signature_validation.py'])

    def test_unknown_names_fail_before_a_native_driver_can_launch(self):
        result = self.query("-TestName @('missing-fixture')")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Unknown call-matrix test', result.stderr)

    def test_duplicate_names_cannot_overwrite_or_repeat_evidence(self):
        result = self.query("-TestName @('callsite','callsite')")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Duplicate call-matrix test names', result.stderr)

    def test_one_explicit_case_remains_one_case(self):
        result = self.query("-TestName @('named-outputs-negative')")
        self.assertEqual(result.returncode, 0, result.stderr)
        rows = json.loads(result.stdout)
        if isinstance(rows, dict): rows = [rows]
        self.assertEqual([row['name'] for row in rows], ['named-outputs-negative'])

    def test_importing_the_helper_does_not_execute_native_process_commands(self):
        command = ". '" + str(HELPER).replace("'", "''") + "'; if(Get-Command Start-UEPValidationProcess -ErrorAction SilentlyContinue){throw 'Unexpected process helper side effect'}; 'pure'"
        result = subprocess.run(['pwsh', '-NoProfile', '-Command', command], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), 'pure')
