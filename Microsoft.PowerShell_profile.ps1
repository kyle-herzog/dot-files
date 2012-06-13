$editor = 'gvim'
$git =
@{
	workspaces = "E:\Development\Workspaces"
	poshGitPath = "https://github.com/dahlbyk/posh-git.git"
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
    Write-Host "Generated git path = " $dir
  }
  if(!(Test-Path $dir))
  {
    New-Item $dir -Type Directory
  }
  git clone $repoPath $dir
}
Set-Alias gclone Get-ClonedGitRepository

function Load-PoshGitModule
{
	$modulePath = Get-GitRepositoryPath $git.poshGitPath 
	if(!(Test-Path $modulePath))
	{
		Write-Host "Posh-Git is not downloaded" -ForegroundColor Yellow
		$shouldInstall = (Read-Host "Should an install attempt be performed?")
		if($shouldInstall)
		{
			Get-ClonedGitRepository $git.poshGitPath 
			$success = $true
		}
	}
	else
	{
		$success = $true
	}
	if($success)
	{
		Import-Module $modulePath
		return 0
	}
	else
	{
		return 1
	}
}

$poshGitLoaded = Load-PoshGitModule
if($poshGitLoaded -eq 1)
{
	Enable-GitColors
	Start-SshAgent -Quiet
}

function prompt {
    $realLASTEXITCODE = $LASTEXITCODE

    # Reset color, which can be messed up by Enable-GitColors
    $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor

    Write-Host($pwd) -nonewline

    Write-VcsStatus

    $global:LASTEXITCODE = $realLASTEXITCODE
    return "> "
}


