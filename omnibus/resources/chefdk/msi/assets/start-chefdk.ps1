Try {
    $conemulocation = "$env:programfiles\ConEmu\Conemu64.exe"
    $chefdk_bin = (split-path $MyInvocation.MyCommand.Definition -Parent)

    $block = @"
        # We don't want the current path to affect which "chef shell-init powershell" we run, so we need to set the PATH to include the current omnibus.
        `$env:PATH = "$chefdk_bin" + ';' + `$env:PATH
        `$env:CHEFDK_ENV_FIX = 1
        chef shell-init powershell | out-string | iex
        Import-Module chef -DisableNameChecking
        write-host "PowerShell `$(`$PSVersionTable.psversion.tostring()) (`$([System.Environment]::OSVersion.VersionString))"
        write-host -foregroundcolor darkyellow 'Ohai, welcome to ChefDK!`n'
"@
    $chefdktitle = "ChefDK ($env:username)"

    if ( test-path $conemulocation )
    {
        $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($block))
        start-process $conemulocation -argumentlist '/title',"`"$chefdktitle`"",'/cmd','powershell.exe','-noexit','-EncodedCommand',$encoded
        Stop-Process $PID
    }
    else
    {
        Invoke-Expression $block
    }
}
Catch
{
    sleep 10
    Throw
}
