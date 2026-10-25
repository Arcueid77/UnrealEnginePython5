"""Real commandlet bootstrap paths/import order and a native reflection call."""
import importlib,json,sys,traceback
from pathlib import Path
import unreal_engine as ue

def argument(name):
    prefix='-'+name+'='
    return next(value[len(prefix):] for value in sys.argv if value.startswith(prefix))

result_path=Path(argument('UEPBootstrapPathsResult'))
expected=json.loads(Path(argument('UEPBootstrapPathsExpected')).read_text(encoding='utf-8-sig'))
result=dict(status='failed',case=expected['case'],configured_paths=expected['paths'],imports={},native_sum=None,
    shared_interpreter=expected['shared_interpreter'],cpp_compile_executed=False,full_acceptance=False)
try:
    if expected['shared_interpreter']:
        import unreal
        result['official_unreal_module_loaded']=unreal is not None
    if expected['paths']:
        normalize=lambda value:str(Path(value).resolve()).casefold()
        actual=[normalize(value) for value in sys.path if isinstance(value,str)]
        indexes={key:actual.index(normalize(value)) for key,value in expected['paths'].items()}
        assert indexes['additional']<indexes['scripts']<indexes['zip'],indexes
        result['path_indexes']=indexes
        for name,value in expected['modules'].items():
            module=importlib.import_module(name);assert module.VALUE==value,(name,module.VALUE)
            result['imports'][name]=dict(value=module.VALUE,file=module.__file__)
    native=ue.find_class('KismetMathLibrary').get_cdo()
    result['native_sum']=native.call_function('Add_IntInt',20,22)
    assert result['native_sum']==42,result['native_sum']
    result['status']='passed'
except Exception:
    result['error']=traceback.format_exc()
    raise
finally:
    result_path.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
if result['status']=='passed':ue.log('UEP_BOOTSTRAP_PATH_PASSED')
