#requires -version 2

Function Get-VMLogicalPath {
<#
    .SYNOPSIS
            This function will return a VM's logical path within vCenter
    .DESCRIPTION
            This function will return a VM's logical path within vCenter with or without the VM's name
    .PARAMETER  VM
            Specifies a vCenter VM
    .EXAMPLE
            Get-VMLogicalPath -VM (Get-VM -Name "Master")

            Name                 VMPath                                        ParentPath                                           
            ----                 ------                                        ----------                                           
            Master               /KatalyktDC/vm/PoolFolder/Master              /KatalyktDC/vm/PoolFolder  
    .EXAMPLE
            $VMArray | Get-VMLogicalPath

            Name                 VMPath                                        ParentPath                                           
            ----                 ------                                        ----------                                           
            Master               /KatalyktDC/vm/PoolFolder/Master              /KatalyktDC/vm/PoolFolder  
            MasterTraining       /KatalyktDC/vm/PoolFolder/MasterTraining      /KatalyktDC/vm/PoolFolder  
    .NOTES
            NAME:     Get-VMLogicalPath
            AUTHOR:   ROULEAU Benjamin
            LASTEDIT: 2014-02-05
    .LINKS
            http://katalykt.blogspot.fr/
#>
    [CmdletBinding()]
    PARAM(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]$VM
    )

    BEGIN {
        
    }

    PROCESS {
        $VM | ForEach-Object {
            TRY {
                Write-Verbose -Message ("[PROCESS - Get-VMLogicalPath] Retrieving path for VM {0}" -f $_.Name)

                # We keep retrieving the parent's folder up to the Datacenter root
                $VMo = $_.Folder
                $Path = ""
                WHILE ($VMo) {
                    $Path = "/" + $VMo.Name + $Path
                    $VMo = $VMo.Parent
                }

                # Compose the VM Path
                $VMPath = $Path + "/" + $_.Name
                
                Write-Verbose -Message ("[PROCESS - Get-VMLogicalPath] Retrieved path {0} for VM {1}" -f $VMPath, $_.Name)

                # Return the desired properties in an object
                New-Object -TypeName PSObject -Property @{
                    Name = $_.Name
                    ParentPath = $Path
                    VMPath = $VMPath
                }
                
            } CATCH {
                Write-Warning -Message ("[PROCESS - Get-VMLogicalPath] Something went wrong: {0}" -f $Error[0].Exception.Message)
            }
        }
    }

    END {

    }
}