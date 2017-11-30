# Copy-Command

## Archived
The code in this project has been moved to [PSScriptTools](https://github.com/jdhitsolutions/PSScriptTools). This repository has been archived.

## Original README
This command will copy a PowerShell command, typically a cmdlet, including parameters and help to a new user-specified command. You can also specify an alias in place of the actual command name.

You can use this *copied* command to create a "wrapper" function or to easily create a proxy function. The default behavior is to create a copy of the command complete with the original comment-based help block.  

Once completed, all you need to do is remove or modify the parameters, update script blocks or script command if creating a proxy version, and update help to reflect your new command.

The goal for *Copy-Command* is to serve as an accelerator for rapidly creating your own PowerShell tools based on existing PowerShell commands.

For best results, run this command in the PowerShell ISE so that the copied command will be opened in a new tab automatically.

    Copy-Command Get-ADComputer Get-MyADComputer -includedynamic

This command will copy a PowerShell command, typically a cmdlet, including parameters and help to a new user-specified command. You can also specify an alias in place of the actual command name.

You can use this *copied* command to create a "wrapper" function or to easily create a proxy function. The default behavior is to create a copy of the command complete with the original comment-based help block.  

Once completed, all you need to do is remove or modify the parameters, updatescript blocks or script command if creating a proxy version, and update help to reflect your new command.

The goal for *Copy-Command* is to serve as an accelerator for rapidly creating your own PowerShell tools based on existing PowerShell commands.

For best results, run this command in the PowerShell ISE so that the copied command will be opened in a new tab automatically. If you run the command in Visual Studio Code you will get a message to press Ctrl+N to create a new file and then Ctrl+V to paste the code for the copied command.

##### Examples
    Copy-Command Get-ADComputer Get-MyADComputer -includedynamic

Create a wrapper function for Get-ADComputer called Get-MyADComputer. Due to the way the Active Directory cmdlets are written, most parameters appear to be dynamic so you need to include dynamic parameters otherwise there will be no parameters in the final function.

    Copy-Command Get-CimInstance Get-MyDisks -AsProxy

Create a proxy version of Get-CimInstance called Get-MyDisks.

## Module
The command is now packaged in a basic module without a manifest. Import the module to access the command and its alias, *cc*.

*Last Updated May 1, 2017*
