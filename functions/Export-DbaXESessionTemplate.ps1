#ValidationTags#Messaging,FlowControl,Pipeline,CodeStyle#
function Export-DbaXESessionTemplate {
    <#
    .SYNOPSIS
        Exports an XESession XML Template using XE Session(s) output by Get-DbaXESession

    .DESCRIPTION
        Exports an XESession XML Template either from the Target SQL Server or XE Session(s) output by Get-DbaXESession. Exports to "$home\Documents\SQL Server Management Studio\Templates\XEventTemplates" by default

    .PARAMETER SqlInstance
        The target SQL Server instance or instances. You must have sysadmin access and server version must be SQL Server version 2008 or higher.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Windows and SQL Authentication supported. Accepts credential objects (Get-Credential)

    .PARAMETER Session
        The Name of the session(s) to export.

    .PARAMETER Path
        The path to export the file into. Can be .xml or directory.

    .PARAMETER InputObject
        Specifies an XE Session output by Get-DbaXESession.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: ExtendedEvent, XE, XEvent
        Author: Chrissy LeMaire (@cl), netnerds.net

        Website: https://dbatools.io
        Copyright: (c) 2018 by dbatools, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://dbatools.io/Export-DbaXESessionTemplate

    .EXAMPLE
        PS C:\> Export-DbaXESessionTemplate -SqlInstance sql2017 -Path C:\temp\xe

        Exports an XESession XML Template for all Extended Event Sessions on sql2017 to the C:\temp\xe folder.

    .EXAMPLE
        PS C:\> Get-DbaXESession -SqlInstance sql2017 -Session system_health | Export-DbaXESessionTemplate -Path C:\temp\xe

        Gets the system_health Extended Events Session from sql2017 and then exports as an XESession XML Template to C:\temp\xe

    #>
    [CmdletBinding()]
    param (
        [Alias("ServerInstance", "SqlServer")]
        [DbaInstanceParameter[]]$SqlInstance,
        [PSCredential]$SqlCredential,
        [object[]]$Session,
        [string]$Path = "$home\Documents\SQL Server Management Studio\Templates\XEventTemplates",
        [Parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.XEvent.Session[]]$InputObject,
        [switch]$EnableException
    )
    process {
        foreach ($instance in $SqlInstance) {
            try {
                $InputObject += Get-DbaXESession -SqlInstance $instance -SqlCredential $SqlCredential -Session $Session -EnableException
            } catch {
                Stop-Function -Message "Error occurred while establishing connection to $instance" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }
        }

        foreach ($xes in $InputObject) {
            $xesname = Remove-InvalidFileNameChars -Name $xes.Name

            if (-not (Test-Path -Path $Path)) {
                Stop-Function -Message "$Path does not exist." -Target $Path
            }

            if ($path.EndsWith(".xml")) {
                $filename = $path
            } else {
                $filename = "$path\$xesname.xml"
            }
            Write-Message -Level Verbose -Message "Wrote $xesname to $filename"
            [Microsoft.SqlServer.Management.XEvent.XEStore]::SaveSessionToTemplate($xes, $filename, $true)
            Get-ChildItem -Path $filename
        }
    }
}