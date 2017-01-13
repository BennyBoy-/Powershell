#requires -version 3

Function Get-BigFiles {
<#
    .SYNOPSIS
            This function will scan a folder in order to retrieve the files which exceed a given 
            size threshold
    .DESCRIPTION
            This function will scan a folder in order to retrieve the files which exceed a given 
            size threshold
    .PARAMETER  Path
            Specifies the folder to scan recursively
    .PARAMETER  MinSize
            Specifies the minimal threshold
    .EXAMPLE
            Get-BigFiles -Path "D:\temp\vsphere6.1"

            FullName                      Date Created             Date Modified            Size (MB)
            --------                      ------------             -------------            ---------
            D:\temp\vsphere6.1\VMware-... 20/05/2015 12:07:33      20/05/2015 11:50:35         2613,7
            D:\temp\vsphere6.1\vRealiz... 16/06/2015 11:04:43      11/06/2015 11:52:31        1503,97
            D:\temp\vsphere6.1\VMware-... 29/06/2015 13:41:37      29/06/2015 13:39:12          868,5
            D:\temp\vsphere6.1\VMware-... 29/06/2015 14:04:48      29/06/2015 14:03:34         867,63
            D:\temp\vsphere6.1\vRealiz... 16/06/2015 11:03:56      15/06/2015 12:10:53         404,82
            D:\temp\vsphere6.1\VMware-... 20/05/2015 12:08:54      20/05/2015 11:56:10         348,38
            D:\temp\vsphere6.1\VMware-... 20/05/2015 12:09:31      20/05/2015 10:06:22         171,72
            D:\temp\vsphere6.1\VMware-... 20/05/2015 12:09:16      20/05/2015 10:05:25         119,95
            D:\temp\vsphere6.1\VMware-... 17/06/2015 09:35:40      11/06/2015 11:23:47          35,82
            D:\temp\vsphere6.1\VMware-... 20/05/2015 12:09:20      20/05/2015 10:03:19          31,33
    .EXAMPLE
            Get-BigFiles -Path "D:\temp\vsphere6.1" -MinSize 1Gb

            FullName                      Date Created             Date Modified            Size (MB)
            --------                      ------------             -------------            ---------
            D:\temp\vsphere6.1\VMware-... 20/05/2015 12:07:33      20/05/2015 11:50:35         2613,7
            D:\temp\vsphere6.1\vRealiz... 16/06/2015 11:04:43      11/06/2015 11:52:31        1503,97

    .EXAMPLE
            "D:\temp\vsphere6.1" | Get-BigFiles -MinSize 750Mb

            FullName                      Date Created             Date Modified            Size (MB)
            --------                      ------------             -------------            ---------
            D:\temp\vsphere6.1\VMware-... 20/05/2015 12:07:33      20/05/2015 11:50:35         2613,7
            D:\temp\vsphere6.1\vRealiz... 16/06/2015 11:04:43      11/06/2015 11:52:31        1503,97
            D:\temp\vsphere6.1\VMware-... 29/06/2015 13:41:37      29/06/2015 13:39:12          868,5
            D:\temp\vsphere6.1\VMware-... 29/06/2015 14:04:48      29/06/2015 14:03:34         867,63
    .NOTES
            NAME:     Get-BigFiles
            AUTHOR:   ROULEAU Benjamin
            LASTEDIT: 2015-07-07
    .LINKS
            http://katalykt.blogspot.fr/
#>

    [CmdletBinding()]
    PARAM(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        $Path,
        
        [ValidateScript({$_.GetType().Name -eq "Int32"})]
        $MinSize=25Mb
    )

    BEGIN {
        Write-Verbose -Message "[BEGIN] Scan began at: $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))"
    }

    PROCESS {
        Write-Verbose -Message "[PROCESS] Scanning folder: $Path"

        # Get the content of the given folder and fetch files which are higher than the given size threshold
        Get-ChildItem -Path $Path -Recurse -ErrorAction "SilentlyContinue" |
            Where-Object {$_.Length -ge $MinSize} |            Select-Object FullName, `                @{Name="Date Created";Expression={$_.CreationTime.ToString()}}, `
                @{Name="Date Modified";Expression={$_.LastWriteTime.ToString()}}, `
                @{Name="Size (MB)";Expression={[math]::Round($_.Length / 1Mb, 2)}} |
            Sort-Object "Size (MB)" -Descending
    }

    END {
        Write-Verbose -Message "[END] Scan ended at: $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))"
    }
}