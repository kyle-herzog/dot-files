function Get-CurrentScriptPath
{
	Split-Path $myInvocation.ScriptName 
}

function Install-DotFiles
{
	$profileFileName = "Microsoft.PowerShell_profile.ps1"
	$profilePath = Join-Path (Get-CurrentScriptPath) $profileFileName
    $installPath = Join-Path (Join-Path $HOME "Documents\WindowsPowerShell") $profileFileName
	Copy-Item $profilePath $installPath -Force
    . $installPath
}

try
{
    Write-Host "Installing dot-files..."
	Install-DotFiles
    Write-Host "Installing dot-files...done" -ForegroundColor DarkGreen
}
catch
{
	Write-Error ($_.Exception)
}
