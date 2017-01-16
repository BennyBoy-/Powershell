#requires -version 2

Function Set-BlastHTMLAccess {
<#
    .SYNOPSIS
            This function will enable or disable the VMware BLAST HTML5 Protocol from one or multiple VDI Pools
    .DESCRIPTION
            This function will enable or disable the VMware BLAST HTML5 Protocol from one or multiple VDI Pools
    .PARAMETER  $Pool
            The Pool in question in a string format, pipeline is supported
    .PARAMETER  $Enabled
            Enable the BLAST Protocol if present. BLAST is disabled without this parameter
    .EXAMPLE
            Set-BlastHTMLAccess -Pool "Pool_VDIW7" -Enabled
    .EXAMPLE
            Set-BlastHTMLAccess -Pool "Pool_VDIW10"
    .EXAMPLE
            "Pool_VDIW7", "Pool_VDIW10" | Set-BlastHTMLAccess -Enabled
    .NOTES
            NAME:     Set-BlastHTMLAccess
            AUTHOR:   ROULEAU Benjamin
            LASTEDIT: 2015-10-12

            Supported on VMware Horizon 5/6.x
    .LINKS
            http://katalykt.blogspot.fr/
#>
    [CmdletBinding()]
    PARAM(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [string]$Pool,

        [switch]$Enabled
    )

    BEGIN {
        Write-Verbose -Message "[BEGIN Set-BlastHTMLAccess] Editing BLAST HTML5 Access..."

        # Path to the VMware Horizon ADAM DB
        $ldap = [adsi]"LDAP://localhost:389/DC=vdi,DC=vmware,DC=int"
    }

    PROCESS {
        $Pool | ForEach-Object {
            Write-Verbose -Message "[PROCESS Set-BlastHTMLAccess] Attempting to edit BLAST HTML Access for Pool '$_'"

            $filter = "(&(objectCategory=pae-DesktopApplication)(cn=$_))"
            $ds = New-Object System.DirectoryServices.DirectorySearcher($ldap, $filter)

            $ds.FindAll() | ForEach-Object {
                # Retrieve the protocols present on the given VDI Pool
                $objPool = $_.GetDirectoryEntry()
                $objProtocols = @($objPool."pae-ServerProtocolLevel")
                $objDisplayName = $objPool."pae-DisplayName"

                Write-Verbose -Message "[PROCESS Set-BlastHTMLAccess] Found protocols '$objProtocols' for '$objDisplayName'"

                # Retrieve the non-BLAST Protocols
                [array]$newObjProtocols = ($objProtocols | Where-Object { $_ -ne "BLAST" }) -split "\s+"

                # Add BLAST to the protocols if enabled
                IF ($Enabled) {
                    Write-Verbose -Message "[PROCESS Set-BlastHTMLAccess] Enabling BLAST for '$objDisplayName'"

                    $newObjProtocols += "BLAST"
                }

                # Compare the Pool protocols and commit the changes if needed
                IF (Compare-Object -ReferenceObject $objProtocols -DifferenceObject $newObjProtocols) {
                    Write-Verbose -Message "[PROCESS Set-BlastHTMLAccess] Committing changes with new protocols '$newObjProtocols'"

                    $objPool."pae-ServerProtocolLevel" = $newObjProtocols
                    $objPool.CommitChanges()
                } ELSE {
                    Write-Verbose -Message "[PROCESS Set-BlastHTMLAccess] No changes were detected"
                }
            }
        }
    }

    END {
        Write-Verbose -Message "[END Set-BlastHTMLAccess] Done Editing BLAST HTML5 Access..."
    }
}