#Requires -Version 3.0

Function Get-VMSnapshotPath {
<#
    .SYNOPSIS
            This function will return a VM's Snapshot path
    .DESCRIPTION
            This function will return a VM's Snapshot path
    .PARAMETER  Snapshot
            Specifies a VM Snapshot
    .EXAMPLE
            Get-Snapshot -VM (Get-VM "Master") -Name "BaseSnapshot" | Get-VMSnapshotPath

            /BaseSnapshot
    .EXAMPLE
            Get-Snapshot -VM (Get-VM "Master") -Name "SecondSnapshot" | Get-VMSnapshotPath

            /BaseSnapshot/SecondSnapshot
    .EXAMPLE
            (Get-VM "Master"), (Get-VM "MasterVDI") | Get-Snapshot | Get-VMSnapshotPath

            /BaseSnapshot
            /BaseSnapshot/SecondSnapshot
            /VDIBaseSnapshot
    .NOTES
            NAME:     Get-VMLogicalPath
            AUTHOR:   ROULEAU Benjamin
            LASTEDIT: 2015-02-05
    .LINKS
            http://katalykt.blogspot.fr/
#>
    [CmdletBinding()]
    PARAM(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [VMware.VimAutomation.ViCore.Impl.V1.VM.SnapshotImpl]$Snapshot
    )

    BEGIN {
        
    }

    PROCESS {
        $Snapshot | ForEach-Object {
            Write-Verbose -Message ("[PROCESS - Get-VMSnapshotPath] Retrieving the path of Snapshot: '{0}' on VM : '{1}'" -f $_.Name, $_.VM.Name)

            # We retrieve the Snapshot path up the the root of the VM
            $VMo = $_
            $Path = ""
            WHILE ($VMo) {
                $Path = "/" + $VMo.Name + $Path
                $VMo = $VMo.ParentSnapshot
            }

            $Path
        }
    }

    END {

    }
}