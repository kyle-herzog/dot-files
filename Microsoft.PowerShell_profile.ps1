$editor = 'gvim'
$git =
@{
  workspaces = "C:\dev"
}

function Get-ChildDirectories
{
  param
  (
    [Parameter(Mandatory=$true)][string] $path
  )
  
  if((Test-Path $path))
  {
    Get-ChildItem $path | Where-Object { $_.mode -match "d" }
  }
}

function New-Symlink {
  <#
  .SYNOPSIS
    Creates a symbolic link.
  #>
  param (
    [Parameter(Position=0, Mandatory=$true)]
    [string] $Link,
    [Parameter(Position=1, Mandatory=$true)]
    [string] $Target,
    [switch] $Force
  )

  Invoke-MKLINK @psBoundParameters -Symlink
}


function New-Hardlink {
  <#
  .SYNOPSIS
    Creates a hard link.
  #>
  param (
    [Parameter(Position=0, Mandatory=$true)]
    [string] $Link,
    [Parameter(Position=1, Mandatory=$true)]
    [string] $Target,
    [switch] $Force
  )

  Invoke-MKLINK @psBoundParameters -HardLink
}


function New-Junction {
  <#
  .SYNOPSIS
    Creates a directory junction.
  #>
  param (
    [Parameter(Position=0, Mandatory=$true)]
    [string] $Link,
    [Parameter(Position=1, Mandatory=$true)]
    [string] $Target,
    [switch] $Force
  )

  Invoke-MKLINK @psBoundParameters -Junction
}


function Invoke-MKLINK {
  <#
  .SYNOPSIS
    Creates a symbolic link, hard link, or directory junction.
  #>
  [CmdletBinding(DefaultParameterSetName = "Symlink")]
  param (
    [Parameter(Position=0, Mandatory=$true)]
    [string] $Link,
    [Parameter(Position=1, Mandatory=$true)]
    [string] $Target,

    [Parameter(ParameterSetName = "Symlink")]
    [switch] $Symlink = $true,
    [Parameter(ParameterSetName = "HardLink")]
    [switch] $HardLink,
    [Parameter(ParameterSetName = "Junction")]
    [switch] $Junction,
    [switch] $Force
  )

  # Ensure target exists.
  if (-not(Test-Path $Target)) {
    throw "Target does not exist.`nTarget: $Target"
  }

  # Ensure link does not exist.
  if (Test-Path $Link) {
    if($Force)
    {
      try
      {
        (Get-Item $Link).Delete()
      }
      catch{}
      if(Test-Path $Link)
      {
        Remove-Item $Link -Resurce -Force
      }
    }
    else
    {
      throw "A file or directory already exists at the link path.`nLink: $Link"
    }
  }

  $isDirectory = (Get-Item $Target).PSIsContainer
  $mklinkArg = ""

  if ($Symlink -and $isDirectory) {
    $mkLinkArg = "/D"
  }

  if ($Junction) {
    # Ensure we are linking a directory. (Junctions don't work for files.)
    if (-not($isDirectory)) {
      throw "The target is a file. Junctions cannot be created for files.`nTarget: $Target"
    }

    $mklinkArg = "/J"
  }

  if ($HardLink) {
    # Ensure we are linking a file. (Hard links don't work for directories.)
    if ($isDirectory) {
      throw "The target is a directory. Hard links cannot be created for directories.`nTarget: $Target"
    }

    $mkLinkArg = "/H"
  }

  # Capture the MKLINK output so we can return it properly.
  # Includes a redirect of STDERR to STDOUT so we can capture it as well.
  $output = cmd /c mklink $mkLinkArg `"$Link`" `"$Target`" 2>&1

  if ($lastExitCode -ne 0) {
    throw "MKLINK failed. Exit code: $lastExitCode`n$output"
  }
  else {
    Write-Output $output
  }
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

function Edit-ProfileFile
{
  Edit-File $profile
}
Set-Alias epf Edit-ProfileFile

function Edit-File
{
  param
  (
  [Parameter(Mandatory=$false)] [string] $file
  )
  & $editor $file
}
Set-Alias edit Edit-File
Set-Alias ef Edit-File

function Start-BashScript
{
  param
  (
  [Parameter(Mandatory=$true)] [string] $script
  )
  & sh $script
}

function Repair-NetworkConnection
{
  Write-Host "Releasing Network Connection..." -NoNewLine
  ipconfig /release | Out-Null
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Renewing Network Connection..." -NoNewLine
  ipconfig /renew | Out-Null 
  Write-Host "done" -ForegroundColor DarkGreen

  Write-Host "Flushing DNS..." -NoNewLine
  ipconfig /flushdns | Out-Null
  Write-Host "done" -ForegroundColor DarkGreen
}
Set-Alias rnc Repair-NetworkConnection

function Open-WindowsExplorer
{
  & explorer .
}
Set-Alias wui Open-WindowsExplorer

function Open-Solution
{
  $solutions = Get-ChildItem **\*.sln -Recurse
  if(!$solutions)
  {
  Write-Host "There are no solution files within the current/sub directory" -ForegroundColor DarkRed
  }
  elseif($solutions.Count -gt 1)
  {
  Write-Host "There is more than one solution file in the currentsub directory"
  }
  else
  {
  Invoke-Item $solutions | Out-Null
  }
}
Set-Alias os Open-Solution

