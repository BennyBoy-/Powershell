#Requires -Version 3.0

Function Export-VMGuestDiskCapacity {
<#
    .SYNOPSIS
            This function will export the output from Get-VMGuestDiskCapacity via Mail 
    .DESCRIPTION
            This function will export the output from Get-VMGuestDiskCapacity via Mail in an HTML report
    .PARAMETER  VM
            The VM status in an object-format, pipeline is supported
    .EXAMPLE
            $VM = Get-VMGuestDiskCapacity -vCenter vc001.katalykt.lan
            Export-VMGuestDiskCapacity -VM $VM
    .EXAMPLE
            Get-VMGuestDiskCapacity -vCenter vc001.katalykt.lan | Export-VMGuestDiskCapacity
    .EXAMPLE
            "vc001.katalykt.lan", "vc002.katalykt.lan" | Get-VMGuestDiskCapacity | Export-VMGuestDiskCapacity
    .PROFILES
            [System.Object]$MAIL_DOSIL
            [System.String]$SMTP_Host
    .NOTES
            NAME:     Export-VMGuestDiskCapacity
            AUTHOR:   ROULEAU Benjamin
            LASTEDIT: 2015-08-21
#>
    [CmdletBinding()]
    PARAM(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        $VM
    )

    BEGIN {
        Write-Verbose -Message "[BEGIN - Export-VMGuestDiskCapacity] Attempting to export the desired output"

        Function Get-ProgressColoration {
        <#
            .SYNOPSIS
                    This function will return a color according to an Hue/Saturation/Lightness Value
            .DESCRIPTION
                    This function will return a color according to an Hue/Saturation/Lightness Value
            .PARAMETER  HSLValue
                    The HSL Value on a scale from 0 to 1
            .PARAMETER  ConvertToRGB
                    Define whether the output should be returned in a RGB format or not
            .PARAMETER  Saturation
                    The Saturation Value on a scale from 0 to 1
            .PARAMETER  Lightness
                    The Lightness Value on a scale from 0 to 1
            .EXAMPLE
                    Get-ProgressColoration -HSLValue 0.5
                    
                    hsl(60.0,100%,50%)
            .EXAMPLE
                    Get-ProgressColoration -HSLValue 0.2 -Saturation 0.7 -Lightness 0.4
                    
                    hsl(96.0,70%,40%)
            .EXAMPLE
                    Get-ProgressColoration -HSLValue 0.5 -ConvertToRGB
                    
                    rgb(255,255,0)
            .NOTES
                    NAME:     Get-ProgressColoration
                    AUTHOR:   ROULEAU Benjamin
                    LASTEDIT: 2015-08-21
        #>
            [CmdletBinding()]
            PARAM(
                [Parameter(Mandatory)]
                [ValidateRange(0,1.00)]
                [Decimal]$HSLValue,
                
                [Switch]$ConvertToRGB,

                $Saturation = 1,

                $Lightness = 0.5
            )

            BEGIN {
                Write-Verbose -Message "[BEGIN - Get-ProgressColoration] Getting a desired color for value $Value"
            }

            PROCESS {
                # Return either the HSL or the RGB format
                If ($ConvertToRGB) {
                    $Hue = ((1-$HSLValue)*120).ToString() -replace ',', '.'
                    "rgb({0})" -f ((Convert-HSLToRGB -Hue ($Hue/360) -Saturation $Saturation -Lightness $Lightness) -join ',')
                } Else {
                    "hsl({0},{1}%,{2}%)" -f ((((1-$HSLValue)*120).ToString() -replace ',', '.'), [System.Math]::Round($Saturation * 100), [System.Math]::Round($Lightness * 100))
                }
            }

            END {
                
            }
        }

        Function Convert-HSLToRGB {
        <#
            .SYNOPSIS
                    This function will convert a Hue/Saturation/Lightness Value to a Red/Green/Blue format
            .DESCRIPTION
                    This function will convert a Hue/Saturation/Lightness Value to a Red/Green/Blue format
            .PARAMETER  Hue
                    The Hue Value on a scale from 0 to 1
            .PARAMETER  Saturation
                    The Saturation Value on a scale from 0 to 1
            .PARAMETER  Lightness
                    The Lightness Value on a scale from 0 to 1
            .EXAMPLE
                    Convert-HSLToRGB -Hue 0.166666666666667 -Saturation 1 -Lightness 0.5
                    
                    255, 255, 0
            .NOTES
                    NAME:     Convert-HSLToRGB
                    AUTHOR:   ROULEAU Benjamin
                    LASTEDIT: 2015-08-21
            .LINKS
                    https://en.wikipedia.org/wiki/HSL_color_space
                    http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c
        #>
            [CmdletBinding()]
            PARAM(
                [Parameter(Mandatory)]
                $Hue,

                [Parameter(Mandatory)]
                $Saturation,

                [Parameter(Mandatory)]
                $Lightness
            )

            BEGIN {
                Write-Verbose -Message "[BEGIN - Convert-HSLToRGB] Converting HSL: $Hue, $Saturation, $Lightness to RGB"
                
                Function Convert-HueToRGB {
                <#
                    .SYNOPSIS
                            This function will convert a Hue value to either a Red, Green or Blue value
                    .DESCRIPTION
                            This function will convert a Hue value to either a Red, Green or Blue value
                    .PARAMETER  p
                            The temporary 2 value
                    .PARAMETER  q
                            The temporary 1 value
                    .PARAMETER  t
                            The temporary color (R, G or B)
                    .EXAMPLE
                            Convert-HSLToRGB -Hue 0.166666666666667 -Saturation 1 -Lightness 0.5
                    
                            255, 255, 0
                    .NOTES
                            NAME:     Convert-HueToRGB
                            AUTHOR:   ROULEAU Benjamin
                            LASTEDIT: 2015-08-21
                    .LINKS
                            https://en.wikipedia.org/wiki/HSL_color_space
                            http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c
                            http://www.niwa.nu/2013/05/math-behind-colorspace-conversions-rgb-hsl/
                #>
                    [CmdletBinding()]
                    PARAM(
                        [Parameter(Mandatory)]
                        $p,

                        [Parameter(Mandatory)]
                        $q,

                        [Parameter(Mandatory)]
                        $t
                    )

                    BEGIN {

                    }

                    PROCESS {
                        If ($t -lt 0) { $t += 1 }
                        If ($t -gt 1) { $t -= 1 }
                        If ($t -lt 1/6) { return (($p + ($q - $p)) * 6 * $t) }
                        If ($t -lt 1/2) { return $q }
                        If ($t -lt 2/3) { return (($p + ($q - $p)) * (2/3 - $t) * 6) }
                        return $p
                    }

                    END {

                    }
                }
            }

            PROCESS {
                # If there's no saturation then it's a shade of grey.
                If ($Saturation -eq 0) {
                    $Red = $Green = $Blue = $Lightness
                } Else {
                    If ($Lightness -lt 0.5) {
                        $q = $Lightness * (1 + $Saturation)
                    } Else {
                        $q = $Lightness + $Saturation - ($Lightness *$Saturation)
                    }

                    $p = 2 * $Lightness -$q

                    $Red = Convert-HueToRGB -p $p -q $q -t ($Hue + 1/3)
                    $Green = Convert-HueToRGB -p $p -q $q -t ($Hue)
                    $Blue = Convert-HueToRGB -p $p -q $q -t ($Hue - 1/3)
                }

                # Round it up
                $Red = [System.Math]::Round($Red * 255)
                $Green = [System.Math]::Round($Green * 255)
                $Blue = [System.Math]::Round($Blue * 255)

                Write-Verbose -Message "[BEGIN - Convert-HSLToRGB] Returning RGB: $Red, $Green, $Blue"

                @($Red, $Green, $Blue)
            }

            END {
                
            }
        }

        $HTML_BorderThinColor = "#e5e5e5"
        $HTML_BorderThickColor = "#6690bc"
        $InitDate = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    }

    PROCESS {
        # Buld the output
        $HTML_BorderColor = $HTML_BorderThickColor
        If ($VM.Disks) {
            $HTML_Disks = ""

            $VM.Disks | Sort-Object DiskPath | ForEach-Object {
                # Parse properly
                If ($VM_.Disks.Count -gt 1) {
                    $TR_OpenTag = "<tr>"
                    $TR_CloseTag = "</tr>"
                } Else {
                    $TR_OpenTag = ""
                    $TR_CloseTag = ""
                }

                # Coloration scale
                $ScaleRatio = 1
                If ($_.PercentFull -lt 95) { $ScaleRatio = 1.3 }


                $HTML_Disks += '
                  {5}
                    <td style="border-right: 1px solid {8}; border-top: 1px solid {7}; padding-left: 4px;"><span id="pbcontainer">{0}</span></td>
                    <td width="80px" id="rowlight" style="border-top: 1px solid {7};">{1} GB</td>
                    <td width="80px" id="rowlight" style="border-top: 1px solid {7};">{2} GB</td>
                    <td width="50px" id="rowlight" style="border-top: 1px solid {7};">{3} %</td>
				    <td style="border-top: 1px solid {7};">
					    <div class="percentbar" style="width:100px; ">
					      <div style="background-color: {4};width:{3}px;"></div>
					    </div>
				    </td>
                  {6}
                  </tr>
                ' -f $_.DiskPath, $_.Capacity, $_.Freespace, $_.PercentFull, (Get-ProgressColoration -HSLValue (($_.PercentFull / 100) / $ScaleRatio) -ConvertToRGB), $TR_OpenTag, $TR_CloseTag, $HTML_BorderColor, $HTML_BorderThinColor
                
                # The next borders are lighter than the first one
                $HTML_BorderColor = $HTML_BorderThinColor
            }

            $HTML_Content += '
            <tr>
              <td width="300px" rowspan="{0}" id="rowhead">{1}</td>
              {2}
            
            ' -f $VM.Disks.Count, $VM.Name, $HTML_Disks, $HTML_BorderThickColor
        } Else {
            $HTML_Content += '
            <tr>
              <td width="300px" id="rowhead">{0}</td>
              <td colspan="5" id="rowoff">{1}</td>
            </tr>
            ' -f $VM.Name, $VM.Status, $HTML_BorderThickColor
        }
    }

    END {
        $HTML_Export = @"
	    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
	    <html xmlns="http://www.w3.org/1999/xhtml">
	      <head>
		    <title>VMware Disk Report</title>
		    <style type="text/css">
		      body {
			    width: 900px;
			    margin: 0 auto;
			    padding-top: 15px;
		      }
		  
		      #reporting {
			    border: 1px solid #6690BC;
			    border-collapse:collapse;
			    font: 12px Arial, Helvetica, sans-serif; 
			    margin: 0 auto;
		      }
		  
		      #reporting th { background-color: #6690BC; color: #ffffff; }

              #reporting tr { vertical-align: top; }	 

              #subheaders {
                font-weight: bold; 
                padding-left: 4px; 
                background-color: #A8C8E9;
              }

              #rowlight {
                border-right: 1px solid #e5e5e5; 
                padding-left: 4px;
              }

              #rowhead {
                background-color: #D3E6FA; 
                border-right: 1px solid #6690BC; 
                border-top: 1px solid #6690bc; 
                padding-left: 4px;
              }

              #rowoff {
                padding-left: 4px;
                border-top: 1px solid #6690bc;
                background-color: #CCCCCC;
              }

              #pbcontainer {
                display:block; 
                float:left; 
                overflow: hidden; 
                text-overflow:ellipsis; 
                max-width:80px; 
                width:80px;
              }
		  
		      .percentbar { background:#CCCCCC; border:1px solid #666666; height:10px; }
		      .percentbar div { background: #28B8C0; height: 10px; }
		    </style>
	      </head>
	  
	      <body>
		    <table id="reporting">
		      <tr>
			    <th>Virtual Machine</th>
			    <th colspan="5">Guest Disk Properties</th>
		      </tr>

			  <tr>
                <td width="300px" id="subheaders"></td>
			    <td width="60px" id="subheaders">Path</td>
			    <td width="80px" id="subheaders">Capacity</td>
			    <td width="80px" id="subheaders">Free Space</td>
			    <td width="150px" colspan="2" id="subheaders">Occupation</td>
			  </tr>

              $HTML_Content
		    </table>

            <br /><br />
          </body>
        </html>
"@

        #$HTML_Export | Out-File D:\office\vm.html

        # Send the report via Mail
        Send-MailMessage `            -To $MAIL_DOSIL.ToSysAdm `
            -From $MAIL_DOSIL.From `
            -Subject "vCenter Report: $InitDate" `
            -Body $HTML_Export `
            -BodyAsHtml `
            -SmtpServer $SMTP_Host
    }
}

