#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$PlanDirectory,[Parameter(Mandatory=$true)][string]$OutputDirectory,[switch]$ReplayActions)
# Exactly one owned read-only module; never an Engine/Lyra refresh.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$planRoot=[IO.Path]::GetFullPath($PlanDirectory);$output=[IO.Path]::GetFullPath($OutputDirectory)
foreach($path in @($stage,$planRoot,$output)){if(!$path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned stage/plan/output required'}}
if(!(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json')) -or (Test-Path -LiteralPath $output)){throw 'Marked stage/fresh output required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool,cl,link -ErrorAction SilentlyContinue).Count){throw 'Another native/build lane is active'}
$planPath=Join-Path $planRoot 'actions.json'
$plan=Get-Content -LiteralPath $planPath -Raw|ConvertFrom-Json -Depth 90
$prior=Get-Content -LiteralPath (Join-Path $planRoot 'summary.json') -Raw|ConvertFrom-Json -Depth 40
$expected=@('Module.UEPNetworkIdentity.cpp','UnrealEditor-UEPNetworkIdentity.dll','UnrealEditor-UEPNetworkIdentity.lib')
if($prior.status -ne 'plan_exported_requires_review' -or !$prior.checked_engine_files_unchanged -or @($plan.Actions).Count -ne 3 -or
    ((@($plan.Actions.StatusDescription|Sort-Object)) -join ',') -ne (($expected|Sort-Object) -join ',')){throw 'Exact three-action identity-only plan required'}
$plugin=[IO.Path]::GetFullPath((Join-Path $stage 'Plugins/UEPLyraBridge'))
$nativePrefix=[IO.Path]::GetFullPath((Join-Path $plugin 'Intermediate/Build/Win64/x64/UnrealEditor/Development/UEPNetworkIdentity'))+[IO.Path]::DirectorySeparatorChar
$binaryPrefix=[IO.Path]::GetFullPath((Join-Path $plugin 'Binaries/Win64'))+[IO.Path]::DirectorySeparatorChar
foreach($action in $plan.Actions){foreach($item in @($action.ProducedItems)+@($action.DeleteItems)){
    if(!$item){continue};$path=[IO.Path]::GetFullPath($item)
    $binary=$path.StartsWith($binaryPrefix,[StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($path) -in @('UnrealEditor-UEPNetworkIdentity.dll','UnrealEditor-UEPNetworkIdentity.pdb')
    if(!$path.StartsWith($nativePrefix,[StringComparison]::OrdinalIgnoreCase) -and !$binary){throw 'Plan writes outside the new owned identity module'}
}}
$sourceRoot=Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge'
$sources=@()
foreach($file in Get-ChildItem -LiteralPath (Join-Path $sourceRoot 'Source/UEPNetworkIdentity') -Recurse -File){
    $target=Join-Path $plugin ([IO.Path]::GetRelativePath($sourceRoot,$file.FullName))
    $hash=(Get-FileHash -LiteralPath $file.FullName).Hash
    if((Get-FileHash -LiteralPath $target).Hash -ne $hash){throw 'Staged identity source mismatch'}
    $sources+=@{path=$file.FullName;stage=$target;sha256=$hash}
}
$descriptor=Join-Path $sourceRoot 'UEPLyraBridge.uplugin';$stagedDescriptor=Join-Path $plugin 'UEPLyraBridge.uplugin'
if((Get-FileHash -LiteralPath $descriptor).Hash -ne (Get-FileHash -LiteralPath $stagedDescriptor).Hash){throw 'Staged plugin descriptor mismatch'}
$sources+=@{path=$descriptor;stage=$stagedDescriptor;sha256=(Get-FileHash -LiteralPath $descriptor).Hash}
$responseHashes=@()
if($ReplayActions){
    foreach($action in $plan.Actions){
        if($action.CommandArguments -notmatch '^(?:/LIB )?@"([^"]+)"\s*$'){throw 'Only exported response-file actions may replay'}
        $response=[IO.Path]::GetFullPath($Matches[1])
        if(!$response.StartsWith($nativePrefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Response file escaped owned module'}
        $lines=[IO.File]::ReadAllLines($response)
        $recorded=@($action.ResponseFileContents)
        if(($lines -join "`n") -cne ($recorded -join "`n")){
            # UE's VC action finalizer appends exactly these standard switches
            # after JSON export. No output path, include or definition change.
            $tail=@('/nologo','/TP','/GR-','/std:c++20','/wd5054')
            if($action.StatusDescription -ne 'Module.UEPNetworkIdentity.cpp' -or
                ($lines -join "`n") -cne (($recorded+$tail) -join "`n")){throw 'Exported action response file changed'}
        }
    }
    foreach($file in Get-ChildItem -LiteralPath $nativePrefix -File|Where-Object {$_.Extension -in '.rsp','.h','.cpp'}){
        $responseHashes+=@{path=$file.FullName;sha256=(Get-FileHash -LiteralPath $file.FullName).Hash}
    }
}
New-Item -ItemType Directory -Path (Join-Path $output 'PreviousBinaries')|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';cpp_compile_executed=$false;engine_full_compile_executed=$false
    lyra_cpp_compile_executed=$false;cook_package_executed=$false;runtime_acceptance=$false;reviewed_actions=$expected
    source_hashes=$sources;response_hashes=$responseHashes;reviewed_action_replay=[bool]$ReplayActions;phases=@()
    protected_before=@();protected_after=@();backup=@();process=$null;error=$null}
try{
    $protected=@()
    foreach($relative in @('Engine/Build/Build.version','Engine/Binaries/Win64/UnrealEditor.exe','Engine/Binaries/Win64/UnrealEditor-Core.dll','Engine/Binaries/Win64/UnrealEditor-Engine.dll','Engine/Binaries/Win64/UnrealEditor-NetCore.dll','Engine/Binaries/Win64/UnrealEditor-IrisCore.dll','Engine/Binaries/Win64/UnrealEditor.modules')){
        $protected+=Join-Path $EngineRoot $relative
    }
    foreach($relative in @('Binaries/Win64/UnrealEditor-LyraGame.dll','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPLyraBridge.dll')){$protected+=Join-Path $stage $relative}
    foreach($module in @('Core','CoreUObject','Engine','NetCore','IrisCore')){
        $protected+=Join-Path $EngineRoot "Engine/Intermediate/Build/Win64/x64/UnrealEditor/Development/$module/UnrealEditor-$module.lib"
    }
    foreach($path in $protected){$summary.protected_before+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    foreach($name in @('UnrealEditor.modules','UnrealEditor-UEPNetworkIdentity.dll','UnrealEditor-UEPNetworkIdentity.pdb')){
        $path=Join-Path $binaryPrefix $name
        if(Test-Path -LiteralPath $path){$backup=Join-Path $output ('PreviousBinaries/'+$name);Copy-Item -LiteralPath $path -Destination $backup;$summary.backup+=@{path=$path;backup=$backup;sha256=(Get-FileHash -LiteralPath $backup).Hash}}
    }
    $summary.reviewed_plan_sha256=(Get-FileHash -LiteralPath $planPath).Hash
    $dotnet=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/DotNet/10.0/win-x64/dotnet.exe'
    if($ReplayActions){
        $args=@((Join-Path $EngineRoot 'Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.dll'),'-Mode=Execute',"-Actions=$planPath",'LyraEditor','Win64','Development',
            "-Project=$project",'-NoUBA','-MaxParallelActions=2','-UTF8Output',"-Log=$output/build.log")
    }else{
        $args=@((Join-Path $EngineRoot 'Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.dll'),'LyraEditor','Win64','Development',
            "-Project=$project",'-Module=UEPNetworkIdentity','-NoEngineChanges','-IgnoreJunk','-SkipPreBuildTargets','-SkipRulesCompile',
            '-WaitMutex','-NoHotReload','-NoUBA','-MaxParallelActions=2','-UTF8Output',"-Log=$output/build.log")
        if($prior.process.arguments -contains '-UsePrecompiled'){$args+='-UsePrecompiled'}
        if($prior.process.arguments -contains '-NoUBTMakefiles'){$args+='-NoUBTMakefiles'}
    }
    $summary.cpp_compile_executed=$true
    if($ReplayActions){
        # Execute-mode import does not retain the exported prerequisite-index
        # edges. Keep the same reviewed commands, but gate links on compilation.
        foreach($phase in @('compile','links')){
            $actions=@($plan.Actions|Where-Object {if($phase -eq 'compile'){$_.StatusDescription -eq 'Module.UEPNetworkIdentity.cpp'}else{$_.StatusDescription -ne 'Module.UEPNetworkIdentity.cpp'}})
            $copies=@($actions|ForEach-Object {$copy=$_|ConvertTo-Json -Depth 90|ConvertFrom-Json -Depth 90;$copy.PrerequisiteActions=@();$copy})
            $phasePath=Join-Path $output ("reviewed-$phase-actions.json")
            @{Environment=$plan.Environment;Actions=$copies}|ConvertTo-Json -Depth 100|Set-Content -LiteralPath $phasePath -Encoding utf8
            $phaseArgs=@((Join-Path $EngineRoot 'Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.dll'),'-Mode=Execute',"-Actions=$phasePath",'LyraEditor','Win64','Development',
                "-Project=$project",'-NoUBA','-MaxParallelActions=2','-UTF8Output',"-Log=$output/$phase.log")
            $summary.process=Invoke-UEPValidationProcess $dotnet $phaseArgs $stage (Join-Path $output $phase) "Reviewed identity $phase only" 180
            $summary.phases+=@{phase=$phase;reviewed_subset_sha256=(Get-FileHash -LiteralPath $phasePath).Hash;process=$summary.process}
        }
    }else{
        $summary.process=Invoke-UEPValidationProcess $dotnet $args $stage (Join-Path $output 'build') 'Reviewed identity-only compile/link' 180
    }
    foreach($row in $sources){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256 -or (Get-FileHash -LiteralPath $row.stage).Hash -ne $row.sha256){throw 'Frozen identity source changed'}}
    foreach($row in $responseHashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen action response/source changed'}}
    $binary=Join-Path $binaryPrefix 'UnrealEditor-UEPNetworkIdentity.dll';$summary.identity_dll=@{path=$binary;sha256=(Get-FileHash -LiteralPath $binary).Hash}
    $id=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    $manifest=Get-Content -LiteralPath (Join-Path $binaryPrefix 'UnrealEditor.modules') -Raw|ConvertFrom-Json
    if($ReplayActions){
        if($manifest.BuildId -ne $id){throw 'Never rewrite an incompatible existing module BuildId'}
        # Execute mode links binaries, not manifests. Add only this freshly
        # compiled module; preserve the actual existing SDK id and old entries.
        $manifest.Modules|Add-Member -NotePropertyName UEPNetworkIdentity -NotePropertyValue 'UnrealEditor-UEPNetworkIdentity.dll' -Force
        $manifest|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $binaryPrefix 'UnrealEditor.modules') -Encoding utf8
        $summary.own_manifest_entry_added=$true
    }
    if($manifest.BuildId -ne $id -or $manifest.Modules.UEPNetworkIdentity -ne 'UnrealEditor-UEPNetworkIdentity.dll'){throw 'Identity module BuildId/manifest mismatch'}
    $summary.engine_build_id=$id;$summary.status='built_requires_native_acceptance'
}catch{$summary.error=$_.ToString();throw}
finally{
    foreach($row in $summary.protected_before){$summary.protected_after+=@{path=$row.path;sha256=(Get-FileHash -LiteralPath $row.path).Hash}}
    $summary.checked_engine_and_existing_binaries_unchanged=(@($summary.protected_before|Where-Object {$before=$_;!@($summary.protected_after|Where-Object {$_.path -eq $before.path -and $_.sha256 -eq $before.sha256}).Count}).Count -eq 0)
    if(!$summary.checked_engine_and_existing_binaries_unchanged){$summary.status='failed';$summary.error='Protected engine/existing binary changed'}
    $summary|ConvertTo-Json -Depth 15|Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8
}
if($summary.status -ne 'built_requires_native_acceptance'){throw $summary.error}
Write-Host 'Read-only identity module built; no native runtime acceptance yet'