function Get-GitRepositoryPath
{
  param
  (
    [Parameter(Mandatory=$true)][string] $repoPath
  )

  try
  {
    $uri = New-Object System.Uri($repoPath)
    $gitPath = $uri.LocalPath.Replace(".git", "")
  }
  catch
  {
    $index = $repoPath.LastIndexOf(":")
    $gitPath = $repoPath.SubString($index + 1, $repoPath.Length - $index - 1).Replace(".git", "")
  }
  Join-Path $git.workspaces $gitPath
}

function Get-ClonedGitRepository
{
  param
  (
  [Parameter(Mandatory=$true)][string] $repoPath,
  [string] $dir
  )
  if(!($dir))
  {
  $dir = Get-GitRepositoryPath $repoPath
  }
  if(!(Test-Path $dir))
  {
  New-Item $dir -Type Directory
  }
  git clone $repoPath $dir
}
Set-Alias gclone Get-ClonedGitRepository


function Expand-Item
{
  param
  (
    [Parameter(Mandatory=$true)] [string] $zipFile,
    [Parameter(Mandatory=$true)] [string] $destinationDirectory
  )
  
  if (!(Test-Path -Path $zipFile -PathType Leaf))
  {
    throw ("Specified zipFile is invalid: " + $zipFile)
  }

  if (!(Test-Path -Path $destinationDirectory -PathType Container))
  {
    New-Item $destinationDirectory -ItemType Directory | Out-Null
  }
  
  $shell_app = new-object -com shell.application 
  $zip_file = $shell_app.namespace($zipFile) 
  $destination = $shell_app.namespace($destinationDirectory) 
  $destination.Copyhere($zip_file.items(), 0x14)
}

function New-TempDirectory
{
  $tempDirectory = $env:temp
  $retVal = Join-Path $tempDirectory ([guid]::NewGuid())
  while(Test-Path $retVal -ErrorAction SilentlyContinue)
  {
    $retVal = Join-Path $tempDirectory ([guid]::NewGuid())
  }
  New-Item $retVal -type Directory | Out-Null
  $retVal
}

function Set-EnvironmentVariable
{
  param
  (
    [Parameter(Mandatory=$true)] [string] $name,
    [Parameter(Mandatory=$true)] [string] $value,
    [Parameter(Mandatory=$false)] [string] $scope = "process",
    [switch] $appendValue
  )
  $scope = $scope.ToLower()
  
  if(($scope -ne "machine") -and ($scope -ne "user") -and ($scope -ne "process"))
  {
    THROW New-Object System.Exception "Scope must be 'machine', 'user', or 'process'"
  }
  
  if($appendValue)
  {
    $newValue = (Get-Item "Env:\$name").Value
    if(!$newValue.Contains($value))
    {
      $newValue += ";$value"
    }
    $value = $newValue
  }
  Set-Item -Path "Env:$name" -Value "$value"
  [Environment]::SetEnvironmentVariable("$name", "$value", "$scope")
}

function Copy-Item-RoboCopy
{
  param
  (
    [Parameter(Mandatory = $true)] [string] $source
    ,[Parameter(Mandatory = $true)] [string] $destination
    ,[Parameter(Mandatory = $false)] [string] $file
    ,[Parameter(Mandatory = $false)] [switch] $mirror
    ,[Parameter(Mandatory = $false)] [switch] $recurse
  )
  
  $roboCopyArguments = "`"$source`" `"$destination`""
  
  if($file)
  {
    $roboCopyArguments += " $file"
  }
  $roboCopyArguments += " /V"
  
  if($mirror)
  {
    $roboCopyArguments += ' /MIR'
  }
  else 
  {
    if($recurse)
    {
      $roboCopyArguments += ' /E'
    }
  }
  
  $roboCopyOutput = robocopy $roboCopyArguments
  
  if($file)
  {
    return "$destination\$file"
  }
}

function Test-Key([string] $path, [string] $key)
{
  return ((Test-Path $path) -and ((Get-Key $path $key) -ne $null))   
}

function Remove-Key([string] $path, [string] $key)
{
  Remove-ItemProperty -path $path -name $key
}

function Set-Key([string] $path, [string] $key, [string] $value) 
{
  Set-ItemProperty -path $path -name $key -value $value
}

function Get-Key([string] $path, [string] $key) 
{
  return (Get-ItemProperty $path).$key
}

function Restart-And-Run([string] $key, [string] $run) 
{
  Set-Key $global:RegRunKey $key $run
  Read-Host -Prompt "Press Enter to restart"
  Restart-Computer
}

function Restart-And-PowerShell([string]$scriptPath) 
{
   Restart-And-Run $global:restartKey "$global:powershell `"& '$scriptPath'`""
}

function Clear-Any-Restart([string] $key=$global:restartKey) 
{
  if (Test-Key $global:RegRunKey $key) {
    Remove-Key $global:RegRunKey $key
  }
}

Import-Module Posh-Git -ErrorAction SilentlyContinue
if(Get-Module Posh-Git)
{
  Enable-GitColors
  Start-SshAgent -Quiet
}
else
{
  Write-Warning "Posh-Git module was not found"
}

function prompt {
  $realLASTEXITCODE = $LASTEXITCODE

  if((Get-Module posh-git))
  {
    # Reset color, which can be messed up by Enable-GitColors
    $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor
  }

  Write-Host($pwd) -nonewline

  if((Get-Module posh-git))
  {
    Write-VcsStatus
  }

  $global:LASTEXITCODE = $realLASTEXITCODE
  return "> "
}
