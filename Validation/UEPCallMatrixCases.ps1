# Pure selection only: importing this file never stages, builds or starts UE.
function Get-UEPCallMatrixCases {
    param([string[]]$TestName=@())
    $cases=@(
        @{name='delegate-broadcast';script='delegate_broadcast_validation.py';result='UEPDelegateBroadcastResult';marker='UEP_DELEGATE_BROADCAST_PASSED'},
        @{name='signature-standalone';script='mixin_signature_validation.py';result='UEPMixinSignatureResult';marker='UEP_MIXIN_SIGNATURE_PASSED'},
        @{name='signature-shared';script='mixin_signature_validation.py';result='UEPMixinSignatureResult';marker='UEP_MIXIN_SIGNATURE_PASSED'},
        @{name='callsite';script='mixin_callsite_validation.py';result='UEPMixinCallsiteResult';marker='UEP_MIXIN_CALLSITE_PASSED'},
        @{name='experimental-body';script='blueprint_script_body_validation.py';result='UEPBlueprintScriptBodyResult';marker='UEP_BLUEPRINT_SCRIPT_BODY_PASSED'},
        @{name='named-outputs';script='mixin_named_output_validation.py';result='UEPMixinNamedOutputResult';marker='UEP_MIXIN_NAMED_OUTPUT_PASSED'},
        @{name='named-outputs-negative';script='mixin_named_output_validation.py';result='UEPMixinNamedOutputResult';marker='UEP_MIXIN_NAMED_OUTPUT_PASSED'},
        @{name='inherited-selector';script='mixin_inherited_selector_validation.py';result='UEPInheritedSelectorResult';marker='UEP_INHERITED_SELECTOR_PASSED'},
        @{name='construction-forwarder';script='mixin_construction_forwarder_validation.py';result='UEPConstructionForwarderResult';marker='UEP_CONSTRUCTION_FORWARDER_PASSED'},
        @{name='soft-class-path';script='soft_class_path_validation.py';result='UEPSoftClassPathResult';marker='UEP_SOFT_CLASS_PATH_PASSED'},
        @{name='mixin-exception';script='mixin_exception_validation.py';result='UEPMixinExceptionResult';marker='UEP_MIXIN_EXCEPTION_PASSED'}
    )
    if(!$TestName.Count){return $cases}
    if(@($TestName|Select-Object -Unique).Count -ne $TestName.Count){throw 'Duplicate call-matrix test names are not allowed'}
    foreach($name in $TestName){if($name -notin $cases.name){throw "Unknown call-matrix test: $name"}}
    return @($cases|Where-Object {$_.name -in $TestName})
}
