Function Set-SNMPProperties {
    #requires -version 3

<#
    .SYNOPSIS
            This function will install SNMP if needed and configure the Permitted Managers along with
            the desired communities in read-only via WSMan
    .DESCRIPTION
            This function will install SNMP if needed and configure the Permitted Managers along with
            the desired communities in read-only via WSMan
    .PARAMETER  Computer
            Specifies which computer(s) will be processed
    .PARAMETER  SNMPPermittedManager 
            Specifies which Managers are allowed
    .PARAMETER  SNMPCommunity
            Specifies which Communities are allowed
    .PARAMETER  SNMPClear
            Specifies whether the existing Managers/Communities should be cleared or not
    .EXAMPLE
            Set-SNMPProperties -Computer "lab-fs001.katalykt.lan" `
                -SNMPPermittedManager "lab-centreon001.katalykt.lan" `
                -SNMPCommunity "katalyktRO"

            PSComputerName           SNMPManagers                   SNMPCommunities 
            --------------           ------------                   --------------- 
            lab-fs001.katalykt.lan   lab-centreon001.katalykt.lan   katalyktRO
    .EXAMPLE
            Set-SNMPProperties -Computer "lab-fs001.katalykt.lan", "lab-fs002.katalykt.lan" `
                -SNMPPermittedManager "lab-centreon001.katalykt.lan", "lab-centreon002.katalykt.lan" `
                -SNMPCommunity "katalyktRO", "labRO"

            PSComputerName           SNMPManagers                                         SNMPCommunities 
            --------------           ------------                                         --------------- 
            lab-fs001.katalykt.lan   {lab-centreon001.katalykt.lan, lab-centreon002...}   {katalyktRO, labRO}
            lab-fs002.katalykt.lan   {lab-centreon001.katalykt.lan, lab-centreon002...}   {katalyktRO, labRO}
    .EXAMPLE
            # Assuming the CSV contains one column with the title "Computer"
            Import-Csv -Path D:\Scripts\PSv3\Set-SNMPProperties.csv | ForEach-Object {$_.Computer} | `
                Set-SNMPProperties -SNMPPermittedManager "lab-centreon001.katalykt.lan" `
                    -SNMPCommunity "katalyktRO" ` 
                    -SNMPClear

            PSComputerName           SNMPManagers                   SNMPCommunities 
            --------------           ------------                   --------------- 
            lab-fs001.katalykt.lan   lab-centreon001.katalykt.lan   katalyktRO
            lab-fs002.katalykt.lan   lab-centreon001.katalykt.lan   katalyktRO
            lab-fs003.katalykt.lan   lab-centreon001.katalykt.lan   katalyktRO
            lab-fs004.katalykt.lan   lab-centreon001.katalykt.lan   katalyktRO
    .NOTES
            NAME:     Set-SNMPProperties
            AUTHOR:   ROULEAU Benjamin
            LASTEDIT: 2016-11-17
    .LINKS
            http://katalykt.blogspot.fr/
#>
    [CmdletBinding()]
    PARAM(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        $Computer,
        
        $SNMPPermittedManager,

        $SNMPCommunity,

        [switch]$SNMPClear
    )

    BEGIN {

    }

    PROCESS {
        $Computer | ForEach-Object {
            Try {
                Write-Verbose -Message "[PROCESS - Set-SNMPProperties] Processing computer [$_]"

                If (Test-WSMan -ComputerName $_ -ErrorAction SilentlyContinue) {
                    Invoke-Command -ComputerName $_ -ErrorAction Stop -ErrorVariable ErrInvoke -ScriptBlock {
                        $VerbosePreference = $Using:VerbosePreference
                        
                        # Install the SNMP Service with the WMI provider if needed
                        If ((Get-WindowsFeature -Name "SNMP-Service").Installed -eq "True") {
                            Write-Verbose -Message "[PROCESS - Set-SNMPProperties] The SNMP-Service Windows Feature is already installed"
                        } Else {
                            Write-Verbose -Message "[PROCESS - Set-SNMPProperties] Installing the SNMP-Service Windows Feature"
                            
                            Get-WindowsFeature -Name "SNMP-Service" | Add-WindowsFeature -IncludeAllSubFeature -IncludeManagementTools
                        }

                        # Clear the existing managers/communities if specified
                        If ($SNMPClear) {
                            Write-Verbose -Message "[PROCESS - Set-SNMPProperties] Clearing up the existing Managers and Communities"

                            "PermittedManagers", "ValidCommunities" | ForEach-Object {
                                $Subkey = $_
                                (Get-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\$Subkey").GetValueNames() |  ForEach-Object {
                                    Write-Verbose -Message "[PROCESS - Set-SNMPProperties] Clearing up existing registry record: HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\$Subkey\$_"

                                    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\$Subkey" -Name $_
                                }
                            }
                        }

                        # Check if the given permitted managers are defined or not
                        Write-Verbose -Message "[PROCESS - Set-SNMPProperties] Checking up Permitted Managers..."

                        $LocalManagers = $using:SNMPPermittedManager
                        If ($LocalManagers) {
                            $PermittedManagers = Get-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers"
                            $Index = ($PermittedManagers.ValueCount)+1
    
                            $PermittedManagers.GetValueNames() | ForEach-Object {
                                # If this manager is located within the manager array, we remove it from it
                                $Item = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers" -Name $_).$_
                            
                                If ($Item -in $LocalManagers) {
                                    Write-Verbose -Message "[PROCESS - Set-SNMPProperties] Skipping Manager $Item since it's already present"
                                    $LocalManagers = $LocalManagers | Where-Object {$_ -ne $Item}
                                }
                            }

                            # Add the missing managers if needed
                            $LocalManagers | ForEach-Object {
                                Write-Verbose -Message "[PROCESS - Set-SNMPProperties] Adding Manager $_ in the Permitted list with Index $Index"

                                New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers" -Name $Index -Value $_
                                $Index++
                            }
                        }

                        # Check if the community exists, if not we add it
                        Write-Verbose -Message "[PROCESS - Set-SNMPProperties] Checking up the communities..."

                        $using:SNMPCommunity | ForEach-Object {
                            If (-not(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities" -Name $_ -ErrorAction SilentlyContinue)) {
                                Write-Verbose -Message "[PROCESS - Set-SNMPProperties] Adding Community $_"

                                New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities" -Name $_ -Value 4 -PropertyType DWORD
                            } Else {
                                Write-Verbose -Message "[PROCESS - Set-SNMPProperties] Skipping Community $_ since it's already present"
                            }
                        }

                        # Return the new SNMP settings for this host
                        New-Object -TypeName PSObject -Property @{
                            SNMPCommunities = (Get-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities").GetValueNames()
                            SNMPManagers = (Get-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers").GetValueNames() | ForEach-Object {(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers" -Name $_).$_}
                        }
                    }
                } Else {
                    Write-Warning -Message "[PROCESS - Set-SNMPProperties] Computer [$_] could not be contacted via WSMan"
                }
            } Catch {
                If ($ErrInvoke) { Write-Warning -Message ("[PROCESS - Set-SNMPProperties] Invoke-Command failed for computer [{0}] with error {1}" -f $Error[0].OriginInfo, $Error[0].Exception.Message) }
            }
        } | Select PSComputerName, SNMPManagers, SNMPCommunities
    }

    END {

    }
}
