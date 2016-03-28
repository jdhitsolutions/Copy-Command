#requires -version 4.0

<#
copy a PowerShell command including parameters and help to 
turn it into a wrapper or a proxy function

run this in the PowerShell ISE for best results
#>

Function Copy-Command {

<#
.Synopsis
Copy a PowerShell command
.Description
This command will copy a PowerShell command, including parameters and help to a new user-specified command. You can use this to create a "wrapper" function or to easily create a proxy function. The default behavior is to create a copy of the command complete with the original comment-based help block.

For best results, run this in the PowerShell ISE so that the copied command will be opened in a new tab.
.Parameter Command
The name of a PowerShell command, preferably a cmdlet but that is not a requirment. You can specify an alias and it will be resolved.

.Parameter NewName
Specify a name for your copy of the command. If no new name is specified, the original name will be used.

.Parameter IncludeDynamic
The command will only copy explicitly defined parameters unless you specify to include any dynamic parameters as well. If you copy a command and it seems to be missing parameters, re-copy and include dynamic parameters.

.Parameter AsProxy
Create a traditional proxy function.

.Parameter UseForwardHelp
By default the copy process will create a comment-based help block with the original command's help which you can then edit to meet your requirements. Or you can opt to retain the forwarded help links to the original command.
.Example
PS C:\> Copy-Command Get-Process Get-MyProcess 

Create a copy of Get-Process called Get-MyProcess.
.Example
PS C:\> Copy-Command Get-Eventlog -asproxy -useforwardhelp

Create a proxy function for Get-Eventlog and use forwarded help links.
.Example
PS C:\> Copy-Command Get-ADComputer Get-MyADComputer -includedynamic

Create a wrapper function for Get-ADComputer called Get-MyADComputer. Due to the way the Active Directory cmdlets are written, most parameters appear to be dynamic so you need to include dynamic parameters otherwise there will be no parameters in the final function.

.Notes
Last Updated: November 25, 2015
Version     : 1.0

Learn more about PowerShell:
http://jdhitsolutions.com/blog/essential-powershell-resources/

  ****************************************************************
  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
  ****************************************************************

.Link
Get-Command
.Inputs
None
.Outputs
[string[]]
#>

[cmdletbinding()]
Param(
[Parameter(Position = 0,Mandatory,HelpMessage = "Enter the name of a PowerShell command")]
[ValidateNotNullorEmpty()]
[string]$Command,
[Parameter(Position = 1,HelpMessage = "Enter the new name for your command using Verb-Noun convention")]
[ValidateNotNullorEmpty()]
[string]$NewName,
[switch]$IncludeDynamic,
[switch]$AsProxy,
[switch]$UseForwardHelp
)

Try {
    Write-Verbose "Getting command metadata for $command"
    $gcm = Get-Command -Name $command -ErrorAction Stop
    #allow an alias or command name
    if ($gcm.CommandType -eq 'Alias') {
        $cmdName = $gcm.ResolvedCommandName
    }
    else {
        $cmdName = $gcm.Name
    }
    Write-Verbose "Resolved to $cmdName"
    $cmd = New-Object System.Management.Automation.CommandMetaData $gcm
}
Catch {
    Write-Warning "Failed to create command metadata for $command"
    Write-Warning $_.Exception.Message
}

if ($cmd) {
    #create the metadata
        
    if ($NewName) {
        $Name = $NewName
    }
    else {
        $Name = $cmd.Name
    }

#define a metadata comment block
$myComment = @"
<#
This is a copy of:

$(($gcm | format-table -AutoSize | out-string).trim())

Created: $('{0:dd} {0:y}' -f (get-date))
Author : $env:username

  ****************************************************************
  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
  ****************************************************************
#>

"@

#define the beginning of text for the new command
#dynamically insert the command's module if one exists
$text = @"
#requires -version $(([regex]"\d+\.\d+").match($psversiontable.psversion).value)
$(if ($gcm.modulename -AND $gcm.modulename -notmatch "Microsoft\.PowerShell\.\w+") { "#requires -module $($gcm.modulename)" })

$myComment

Function $Name {

"@

#manually copy parameters from original command if param block not found
#this can happen with dynamic parameters like those in the AD cmdlets
if (-Not [System.Management.Automation.ProxyCommand]::GetParamBlock($gcm)) {
    Write-Verbose "No param block detected. Looking for dynamic parameters"
    $IncludeDynamic = $True
}

if ($IncludeDynamic) {
    Write-Verbose "Adding dynamic parameters"
    $params = $gcm.parameters.GetEnumerator() | where { $_.value.IsDynamic}
        foreach ($p in $params) {
        $cmd.Parameters.add($p.key,$p.value)
    }
}

if ($UseForwardHelp) {
    #define a regex to pull forward help from a proxy command
    [regex]$rx = "\.ForwardHelp.*\s+\.ForwardHelp.*"
    $help = $rx.match([System.Management.Automation.ProxyCommand]::Create($cmd)).Value 
}
else {
    #if not using the default Forwardhelp links, get comment based help instead

    #get help as a comment block
    $help = [System.Management.Automation.ProxyCommand]::GetHelpComments((get-help $Command))
    #substitute command name
    $help = $help -replace $Command,$NewName

    #remove help link
    $cmd.HelpUri = $null
}

    Write-Verbose "Adding Help"
    $Text += @"
<#
$help
#>

"@

    #cmdletbinding
    $Text += [System.Management.Automation.ProxyCommand]::GetCmdletBindingAttribute($cmd)

    #get parameters
    $NewParameters = [System.Management.Automation.ProxyCommand]::GetParamBlock($cmd)

     Write-Verbose "Cleaning up parameter names"
     [regex]$rx= '\]\r\s+\${(?<var>\w+)}'
     #replace the {variable-name} with just variable-name and joined to type name
     $NewParameters = $rx.Replace($NewParameters,']$$${var}')

    #Insert parameters
    $Text += @"

Param(
$NewParameters
)

Begin {

    Write-Verbose "Starting `$(`$MyInvocation.Mycommand)"
    Write-Verbose "Using parameter set `$(`$PSCmdlet.ParameterSetName)"
    Write-Verbose (`$PSBoundParameters | Out-String)

"@

    Write-Verbose "Adding Begin"

    if ($AsProxy) {
        $Text += [System.Management.Automation.ProxyCommand]::GetBegin($cmd)
    }
    
    $Text += @"

} #begin

Process {


"@

    Write-Verbose "Adding Process"
    if ($AsProxy) {
        $Text += [System.Management.Automation.ProxyCommand]::GetProcess($cmd)
    }
    else {
        $Text += @"
    $($cmd.name) @PSBoundParameters
"@
    }

    $Text += @"


} #process

End {
   
    Write-Verbose "Ending `$(`$MyInvocation.Mycommand)"

"@

    Write-Verbose "Adding End"
    If ($AsProxy) {
        $Text += [System.Management.Automation.ProxyCommand]::GetEnd($cmd)
    }

    $Text += @"

} #end

"@

#insert closing text
$Text += @"

} #end function $Name
"@
    if ($host.Name -match "PowerShell ISE") {
    #open in a new ISE tab
    $tab = $psise.CurrentPowerShellTab.Files.Add()

    Write-Verbose "Opening new command in a new ISE tab"
    $tab.editor.InsertText($Text)

    #jump to the top
    $tab.Editor.SetCaretPosition(1,1)
    }
    else {
      #just write the new command to the pipeline
      $Text
    }
}
Write-Verbose "Ending $($MyInvocation.MyCommand)"

}#end Copy-Command

Set-Alias -Name cc -Value Copy-Command
