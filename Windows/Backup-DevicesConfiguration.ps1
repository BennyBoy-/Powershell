#Requires -Version 3.0

Function Export-BackupStatus {
<#
    .SYNOPSIS
            This function will export the output from Backup-DevicesConfiguration via Mail 
    .DESCRIPTION
            This function will export the output from Backup-DevicesConfiguration via Mail in an HTML report
    .PARAMETER  Jobs
            The backup status in an object-format, pipeline is supported
    .PARAMETER  SendMail
            Send a mail in any cases
    .PARAMETER  SendMailOnError
            Send a mail only if an error occurs
    .EXAMPLE
            $Backups = Backup-DevicesConfiguration
            Export-BackupStatus -Jobs $Backups -SendMail
    .EXAMPLE
            Backup-DevicesConfiguration | Export-BackupStatus -SendMail
    .EXAMPLE
            Backup-DevicesConfiguration | Export-BackupStatus -SendMailOnError
    .PROFILES
            [System.Object]$MAIL_System
            [System.String]$SMTP_Host
    .NOTES
            NAME:     Export-BackupStatus
            AUTHOR:   ROULEAU Benjamin
            LASTEDIT: 2015-08-21
#>
    [CmdletBinding()]
    PARAM(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        $Jobs,

        [Parameter(ParameterSetName="Normal")] 
        [switch]$SendMail,

        [Parameter(ParameterSetName="Advanced")] 
        [switch]$SendMailOnError
    )

    BEGIN {
        Write-Verbose -Message "[BEGIN Export-BackupStatus] Checking the backups..."

        # Init Variables
        $FlagError = $false
        $InitDate = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
        
        # Build up a job report if either switch are present
        If ($SendMail -or $SendMailOnError) {
            $DoReport = $true
        } Else {
            $DoReport = $false
        }

        # HTML Composer.
        $HTML_Content = ""
    }

    PROCESS {
        $Jobs | ForEach-Object {
            TRY {
                If ($_.BackedUp) {
                    Write-Verbose -Message ("[PROCESS Export-BackupStatus] Device [{0}] [{1}] has been successfully backed up" -f $_.Device, $_.Hostname)
                } Else {
                    Write-Warning -Message ("[PROCESS Export-BackupStatus] Device [{0}] [{1}] encountered an error during the backup: '{2}'" -f $_.Device, $_.Hostname, $_.Message)
                    $FlagError = $true
                }

                # Only collect the eta if we have to
                If ($DoReport) {
                    # We do a user-friendly boolean convertion
                    If ($_.BackedUp) {
                        $Status = "Success"
                        $Color = "#aeffa8"
                    } Else {
                        $Status = "Error"
                        $Color = "#ffa8a8"
                    }

                    $HTML_Content += ('
                        <tr>
                          <td width="100px" style="vertical-align: top; background-color: {4};">{0}</td>
                          <td width="100px" style="vertical-align: top; background-color: {4};">{1}</td>
                          <td width="100px" style="vertical-align: top; background-color: {4};">{2}</td>
                          <td width="500px" style="background-color: {4};">{3}</td>
                        </tr>
                    ' -f $_.Device, $_.Hostname, $Status, $_.Message, $Color)
                }
            } CATCH {
                Write-Warning -Message ("[PROCESS - Export-BackupStatus] Something went wrong: {0}" -f $Error[0].Exception.Message)
            }
        }
    }

    END {
        # Send a Mail if either the SendMail switch is present or if the SendMailOnError switch is present and an error is detected
        If (($SendMail -or ($SendMailOnError -and $FlagError)) -and $HTML_Content.Length -gt 0) {
	        $HTML_Body = @"
	        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
	        <html xmlns="http://www.w3.org/1999/xhtml">
	          <head>
		        <title>Devices Backup Report</title>
		        <style type="text/css">
		          body {
			        width: 800px;
                    font: 12px Arial, Helvetica, sans-serif; 
			        margin: 0 auto;
			        padding-top: 15px;
		          }
		  
		          #reporting {
			        border: 1px solid #3a3a3a;
			        border-collapse:collapse;
			        margin: 0 auto;
		          }
		  
		          #reporting th { background-color: #3a3a3a; color: #ffffff; }	 
		        </style>
	          </head>
	  
	          <body>
                <b>Script:</b> $(Split-Path $MyInvocation.ScriptName -Leaf)<br />
                <b>Host:</b> $([System.Environment]::MachineName)<br />
                <b>Report Date:</b> $InitDate<br /><br />

		        <table id="reporting">
		          <tr>
			        <th width="10px">Device</th>
			        <th width="10px">Hostname</th>
                    <th width="10px">Status</th>
                    <th width="500px">Message</th>
		          </tr>

                  $HTML_Content
                </table>
              </body>

              <br /><br />
            </html>
"@

            Write-Verbose -Message "[END Export-BackupStatus] Sending the report by mail"

            # Send the report via Mail
            Send-MailMessage `                -To $MAIL_System.ToSysAdm `
                -From $MAIL_System.From `
                -Subject "Devices Backup: $InitDate" `
                -Body $HTML_Body `
                -BodyAsHtml `
                -SmtpServer $SMTP_Host
        }

        Write-Verbose -Message "[END Export-BackupStatus] Done checking the backups!"
    }
}

