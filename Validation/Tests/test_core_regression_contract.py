import copy
import importlib.util
from pathlib import Path
import unittest

spec=importlib.util.spec_from_file_location('focused_core_contract',
    Path(__file__).resolve().parents[1]/'UEP58Host/Tests/core_regression_contract.py')
audit=importlib.util.module_from_spec(spec);spec.loader.exec_module(audit)


def fixture(kind):
    exception=kind.startswith('exception-');mode='shared' if kind=='editor' else kind.split('-',1)[1]
    names=('dynamic_exception_boundary_and_recovery',) if exception else audit.EDITOR if kind=='editor' else audit.CORE
    report=dict(suite='exception_boundary' if exception else 'editor' if kind=='editor' else 'core',
        status='passed',mode=mode,failed=0,passed=len(names),engine_version=[5,8],python_version='3.11.8',
        tests=[dict(name=n,status='passed') for n in names])
    if not exception:
        report.update(epic_unreal_module_loaded=mode=='shared',known_skips=[
            'delete_asset unattended reference scan; the driver removes the two isolated test assets after editor exit'] if kind=='editor' else [])
    marker='UEP_EXCEPTION_VALIDATION_PASSED' if exception else 'UEP_VALIDATION_PASSED'
    log=('LogPython: Error: RuntimeError: UEP_EXPECTED_DYNAMIC_EXCEPTION\n' if exception else '')
    return report,log+marker+'\nGoodbye Python\nLog file closed'


class FocusedCoreRegressionContractTests(unittest.TestCase):
    def test_five_editor_suites_cover49_checks_without_claiming_packaged_suite(self):
        results=[audit.validate(kind,*fixture(kind),1 if kind.startswith('exception-') else 0) for kind in audit.KINDS]
        self.assertEqual([r['checks'] for r in results],[21,21,1,1,5])
        self.assertEqual(sum(r['checks'] for r in results),49)
        self.assertTrue(all(not r['packaged_runtime'] and not r['complete_six_suite_gate'] for r in results))

    def test_passed_status_cannot_hide_missing_duplicate_or_failed_cases(self):
        for mutation in ('missing','duplicate','failed','count'):
            report,log=fixture('core-shared')
            if mutation=='missing':report['tests'].pop()
            elif mutation=='duplicate':report['tests'][-1]=copy.deepcopy(report['tests'][0])
            elif mutation=='failed':report['tests'][0]['status']='failed'
            else:report['passed']=70
            with self.subTest(mutation=mutation),self.assertRaises(ValueError):audit.validate('core-shared',report,log,0)

    def test_interpreter_engine_python_and_suite_modes_are_checked(self):
        for field,value in [('mode','standalone'),('epic_unreal_module_loaded',False),('engine_version',[5,7]),
                            ('python_version','3.10.1'),('suite','packaged')]:
            report,log=fixture('core-shared');report[field]=value
            with self.subTest(field=field),self.assertRaises(ValueError):audit.validate('core-shared',report,log,0)

    def test_actual_exception_schema_does_not_invent_optional_fields(self):
        report,log=fixture('exception-standalone')
        self.assertNotIn('epic_unreal_module_loaded',report);self.assertNotIn('known_skips',report)
        self.assertTrue(audit.validate('exception-standalone',report,log,1)['expected_exception'])
        report['mode']='shared'
        with self.assertRaises(ValueError):audit.validate('exception-standalone',report,log,1)

    def test_negative_exit_is_allowed_only_for_exercised_expected_exception(self):
        report,log=fixture('exception-shared')
        for text,code in [(log.replace('LogPython: Error: RuntimeError: UEP_EXPECTED_DYNAMIC_EXCEPTION\n',''),1),
                          (log+'\nLogPython: Error: unrelated failure',1),(log,3)]:
            with self.subTest(code=code),self.assertRaises(ValueError):audit.validate('exception-shared',report,text,code)
        report,log=fixture('core-standalone')
        with self.assertRaises(ValueError):audit.validate('core-standalone',report,log,1)

    def test_success_needs_normal_shutdown_and_no_hidden_crash_or_error(self):
        report,log=fixture('core-shared')
        for text in (log.replace('Log file closed',''),log.replace('Goodbye Python',''),
                     log+'\nEnsure condition failed',log+'\nLogPython: Error: unexpected'):
            with self.subTest(text=text[-24:]),self.assertRaises(ValueError):audit.validate('core-shared',report,text,0)

    def test_editor_exclusions_are_explicit(self):
        report,log=fixture('editor');report['known_skips']=[]
        with self.assertRaises(ValueError):audit.validate('editor',report,log,0)

    def test_unique_editor_packages_cannot_escape_the_validation_root(self):
        report,log=fixture('editor');suffix='UEP_'+'a'*32
        report.update(validation_asset_suffix=suffix,test_asset_packages=[
            '/Game/UEPValidation/'+name+'_'+suffix for name in ('M_UEP58Validation','LS_UEP58Validation')],
            known_skips=['delete_asset unattended reference scan; uniquely named test assets retained in the managed stage'])
        audit.validate('editor',report,log,0)
        for field,value in [('validation_asset_suffix','../other'),('test_asset_packages',['/Game/ExistingAsset'])]:
            broken=copy.deepcopy(report);broken[field]=value
            with self.subTest(field=field),self.assertRaises(ValueError):audit.validate('editor',broken,log,0)


if __name__=='__main__':unittest.main()
