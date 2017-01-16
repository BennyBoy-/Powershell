#requires -version 2

Function Remove-OldFiles {
<#
    .SYNOPSIS
            This function will remove the old files located within the given folder(s) recursively
    .DESCRIPTION
            This function will remove the files which are older than x days within the given folder(s) recursively without
            deleting the folder structure.
    .PARAMETER  Path
            The path to a given folder, pipeline input is supported
    .PARAMETER  Days
            Files older than this parameters will be removed, default is 25
    .EXAMPLE
            Remove-OldFiles -Path "d:\office"
    .EXAMPLE
            "d:\office", "d:\temp" | Remove-OldFiles
    .EXAMPLE
            Remove-OldFiles -Path "d:\office" -Days 5
    .EXAMPLE
            Remove-OldFiles -Path "d:\office" -WhatIf

            What if: Performing operation "Remove file" on Target "D:\office\test\db2ddl.txt".
            What if: Performing operation "Remove file" on Target "D:\office\test\gpo.sql".
            What if: Performing operation "Remove file" on Target "D:\office\test\log_vmware.log".
            What if: Performing operation "Remove file" on Target "D:\office\test\Windows6.1-KB2506143-x64.msu".
            What if: Performing operation "Remove file" on Target "D:\office\test\Windows6.1-KB2550978-x86.msu".
    .NOTES
            NAME:     Remove-OldFiles
            AUTHOR:   ROULEAU Benjamin
            LASTEDIT: 2014-07-05
#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    PARAM(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        $Path,

        [int]$Days=25
    )

    BEGIN {
        $Limit = (Get-Date).AddDays(-$Days)

        Write-Verbose -Message "[BEGIN - Remove-OldFiles] Attempting to remove files older than $Limit"
    }

    PROCESS {
        $Path | ForEach-Object {
            Write-Verbose -Message "[PROCESS - Remove-OldFiles] Scaning Folder $_"

            Try {
                Get-ChildItem -Path $_ -Recurse | Where-Object { (-not $_.PSIsContainer) -and ($_.CreationTime -lt $Limit) } | Remove-Item -Force
            } Catch {
                Write-Warning -Message ("[PROCESS - Remove-OldFiles] An error has occured: {0}" -f $Error[0].Exception.Message)
            }
        }
    }

    END {

    }
}