$fileName = 
@{
  powerShellProfile = "Microsoft.PowerShell_profile.ps1"
  vimrc = ".vimrc"
  vimfiles = "vimfiles"
  gitconfig = ".gitconfig"
  console2 = "http://sourceforge.net/projects/console/files/latest/download"
  console = "console.xml"
  pathogen = "vimfiles/bundle/pathogen/autoload"
  poshgit = "posh-git"
}

$directories =
@{
  console = 'E:\Development\Tools\Console'
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
  Write-Host "Initializing SubModules..." -NoNewLine
  & git submodule update --init --recursive | Out-Null
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Installing Posh-Git..." -NoNewLine
  $dotFile = Get-DotFilePath $fileName.poshgit
  $psProfile = Get-DotFilePath $fileName.powerShellProfile
  . $psProfile
  $userpsmodules = Join-Path $HOME "Documents\WindowsPowerShell\Modules"
  if(!(Test-Path $userpsmodules))
  {
    New-Item $userpsmodules -Type Directory | Out-Null
  }
  $installPath = Join-Path $userpsmodules $fileName.poshgit
  New-Junction $installPath $dotFile -Force | Out-Null
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Installing PowerShell Profile..." -NoNewLine
  $dotFile = Get-DotFilePath $fileName.powerShellProfile
  . $dotFile
  $userpshome = Join-Path $HOME "Documents\WindowsPowerShell"
  if(!(Test-Path $userpshome))
  {
    New-Item $userpshome -Type Directory | Out-Null
  }
  $installPath = Join-Path $userpshome $fileName.powerShellProfile
  New-Symlink $installPath $dotFile -Force | Out-Null
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Installing vimrc..." -NoNewLine
  $dotFile = Get-DotFilePath $fileName.vimrc
  $installPath = Join-Path $HOME $fileName.vimrc
  New-Symlink $installPath $dotFile -Force | Out-Null
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Installing vimfiles..." -NoNewLine
  $dotFile = Get-DotFilePath $fileName.vimfiles
  $installPath = Join-Path $HOME $fileName.vimfiles
  New-Junction $installPath $dotFile -Force | Out-Null
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Installing pathogen autorun..." -NoNewLine
  $dotFile = Get-DotFilepath $fileName.pathogen
  $installPath = Join-Path $installPath "autoload"
  New-Junction $installPath $dotFile -Force | Out-Null
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Installing gitconfig..." -NoNewLine
  $dotFile = Get-DotFilePath $fileName.gitconfig
  $installPath = Join-Path $HOME $fileName.gitconfig
  New-Symlink $installPath $dotFile -Force | Out-Null
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Downloading console2..." -NoNewLine

  Write-Host "done" -ForgroundColor DarkGreen

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
