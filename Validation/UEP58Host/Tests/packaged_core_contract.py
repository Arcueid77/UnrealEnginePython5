"""Gate the original21 cases in an actual Game package; Editor mode cannot substitute."""
import argparse
import json
from pathlib import Path
import re

from core_regression_contract import CORE, require


def validate(report,log,exit_code):
    require(report['suite']=='core' and report['mode']=='packaged' and report['status']=='passed',
            'Actual packaged core suite required')
    require(type(report['passed']) is int and report['passed']==21 and type(report['failed']) is int and
            report['failed']==0 and tuple(r['name'] for r in report['tests'])==CORE and
            all(r['status']=='passed' for r in report['tests']), 'Every original core case must pass exactly once')
    require(report['engine_version']==[5,8] and report['python_version'].startswith('3.11.') and
            report['epic_unreal_module_loaded'] is False and report['known_skips']==[],
            'Packaged engine/interpreter scope or exclusions differ')
    require(exit_code==0, 'Actual packaged Game process must exit0')
    require(re.search(r'UEP_VALIDATION_PASSED.*UEP_PACKAGED_VALIDATION_PASSED.*Goodbye Python.*Log file closed',log,re.S),
            'Core/Game-host markers and normal interpreter/log shutdown must be ordered')
    require(not re.search(r'Fatal error:|Assertion failed:|Unhandled Exception:|Ensure condition failed|Traceback|'
                         r'UEP_VALIDATION_FAILED|UEP_VALIDATION_CASE_FAILED|UEP_PACKAGED_VALIDATION_FAILED|Log\w+:\s*Error:',log),
            'Unexpected packaged diagnostic')
    return dict(status='passed',suite='core',mode='packaged',checks=21,packaged_runtime=True,
                native_exit_code=0,complete_six_suite_gate=False,full_candidate_regression_requirement_proven=False)


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--report',required=True)
    parser.add_argument('--log',required=True);parser.add_argument('--exit-code',type=int,required=True)
    args=parser.parse_args()
    print(json.dumps(validate(json.loads(Path(args.report).read_text(encoding='utf-8-sig')),
                             Path(args.log).read_text(encoding='utf-8-sig'),args.exit_code)))
