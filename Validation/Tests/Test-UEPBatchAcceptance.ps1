#Requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$id=[Guid]::NewGuid().ToString('N')
$inputRoot=Join-Path $repo ".build/CommitVerification/batch-ledger-test-$id"
$outputRoot=Join-Path $repo "Validation/AcceptedBatches/.test-$id"
New-Item -ItemType Directory -Path $inputRoot,$outputRoot|Out-Null
$summaryPath=Join-Path $inputRoot 'summary.json'
$outputPath=Join-Path $outputRoot 'snapshot.json'
$passed=0
try{
    foreach($shape in @('array','map','missing','nonzero')){
        $peers=switch($shape){
            'array' {@(@{name='server';exit_code=0},@{name='A';exit_code=0})}
            'map' {@{server=@{exit_code=0};A=@{exit_code=0}}}
            'missing' {@(@{name='server'})}
            'nonzero' {@{server=@{exit_code=9}}}
        }
        @{status='passed';processes=$peers;hashes=@()}|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $summaryPath
        $accepted=$false
        try{
            & (Join-Path $repo 'Validation/Save-UEPBatchAcceptance.ps1') -Batch $shape -Scope 'Synthetic ledger format test, not native evidence' -EvidenceDirectories @($inputRoot) -OutputFile $outputPath
            $accepted=$true
        }catch{if($shape -in @('array','map')){throw}}
        if($accepted -ne ($shape -in @('array','map'))){throw "Wrong ledger decision for $shape"}
        if($accepted){
            $result=Get-Content -LiteralPath $outputPath -Raw|ConvertFrom-Json
            if(@($result.runs[0].peer_exit_codes.PSObject.Properties).Count -ne 2){throw 'Lost native peer exits'}
            Remove-Item -LiteralPath $outputPath
        }
        $passed++
    }
}finally{
    if(Test-Path -LiteralPath $outputPath){Remove-Item -LiteralPath $outputPath}
    if(Test-Path -LiteralPath $summaryPath){Remove-Item -LiteralPath $summaryPath}
    Remove-Item -LiteralPath $outputRoot
    Remove-Item -LiteralPath $inputRoot
}
Write-Host "Batch acceptance format checks PASS: $passed (synthetic, no native runtime claim)"
