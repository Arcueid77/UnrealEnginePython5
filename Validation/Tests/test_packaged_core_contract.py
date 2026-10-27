import copy
import importlib.util
from pathlib import Path
import sys
import unittest

folder=Path(__file__).resolve().parents[1]/'UEP58Host/Tests'
sys.path.insert(0,str(folder))
spec=importlib.util.spec_from_file_location('packaged_core_gate',folder/'packaged_core_contract.py')
gate=importlib.util.module_from_spec(spec);spec.loader.exec_module(gate)


def fixture():
    value=dict(suite='core',mode='packaged',status='passed',passed=21,failed=0,engine_version=[5,8],
        python_version='3.11.8',epic_unreal_module_loaded=False,known_skips=[],
        tests=[dict(name=n,status='passed') for n in gate.CORE])
    log='UEP_VALIDATION_PASSED\nUEP_PACKAGED_VALIDATION_PASSED\nGoodbye Python\nLog file closed'
    return value,log


class PackagedCoreContractTests(unittest.TestCase):
    def test_packaged21_is_a_component_and_cannot_alone_certify_the_six_suite_gate(self):
        result=gate.validate(*fixture(),0)
        self.assertEqual(result['checks'],21);self.assertTrue(result['packaged_runtime'])
        self.assertFalse(result['complete_six_suite_gate']);self.assertFalse(result['full_candidate_regression_requirement_proven'])

    def test_editor_modes_or_epic_interpreter_cannot_substitute_for_game(self):
        for field,value in [('mode','standalone'),('mode','shared'),('suite','editor'),('epic_unreal_module_loaded',True)]:
            report,log=fixture();report[field]=value
            with self.subTest(field=field,value=value),self.assertRaises(ValueError):gate.validate(report,log,0)

    def test_missing_duplicate_failed_or_skipped_original_cases_are_rejected(self):
        for mutation in ('missing','duplicate','failed','count','skip'):
            report,log=fixture()
            if mutation=='missing':report['tests'].pop()
            elif mutation=='duplicate':report['tests'][0]=copy.deepcopy(report['tests'][-1])
            elif mutation=='failed':report['tests'][0]['status']='failed'
            elif mutation=='count':report['passed']=70
            else:report['known_skips']=['UDP disabled']
            with self.subTest(mutation=mutation),self.assertRaises(ValueError):gate.validate(report,log,0)

    def test_both_host_markers_and_normal_shutdown_are_required_in_order(self):
        report,log=fixture()
        for text in (log.replace('UEP_PACKAGED_VALIDATION_PASSED',''),log.replace('Goodbye Python',''),
                     log.replace('Log file closed',''),log.replace('UEP_VALIDATION_PASSED\n','')+'\nUEP_VALIDATION_PASSED'):
            with self.subTest(text=text),self.assertRaises(ValueError):gate.validate(report,text,0)

    def test_crash_error_traceback_or_nonzero_exit_cannot_hide_behind_a_passed_report(self):
        report,log=fixture()
        for text,code in [(log,1),(log+'\nFatal error:',0),(log+'\nTraceback',0),
                          (log+'\nLogPython: Error: failed',0),(log+'\nUEP_PACKAGED_VALIDATION_FAILED',0)]:
            with self.subTest(code=code),self.assertRaises(ValueError):gate.validate(report,text,code)

    def test_engine_python_versions_and_integer_counters_are_checked(self):
        for field,value in [('engine_version',[5,7]),('python_version','3.10.0'),('failed',False),('passed',True)]:
            report,log=fixture();report[field]=value
            with self.subTest(field=field),self.assertRaises(ValueError):gate.validate(report,log,0)


if __name__=='__main__':unittest.main()