Function Backup-DevicesConfiguration {
<#
    .SYNOPSIS
            This function will backup the supported devices present in the linked CSV file
    .DESCRIPTION
            This function will backup the supported devices present in the linked CSV file
    .PARAMETER  CSV
            The CSV file input, by default we look for Backup-DevicesConfiguration.csv in the script's folder
    .EXAMPLE
            Backup-DevicesConfiguration

            BackedUp  Message                                       Hostname              Device
            --------  -------                                       --------              ------
                True  The device was successfully backed up         10.1.1.5              Brocade
                True  The device was successfully backed up         10.1.1.6              Brocade
                True  The device was successfully backed up         10.1.2.5              Brocade
                True  The device was successfully backed up         10.1.2.6              Brocade
    .EXAMPLE
            Backup-DevicesConfiguration -CSV D:\temp\local_devices.csv

            BackedUp  Message                                       Hostname              Device
            --------  -------                                       --------              ------
                True  The device was successfully backed up         10.1.1.5              Brocade
                False Unable to connect to the device using SSH     10.1.1.6              Brocade
    .PROFILES
            [System.Object]$FTP_System
    .MODULES
            PSFTP
            Posh-SSH
    .NOTES
            NAME:     Backup-DevicesConfiguration
            AUTHOR:   ROULEAU Benjamin
            LASTEDIT: 2015-08-21
#>
    #Requires -Module PSFTP, Posh-SSH
    [CmdletBinding()]
    Param(
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        $CSV=(Join-Path -Path (Split-Path -parent $PSCommandPath) -ChildPath "Backup-DevicesConfiguration.csv")
    )

    BEGIN {
        Write-Verbose -Message "[BEGIN Backup-DevicesConfiguration] Attempting to import the Posh-SSH Module..."

        If (-not (Get-Module Posh-SSH -ErrorAction SilentlyContinue)) {
            Import-Module Posh-SSH -ErrorAction Stop
        }

        # FTP Tree Function
        Function New-FTPTree {
        <#
            .SYNOPSIS
                    This function will attempt to create an FTP tree from the given FTP Path
            .DESCRIPTION
                    This function will attempt to create an FTP tree from the given FTP Path, an FTP Connection must be active.
            .PARAMETER  Path
                    The FTP Path to create
            .PARAMETER  Server
                    The FTP Server
            .PARAMETER  Session
                    The FTP Session name to use
            .EXAMPLE
                    New-FTPTree -Path "backup/system/brocade/2015/08" -Server ftp0001.katalykt.lan -Session RemoteHost

                    True
            .PROFILES
                    [System.Object]$FTP_System
            .MODULES
                    PSFTP
            .NOTES
                    NAME:     New-FTPTree
                    AUTHOR:   ROULEAU Benjamin
                    LASTEDIT: 2015-08-21
        #>
            #Requires -Module PSFTP
            [CmdletBinding()]
	        PARAM(
		        [Parameter(Mandatory)]
		        [string]$Path,

		        [Parameter(Mandatory)]
		        [string]$Server,

		        [Parameter(Mandatory)]
		        [string]$Session
            )

            BEGIN {
                Write-Verbose -Message "[BEGIN - New-FTPTree] Attempting to create FPT Tree: $Path"
                $Tree = ("ftp://{0}/" -f $Server)
                $PathIsValid = $true
            }

            PROCESS {
                # Split the given Path
                $Path.Split("/") | ForEach-Object {
            
                    Try {
                        # List the current directory and check whether the given folder exists or not. The folder is created if it does not exist
                        If ((Get-FTPChildItem -Path $Tree -Session $Session -ErrorAction Stop -ErrorVariable "ErrListing").Name -contains $_) {
                            Write-Verbose -Message "[PROCESS - New-FTPTree] Found Folder '$_' in $Tree"
                        } Else {
                            Write-Verbose -Message "[PROCESS - New-FTPTree] Creating Folder '$_' in $Tree"
                            $Folder = New-FTPItem -Path $Tree -Name $_ -Session $Session -ErrorVariable "ErrCreating"

                            If (-not ($Folder -like "257*directory created*")) { 
                                $PathIsValid = $false 
                                Write-Warning -Message "[PROCESS - New-FTPTree] Unable to create the given folder!"
                            }
                        }
                    } Catch {
                        Write-Warning -Message "[PROCESS - New-FTPTree] Something went wrong!"
                        If ($ErrListing) { Write-Warning -Message "[PROCESS - New-FTPTree] Unable to list the given path!" }
                        If ($ErrCreating) { Write-Warning -Message "[PROCESS - New-FTPTree] Unable to create the given folder!" }
                        $PathIsValid = $false
                    }

                    $Tree += ("{0}/" -f $_)
                }
            }

            END {
                $PathIsValid
            }
        }

        # Init Variables
        $FTP_Session = "RemoteHost"

        $Message_Success = "The device was successfully backed up"

        Write-Verbose -Message "[BEGIN Backup-DevicesConfiguration] Starting the configuration retrieval..."
    }

    PROCESS {
        # Retrieve the Configuration from each of the given devices
        Import-Csv -Path $CSV -Delimiter ';' | ForEach-Object {
            $Username = $_.Username
            $Hostname = $_.Host
            $Password = $_.Password
            $Type = $_.Type

            $DateStart = Get-Date
            $DateLog = $DateStart.ToString("yyyyMMdd_HHmmss")
            $BackedUp = $false
            $InfoLog = ""

            Switch ($_.Type) {
                # Brocade Switches
                "Brocade" {
                    # Backups will be stored in this child
                    $FTP_Child = "BROCADE"

                    # Build up the Credentials
                    $Password = ConvertTo-SecureString $Password -AsPlainText -Force
                    $SSHCredentials =  New-Object System.Management.Automation.PSCredential ($Username, $Password)

                    $Password = ConvertTo-SecureString $FTP_System.Password -AsPlainText -Force
                    $FTPCredentials =  New-Object System.Management.Automation.PSCredential ($FTP_System.User, $Password)

                    # Get the effective Path
                    $FTP_Path_Effective = (Join-Path $FTP_System.Home -ChildPath ("{0}/{1}/{2}" -f $FTP_Child, $DateStart.ToString("yyyy"), $DateStart.ToString("MM"))) -replace '\\','/'

                    # Attempt to start an SSH Session
                    Try {
                        Write-Verbose -Message "[PROCESS Backup-DevicesConfiguration] Attempting to connect to the SSH host: $Hostname"
                        $SSHSession = New-SSHSession -ComputerName $Hostname -Credential $SSHCredentials -AcceptKey $true -ErrorAction Stop
                    } Catch {
                        Write-Warning -Message "[PROCESS Backup-DevicesConfiguration] Unable to start an SSH Session on the given host"
                        $SSHSession = $false
                        $InfoLog = "Unable to connect to the device using SSH"
                    }
                    
                    # Ensure that the SSH Session is alive and kicking
                    If ($SSHSession) {
                        # Retrieve the Device Name
                        $DeviceName = Invoke-SSHCommand -SSHSession $SSHSession -Command "switchshow | grep switchName"
                        $DeviceName = $DeviceName.Output -match "\:\s(.*[a-zA-Z0-9])"
                        $DeviceName = $matches[1]

                        Write-Verbose -Message "[PROCESS Backup-DevicesConfiguration] Retrieved given device name: '$DeviceName'"

                        # Connect to the FTP in order to create the "tree"
                        Try {
                            Write-Verbose -Message ("[PROCESS Backup-DevicesConfiguration] Attempting to connect to the FTP host: {0}" -f $FTP_System.Host)
                            $FTP_Connection = Set-FTPConnection -Server $FTP_System.Host -Credentials $FTPCredentials -Session $FTP_Session
                        } Catch {
                            Write-Warning -Message "[PROCESS Backup-DevicesConfiguration] Unable to start an FTP Session on the given host"
                            $FTP_Connection = $false
                            $InfoLog = ("Unable to connect to the given FTP Server: {0}" -f $FTP_System.Host)
                        }

                        # Ensure that we've managed to connect to our FTP
                        If ($FTP_Connection) {
                            If (New-FTPTree -Path $FTP_Path_Effective -Session $FTP_Session -Server $FTP_System.Host -Verbose) {
                                Write-Verbose -Message "[PROCESS Backup-DevicesConfiguration] FTP Tree structure is valid"
                                
                                # Export the Log to the FTP
                                $Export = Invoke-SSHCommand -SSHSession $SSHSession -Command ("configupload -all -p ftp {0},{1},{2}/{3}{4}.txt,{5}" -f $FTP_System.Host, $FTP_System.User, $FTP_Path_Effective, $DeviceName, $DateLog, $FTP_System.Password)

                                # Make sure that the output match the expected return
                                If ($Export.Output -like "*All selected config parameters are uploaded*") {
                                    Write-Verbose -Message "[PROCESS Backup-DevicesConfiguration] Device '$DeviceName' configuration has been backed up"
                                    $BackedUp = $true
                                    $InfoLog = $Message_Success
                                } Else {
                                    Write-Warning -Message "[PROCESS Backup-DevicesConfiguration] Failed to back up device '$DeviceName': $($Export.Output)"
                                    $InfoLog = "Failed to export the configuration files with SSH from the device"
                                }
                            } Else {
                                Write-Warning -Message "[PROCESS Backup-DevicesConfiguration] The FTP Tree structure is not valid"
                                $InfoLog = ("The given FTP tree is not valid on host: {0}" -f $FTP_System.Host)
                            }
                        }

                        # Remove the SSH Session
                        $SSHSession | Remove-SSHSession | Out-Null
                    }
                }

                default {
                    Write-Warning -Message "[PROCESS Backup-DevicesConfiguration] Device $Type is unsupported by this script"
                }
            }

            # We return the result of our execution
            New-Object -TypeName PSObject -Property @{
                Device = $Type
                Hostname = $Hostname
                BackedUp = $BackedUp
                Message = $InfoLog
            }
        }
    }

    END {
        Write-Verbose -Message "[END Backup-DevicesConfiguration] Ended the configuration retrieval..."
    }
}

Backup-DevicesConfiguration -Verbose | Export-BackupStatus -SendMailOnError -Verbose