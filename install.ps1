$fileName = 
@{
  powerShellProfile = "Microsoft.PowerShell_profile.ps1"
  vimrc = ".vimrc"
  vimfiles = "vimfiles"
  gitconfig = ".gitconfig"
}

function Get-CurrentScriptPath
{
  Split-Path $myInvocation.ScriptName 
}

function Get-DotFilePath
{
  param
  (
    [Parameter(Mandatory=$true)][string] $file
  )
  Join-Path (Get-CurrentScriptPath) $file
}

function Install-DotFiles
{
  Write-Host "Installing PowerShell Profile..." -NoNewLine
  $dotFile = Get-DotFilePath $fileName.powerShellProfile
  . $dotFile
  $installPath = Join-Path (Join-Path $HOME "Documents\WindowsPowerShell") $fileName.powerShellProfile
  New-Symlink $installPath $dotFile -Force
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Installing vimrc..." -NoNewLine
  $dotFile = Get-DotFilePath $fileName.vimrc
  $installPath = Join-Path $HOME $fileName.vimrc
  New-Symlink $installPath $dotFile -Force
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Installing vimfiles..." -NoNewLine
  $dotFile = Get-DotFilePath $fileName.vimfiles
  $installPath = Join-Path $HOME $fileName.vimfiles
  New-Junction $installPath $dotFile -Force
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Installing gitconfig..." -NoNewLine
  $dotFile = Get-DotFilePath $fileName.gitconfig
  $installPath = Join-Path $HOME $fileName.gitconfig
  New-Symlink $installPath $dotFile -Force
  Write-Host "done" -ForegroundColor DarkGreen
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
