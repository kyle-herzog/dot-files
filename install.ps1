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
  $installer_data =
  @{
    powerShellProfile = "powershell\Microsoft.PowerShell_profile.ps1"
    originalPowerShellProfile = "powershell\Microsoft.PowerShell_profile.orig.ps1"
    vimrc = "vim/.vimrc"
    vimfiles = "vim/vimfiles"
    gitconfig = "git/.gitconfig"
    console2 = "http://sourceforge.net/projects/console/files/latest/download"
    console = "console.xml"
    pathogen = "vim/vimfiles/bundle/pathogen/autoload"
    poshgit = "powershell\posh-git"
    poshVmManagement = "powershell\posh-vm-management\install.ps1"
    consolePath = 'E:\Development\Tools\Console'
  }

  Write-Host "Initializing SubModules..." -NoNewLine
  & git submodule update --init --recursive | Out-Null
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Installing Posh-Git..." -NoNewLine
  $dotFile = Get-DotFilePath $installer_data.poshgit
  $psProfile = Get-DotFilePath $installer_data.originalPowerShellProfile
  . $psProfile
  $userpsmodules = Join-Path $HOME "Documents\WindowsPowerShell\Modules"
  if(!(Test-Path $userpsmodules))
  {
    New-Item $userpsmodules -Type Directory | Out-Null
  }
  $installPath = Join-Path $userpsmodules (Split-Path $installer_data.poshgit -leaf)
  New-Junction $installPath $dotFile -Force | Out-Null
  Write-Host "done" -ForegroundColor DarkGreen

  $dotFile = Get-DotFilePath $installer_data.poshVmManagement
  . $dotFile

  Write-Host "Installing PowerShell Profile..."
  $workspacepath = "C:\dev\workspaces"
  $promptValue = Read-Host "What is the path to your workspace? (leave empty to default to $workspacepath)"
  if($promptValue)
  {
    $workspacepath = $promptValue
  }
  Write-Host ($workspacepath)
  Write-Host ($installer_data.originalPowerShellProfile)

  $original_file = Get-DotFilePath $installer_data.originalPowerShellProfile

  Write-Host "Original File - $original_file"

  $dotFile = Get-DotFilePath $installer_data.powerShellProfile

  Write-Host "Dot File - $dotFile"

  if(Test-Path $dotFile)
  {
    Remove-Item $dotFile -Force
  }

  Write-Host "passed dotfile check"

  (Get-Content $original_file) | Foreach-Object {
      $_ -replace '<workspacepath>', "$workspacepath" `
      } | Set-Content $dotFile

  Write-Host "passed dotfile customization"

  $userpshome = Join-Path $HOME "Documents\WindowsPowerShell"

  Write-Host "UserPSHome $userpshome"

  if(!(Test-Path $userpshome))
  {
    New-Item $userpshome -Type Directory | Out-Null
  }
  $installPath = Join-Path $userpshome (Split-Path $installer_data.powerShellProfile -leaf)
  New-Symlink $installPath $dotFile -Force | Out-Null
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Installing vimrc..." -NoNewLine
  $dotFile = Get-DotFilePath $installer_data.vimrc
  $installPath = Join-Path $HOME (Split-Path $installer_data.vimrc -leaf)
  New-Symlink $installPath $dotFile -Force | Out-Null
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Installing vimfiles..." -NoNewLine
  $dotFile = Get-DotFilePath $installer_data.vimfiles
  $installPath = Join-Path $HOME (Split-Path $installer_data.vimfiles -leaf)
  New-Junction $installPath $dotFile -Force | Out-Null
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Installing pathogen autorun..." -NoNewLine
  $dotFile = Get-DotFilepath $installer_data.pathogen
  $installPath = Join-Path $installPath "autoload"
  New-Junction $installPath $dotFile -Force | Out-Null
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Installing gitconfig..." -NoNewLine
  $dotFile = Get-DotFilePath $installer_data.gitconfig
  $installPath = Join-Path $HOME (Split-Path $installer_data.gitconfig -leaf)
  New-Symlink $installPath $dotFile -Force | Out-Null
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Downloading console2..." -NoNewLine

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