Function Get-VMGuestDiskCapacity {
<#
    .SYNOPSIS
            This function will retrieve the Guest Disk capacity of all VMs present in a vCenter
    .DESCRIPTION
            This function will retrieve the Guest Disk capacity of all VMs present in a vCenter
    .PARAMETER  vCenter
            The vCenter server, pipeline is supported
    .PARAMETER  Credentials
            The credentials used to connect to the vCenter(s)
    .EXAMPLE
            Get-VMGuestDiskCapacity -vCenter vc001.katalykt.lan

            Status         VCServer              Name             Disks                                       
            ------         --------              ----             -----                                       
            Powered On     vc001.katalykt.lan    srv-iis001       {@{Capacity=10; PercentFull=92; DiskPath=...
            Powered On     vc001.katalykt.lan    srv-iis002       {@{Capacity=19,9; PercentFull=71; DiskPat...
    .EXAMPLE
            "vc001.katalykt.lan", "vc002.katalykt.lan" | Get-VMGuestDiskCapacity

            Status         VCServer              Name             Disks                                       
            ------         --------              ----             -----                                       
            Powered On     vc001.katalykt.lan    srv-iis001       {@{Capacity=10; PercentFull=92; DiskPath=...
            Powered On     vc001.katalykt.lan    srv-iis002       {@{Capacity=19,9; PercentFull=71; DiskPat...
            Powered On     vc002.katalykt.lan    srv-sql001       {@{Capacity=120; PercentFull=65; DiskPat...
    .SNAPIN
           VMware.VimAutomation.Core 
    .NOTES
            NAME:     Export-VMGuestDiskCapacity
            AUTHOR:   ROULEAU Benjamin
            LASTEDIT: 2015-08-21
#>
    [CmdletBinding()]
    PARAM(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
	    [String]$vCenter,

	    $Credentials
    )

    BEGIN {
        Try {
            # Attempt to load the VIM Snapin
            If ( (Get-PSSnapin -Name "VMware.VimAutomation.Core" -errorAction SilentlyContinue) -eq $null ) {
                Write-Verbose -Message "[BEGIN - Get-VMGuestDiskCapacity] Attempting to load the VMware.VimAutomation.Core Snapin"
	            Add-PsSnapin "VMware.VimAutomation.Core" -ErrorAction Stop -ErrorVariable ErrSnapin
            }
        } Catch {
            If ($ErrSnapin) { Write-Warning -Message ("[BEGIN - Get-VMGuestDiskCapacity] An error has occured during the PSSnapin import: {0}" -f $Error[0].Exception.Message) }
            exit
        }
    }

    PROCESS {
        Try {
            $vCenter | ForEach-Object {
                $vCenterHost = $_

                If ($Credentials) {
                    Write-Verbose -Message "[PROCESS - Get-VMGuestDiskCapacity] Attempting to connect to the vCenter host: $vCenterHost with the given credentials"
                    $VCServer = Connect-VIServer -Server $vCenterHost -Credential $Credentials -ErrorAction SilentlyContinue -ErrorVariable ErrVCConnect
                } Else {
                    Write-Verbose -Message "[PROCESS - Get-VMGuestDiskCapacity] Attempting to connect to the vCenter host: $vCenterHost with the current user"
                    $VCServer = Connect-VIServer -Server $vCenterHost -ErrorAction SilentlyContinue -ErrorVariable ErrVCConnect
                }

                # If we're connected to the vCenter, we retrieve the list of it's VMs
                If ($VCServer) {
                    Get-View -Server $VCServer -ViewType VirtualMachine | Where-Object {-not $_.Config.Template} | Sort-Object Name | ForEach-Object {
                        $VM = New-Object -TypeName PSObject -Property @{
                            Name = $_.Name
                            VCServer = $vCenterHost
                            Status = ""
                        }
            
                        Write-Verbose -Message ("[PROCESS - Get-VMGuestDiskCapacity] Processing Virtual Machine '{0}'" -f $VM.Name)

		                If ($_.Summary.Runtime.PowerState -eq "poweredOn") {
			                If ($_.Summary.Guest.ToolsRunningStatus -eq "guestToolsRunning") {
                                # The VM is online and it has VM Tools running. Retrieve the disks capacity
                                $VM.Status = "Powered On"

                                $VM | Add-Member -Name Disks -MemberType NoteProperty -Value ($_.Guest.Disk | ForEach-Object {
                                    New-Object -TypeName PSObject -Property @{
                                        DiskPath = $_.DiskPath
                                        Capacity = [math]::Round($_.Capacity/ 1GB, 2)
                                        FreeSpace = [math]::Round($_.FreeSpace / 1GB, 2)
                                        PercentFull = (100 - [math]::Round(([math]::Round($_.FreeSpace / 1GB, 2) * 100) / [math]::Round($_.Capacity/ 1GB, 2)))
                                    }
                                })
                    
                            } Else {
                                Write-Warning -Message ("[PROCESS - Get-VMGuestDiskCapacity] VM Tools on Virtual Machine '{0}' does not appear to be running" -f $VM.Name)
                                $VM.Status = "VM Tools missing"
                            }
                        } Else {
                            Write-Warning -Message ("[PROCESS - Get-VMGuestDiskCapacity] Virtual Machine '{0}' is not powered on" -f $VM.Name)
                            
                            $VM.Status = "Not Powered On"

                            # Just in case, it could managed by SRM?
                            If ($_.Config.ManagedBy.ExtensionKey -eq "com.vmware.vcDr") { $VM.Status = "Managed by Site Recovery Manager" }
                        }

                        $VM
                    }

                    Write-Verbose -Message "[PROCESS - Get-VMGuestDiskCapacity] Removing the vCenter connection from host $_"
                    Disconnect-VIServer $VCServer -Force -Confirm:$false | Out-Null
                } Else {
                    Write-Warning -Message "[PROCESS - Get-VMGuestDiskCapacity] vCenter connection is not established"
                }
            }
        } Catch {
            If ($ErrVCConnect) { Write-Warning -Message ("[PROCESS - Get-VMGuestDiskCapacity] Cannot connect to the given vCenter: {0}" -f $Error[0].Exception.Message) }
            Write-Warning $Error[0].Exception.Message
        }
    }

    END {
        
    }
}