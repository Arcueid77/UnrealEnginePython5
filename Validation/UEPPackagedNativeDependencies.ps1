# Read-only inspection of a process that is already running a packaged game.
function Get-UEPPackagedPythonDependency {
    param([Diagnostics.Process]$Process,[string]$PackageRoot,
          [string]$EngineRoot='F:/UnrealEngine')
    $root=[IO.Path]::GetFullPath($PackageRoot)+[IO.Path]::DirectorySeparatorChar
    $runtime=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python311.dll'
    if($Process.HasExited){return $null}
    $Process.Refresh()
    $all=@($Process.Modules)
    $sourceRoot=[IO.Path]::GetFullPath($EngineRoot)+[IO.Path]::DirectorySeparatorChar
    if(@($all|Where-Object {[IO.Path]::GetFullPath($_.FileName).StartsWith($sourceRoot,[StringComparison]::OrdinalIgnoreCase)}).Count){throw 'Packaged process loaded a DLL from the source Engine installation'}
    $modules=@($all|Where-Object {$_.ModuleName -ieq 'python311.dll'})
    if(!$modules.Count){return $null}
    if($modules.Count -ne 1){throw 'Ambiguous loaded CPython runtime'}
    $path=[IO.Path]::GetFullPath($modules[0].FileName)
    if(!$path.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){throw 'Packaged game loaded CPython from outside its archive'}
    $hash=(Get-FileHash -LiteralPath $path).Hash
    if($hash -ne (Get-FileHash -LiteralPath $runtime).Hash){throw 'Packaged game loaded a different CPython runtime'}
    return @{path=$path;sha256=$hash;actual_loaded_module=$true;inside_package=$true;loaded_modules_at_inspection=$all.Count;source_engine_modules_loaded=0}
}
