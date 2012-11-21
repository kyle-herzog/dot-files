function Get-CurrentScriptPath
{
  Split-Path $myInvocation.ScriptName
}

function Get-ScriptDirectory
{
  Split-Path $myInvocation.ScriptName
}

function Get-ScriptName
{
  $myInvocation.ScriptName
}

function Get-DotFilePath
{
  param
  (
    [Parameter(Mandatory=$true)][string] $file
  )
  Join-Path (Get-CurrentScriptPath) $file
}

function Test-ElevatedShell
{
  $user = [Security.Principal.WindowsIdentity]::GetCurrent()
  (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function ConvertTo-Boolean
{
  param
  (
    [Parameter(Mandatory=$false)][string] $value
  )
  switch ($value)
  {
    "y" { return $true; }
    "yes" { return $true; }
    "true" { return $true; }
    "t" { return $true; }
    1 { return $true; }
    "n" { return $false; }
    "no" { return $false; }
    "false" { return $false; }
    "f" { return $false; }
    0 { return $false; }
  }
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
    originalGitconfig = "git/.gitconfig.original"
    console2 = "http://sourceforge.net/projects/console/files/latest/download"
    console = "console.xml"
    pathogen = "vim/vimfiles/bundle/pathogen/autoload"
    poshgit = "powershell\posh-git"
    poshVmManagement = "powershell\posh-vm-management\install.ps1"
    consolePath = 'E:\Development\Tools\Console'
    gitGlobalIgnore = 'git/.git_global_ignore'
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
  $original_file = Get-DotFilePath $installer_data.originalPowerShellProfile
  $dotFile = Get-DotFilePath $installer_data.powerShellProfile
  if(Test-Path $dotFile)
  {
    Remove-Item $dotFile -Force
  }
  (Get-Content $original_file) | Foreach-Object {
      $_ -replace '<workspacepath>', "$workspacepath" `
      } | Set-Content $dotFile
  $userpshome = Join-Path $HOME "Documents\WindowsPowerShell"
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
  $original_file = Get-DotFilePath $installer_data.originalGitconfig
  $dotFile = Get-DotFilePath $installer_data.gitconfig
  $installPath = Join-Path $HOME (Split-Path $installer_data.gitconfig -leaf)

  $gitUserName = ""
  $promptValue = ""
  while(!$promptValue)
  {
    $promptValue = Read-Host "What is the user.name for git?"
  }
  $gitUserName = $promptValue

  $gitUserEmail = ""
  $promptValue = ""
  while(!$promptValue)
  {
    $promptValue = Read-Host "What is the user.email for git?"
  }
  $gitUserEmail = $promptValue

  if(Test-Path $dotFile)
  {
    Remove-Item $dotFile -Force
  }
  (Get-Content $original_file) | Foreach-Object {
      $_ -replace '<user.name>', "$gitUserName" `
         -replace '<user.email>', "$gitUserEmail" `
      } | Set-Content $dotFile

  New-Symlink $installPath $dotFile -Force | Out-Null

  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Installing gitignore..." -NoNewLine
  $git_global_ignore = Get-DotFilePath $installer_data.gitGlobalIgnore
  & git config --global core.excludesfile $git_global_ignore
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Downloading console2..." -NoNewLine

  Write-Host "done" -ForegroundColor DarkGreen

}

try
{
  if(!(Test-ElevatedShell))
  {
    $answer = Read-Host -Prompt "You are not running as an Administrator. Would you like me to automatically restart as an Administrator?"
    $parsedAnswer = ConvertTo-Boolean $answer
    if($parsedAnswer)
    {
      Start-Process "powershell" "-ExecutionPolicy Bypass -noexit $(Get-ScriptName)" -Verb runAs
    }
    else
    {
      Write-Warning "Did not finish bootstrapping as current prompt is without administraion priviledges..."
    }
  }
  else
  {
    Write-Host "Installing dot-files..."
    Install-DotFiles
    Write-Host "Installing dot-files...done" -ForegroundColor DarkGreen
  }
}
catch
{
  Write-Error ($_.Exception)
}
