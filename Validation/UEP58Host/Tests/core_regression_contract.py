"""Independent gate for existing core suites, without compiling or packaging."""
import argparse
import json
from pathlib import Path
import re

CORE = ('version_and_interpreter_mode','runtime_control_surface','class_lookup_and_construction',
    'property_inventory','scalar_properties','math_properties','array_and_map_properties','set_properties',
    'struct_enum_and_struct_function','object_property','function_return_and_out_params','animation_wrapper_round_trip',
    'udp_socket_receiver_lifecycle','dynamic_uclass_fproperty_and_ufunction','dynamic_function_stress',
    'dynamic_class_reload_contract','game_thread_diagnostic','enhanced_input_binding_lifecycle',
    'dynamic_multicast_delegate','invalid_property_conversion','housekeeper_gc')
EDITOR = ('shared_editor_interpreter','actor_spawn_call_and_destroy','asset_create_save_and_load',
          'sequencer_asset_track_section_and_folder_lifecycle','slate_item_reference_ownership')
KINDS = ('core-shared','core-standalone','exception-shared','exception-standalone','editor')


def require(value,message):
    if not value:raise ValueError(message)


def validate(kind,report,log,exit_code):
    require(kind in KINDS,'Unknown focused core suite')
    exception = kind.startswith('exception-')
    names = ('dynamic_exception_boundary_and_recovery',) if exception else EDITOR if kind=='editor' else CORE
    mode = 'shared' if kind=='editor' else kind.split('-',1)[1]
    require(report['status']=='passed' and report['failed']==0 and report['passed']==len(names) and
            tuple(r['name'] for r in report['tests'])==names and all(r['status']=='passed' for r in report['tests']),
            'Complete original case names/counts and passed outcomes required')
    require(report['suite']==('exception_boundary' if exception else 'editor' if kind=='editor' else 'core') and
            report['mode']==mode and report['engine_version']==[5,8] and
            report['python_version'].startswith('3.11.') and
            (exception or report.get('epic_unreal_module_loaded') is (mode=='shared')), 'Interpreter/engine mode differs')
    allowed_skips = ['delete_asset unattended reference scan; the driver removes the two isolated test assets after editor exit']
    if kind=='editor' and report.get('validation_asset_suffix'):
        suffix=report['validation_asset_suffix']
        require(re.fullmatch(r'UEP_[0-9a-f]{32}',suffix) and report['test_asset_packages']==[
            '/Game/UEPValidation/'+name+'_'+suffix for name in ('M_UEP58Validation','LS_UEP58Validation')],
            'Fresh editor asset names must stay under the owned validation package root')
        allowed_skips=['delete_asset unattended reference scan; uniquely named test assets retained in the managed stage']
    require(report.get('known_skips',[] if exception else None)==(allowed_skips if kind=='editor' else []),'Unexpected core exclusions')
    require(exit_code in ((0,1) if exception else (0,)),'Unexpected native core exit')
    marker = 'UEP_EXCEPTION_VALIDATION_PASSED' if exception else 'UEP_VALIDATION_PASSED'
    require(re.search(re.escape(marker)+r'.*Goodbye Python.*Log file closed',log,re.S),
            'Native core marker/interpreter/log closure absent or out of order')
    require(not re.search(r'Fatal error:|Assertion failed:|Unhandled Exception:|Ensure condition failed|UEP_VALIDATION_FAILED|UEP_VALIDATION_CASE_FAILED|UEP_EXCEPTION_VALIDATION_FAILED',log),
            'Native core reported failure/crash/ensure')
    errors = [line for line in log.splitlines() if re.search(r'Log[^:\s]+:\s+Error:',line)]
    if exception:
        require(errors and any('UEP_EXPECTED_DYNAMIC_EXCEPTION' in line for line in errors), 'Expected dynamic exception was not exercised')
        require(all(re.search(r'LogPython:\s+Error:.*(?:UEP_EXPECTED_DYNAMIC_EXCEPTION|Traceback \(most recent call last\):|MaybeFail|RuntimeError:)',line)
                    for line in errors),'Unexpected dynamic exception diagnostic')
    else:
        require(not errors and 'Traceback' not in log,'Unexpected core diagnostic')
    return dict(status='passed',kind=kind,mode=mode,checks=len(names),expected_exception=exception,
                native_exit_code=exit_code,packaged_runtime=False,complete_six_suite_gate=False)


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--kind',choices=KINDS,required=True)
    parser.add_argument('--report',required=True);parser.add_argument('--log',required=True)
    parser.add_argument('--exit-code',type=int,required=True);args=parser.parse_args()
    report=json.loads(Path(args.report).read_text(encoding='utf-8-sig'))
    print(json.dumps(validate(args.kind,report,Path(args.log).read_text(encoding='utf-8-sig'),args.exit_code)))


if __name__=='__main__':main()
