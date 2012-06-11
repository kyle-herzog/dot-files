$editor = 'gvim'
$git =
@{
  opensource = "C:\dev\opensource"
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

. 'E:\Development\Workspaces\Kyzog\posh-git\profile.example.ps1'

Add-SshKey C:\Users\Kyle\.ssh\kyzog_homedns

