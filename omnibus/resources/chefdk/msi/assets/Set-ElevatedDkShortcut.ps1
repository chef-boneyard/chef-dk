Import-Module C:\windows\system32\windowspowershell\v1.0\Modules\Microsoft.PowerShell.Utility\Microsoft.PowerShell.Utility.psd1
Import-Module C:\windows\system32\windowspowershell\v1.0\Modules\Microsoft.PowerShell.Management\Microsoft.PowerShell.Management.psd1

@(
  [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonDesktopDirectory),
  [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonPrograms)
) | % {
  $linkFile = Join-Path $_ "Chef Development Kit.lnk"

  if(Test-Path($linkFile)) {
    Write-Output "Editing Elevation level of $linkFile"

    $bytes = [System.IO.File]::ReadAllBytes($linkFile)

    # Setting the 22nd byte to 34 will elevate the shortcut
    $bytes[21] = 34

    [System.IO.File]::WriteAllBytes($linkFile, $bytes)
  }
}
