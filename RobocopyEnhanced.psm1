# Enhanced Robocopy Script with Progress Tracking and Reporting
# Author: Assistant
# Purpose: Server-to-server file copy with visual progress and detailed reporting

<#
.SYNOPSIS
    Enhanced Robocopy wrapper with progress tracking and detailed reporting.

.DESCRIPTION
    A PowerShell module that wraps Robocopy with real-time progress monitoring,
    detailed reporting, and an improved user experience for server-to-server
    file migrations. Provides visual feedback, error tracking, and comprehensive
    statistics.

.PARAMETER Source
    Source path for the copy operation (e.g., \\OLD-SERVER\d$ or C:\Data).
    If not provided, the function will prompt interactively.

.PARAMETER Destination
    Destination path for the copy operation (e.g., D:\ or \\NEW-SERVER\d$).
    If not provided, the function will prompt interactively.

.PARAMETER AdditionalSwitches
    Additional Robocopy switches to use beyond the defaults.
    Default switches: /XO /XN /COPYALL /R:2 /W:2 /E /B /V /TS /FP /BYTES /NP
    Common additions: /MIR (mirror), /L (list only), /MT:8 (multi-threaded)

.PARAMETER LogPath
    Custom path for the log file. If not specified, logs are saved to
    %TEMP%\RobocopyLog_YYYYMMDD_HHMMSS.txt

.PARAMETER Quiet
    Suppress interactive prompts and confirmations. Useful for automation.

.EXAMPLE
    Invoke-RobocopyEnhanced -Source "\\OLD-SERVER\d$" -Destination "D:\"
    
    Copies files from OLD-SERVER to local D: drive with default settings.

.EXAMPLE
    Invoke-RobocopyEnhanced -Source "C:\Data" -Destination "\\SERVER\backup$" -AdditionalSwitches "/MIR /L"
    
    Performs a dry-run (/L) mirror operation to preview changes.

.EXAMPLE
    Invoke-RobocopyEnhanced
    
    Runs in interactive mode, prompting for source and destination.

.NOTES
    Requires Windows PowerShell 5.1 or later and Administrator privileges
    for proper permission copying.
#>
function Invoke-RobocopyEnhanced {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if ([string]::IsNullOrWhiteSpace($_)) { return $true }
            if (-not (Test-Path $_)) {
                throw "Source path '$_' does not exist or is not accessible."
            }
            return $true
        })]
        [string]$Source,
        
        [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)]
        [string]$Destination,
        
        [Parameter(Position=2)]
        [string]$AdditionalSwitches = "",
        
        [Parameter()]
        [string]$LogPath,
        
        [Parameter()]
        [switch]$Quiet
    )
    
    begin {
        # Function to display colored output
        function Write-ColorOutput([string]$Text, [string]$Color = "White") {
            Write-Host $Text -ForegroundColor $Color
        }
        
        # Function to get folder size (for progress calculation)
        function Get-FolderSize([string]$Path) {
            try {
                $size = (Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                return [math]::Round($size / 1GB, 2)
            }
            catch {
                Write-Warning "Failed to calculate folder size: $_"
                return 0
            }
        }
        
        # Function to format bytes
        function Format-Bytes([long]$Bytes) {
            if ($Bytes -ge 1TB) { return "{0:N2} TB" -f ($Bytes / 1TB) }
            elseif ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
            elseif ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
            elseif ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
            else { return "$Bytes bytes" }
        }
    }
    
    process {
        try {
            Clear-Host
            Write-ColorOutput "====================================" "Cyan"
            Write-ColorOutput "   Enhanced Robocopy Server Tool   " "Cyan"
            Write-ColorOutput "====================================" "Cyan"
            Write-Host
            Write-ColorOutput "Script produced by Lee Robinson for development and testing purposes." "Yellow"
            Write-ColorOutput "We in no way accept responsibility for use of this product and" "Yellow"
            Write-ColorOutput "not understanding the switches properly." "Yellow"
            Write-Host
            Write-ColorOutput "Use at your own risk - Always test with /L switch first!" "Red"
            Write-Host
            
            # Get source if not provided
            if (-not $Source) {
                do {
                    $Source = Read-Host "Enter source path (e.g., \\OLD-SERVER\d$ or C:\Data)"
                    if (-not (Test-Path $Source)) {
                        Write-ColorOutput "ERROR: Source path does not exist or is not accessible!" "Red"
                        $Source = ""
                    }
                } while (-not $Source)
            }
            
            # Get destination if not provided
            if (-not $Destination) {
                do {
                    $Destination = Read-Host "Enter destination path (e.g., D:\ or \\NEW-SERVER\d$)"
                    $parentPath = Split-Path $Destination -Parent
                    if ($parentPath -and -not (Test-Path $parentPath)) {
                        Write-ColorOutput "ERROR: Destination parent path does not exist!" "Red"
                        $Destination = ""
                    }
                } while (-not $Destination)
            }
            
            # Get additional switches if not provided and not in quiet mode
            if (-not $AdditionalSwitches -and -not $Quiet) {
                Write-ColorOutput "`nDefault switches: /XO /XN /COPYALL /R:2 /W:2 /E /B" "Yellow"
                Write-Host "Common additional switches:"
                Write-Host "  /MIR  - Mirror mode (copies and deletes to match source)"
                Write-Host "  /L    - List only (dry run)"
                Write-Host "  /XC   - Exclude changed files"
                Write-Host "  /XD folder - Exclude specific directories"
                Write-Host
                $AdditionalSwitches = Read-Host "Enter any additional switches (or press Enter for defaults)"
            }
            
            # Build robocopy command
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            if (-not $LogPath) {
                $LogPath = "$env:TEMP\RobocopyLog_$timestamp.txt"
            }
            $defaultSwitches = "/XO /XN /COPYALL /R:2 /W:2 /E /B /V /TS /FP /BYTES /NP"
            $allSwitches = "$defaultSwitches $AdditionalSwitches /LOG:`"$LogPath`""
            
            Write-Host
            Write-ColorOutput "=== COPY CONFIGURATION ===" "Green"
            Write-ColorOutput "Source:      $Source" "White"
            Write-ColorOutput "Destination: $Destination" "White"
            Write-ColorOutput "Switches:    $allSwitches" "White"
            Write-ColorOutput "Log File:    $LogPath" "White"
            
            # Calculate source size for progress estimation
            Write-Host
            Write-ColorOutput "Calculating source size..." "Yellow"
            $sourceSize = Get-FolderSize $Source
            Write-ColorOutput "Source size: $sourceSize GB" "Green"
            
            # Confirm before proceeding (unless Quiet mode)
            if (-not $Quiet) {
                Write-Host
                $confirm = Read-Host "Proceed with copy? (Y/N)"
                if ($confirm -ne "Y" -and $confirm -ne "y") {
                    Write-ColorOutput "Operation cancelled." "Yellow"
                    return
                }
            }
            
            # Start robocopy process
            Write-Host
            Write-ColorOutput "=== STARTING COPY OPERATION ===" "Green"
            $startTime = Get-Date
            
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = "robocopy.exe"
            $processInfo.Arguments = "`"$Source`" `"$Destination`" $allSwitches"
            $processInfo.RedirectStandardOutput = $true
            $processInfo.RedirectStandardError = $true
            $processInfo.UseShellExecute = $false
            $processInfo.CreateNoWindow = $true
            
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $processInfo
            $process.Start() | Out-Null
            
            # Progress tracking variables
            $filesCopied = 0
            $directoriesProcessed = 0
            $errors = 0
            $currentFile = ""
            $totalBytes = 0
            $copiedBytes = 0
            $spinnerChars = @('|', '/', '-', '\')
            $spinnerIndex = 0
            
            Write-ColorOutput "Monitoring progress... (Robocopy is running in background)" "Cyan"
            Write-Host
            
            # Monitor the process with better progress display
            while (-not $process.HasExited) {
                Start-Sleep -Seconds 2
                
                # Try to read current progress from log file
                if (Test-Path $LogPath) {
                    try {
                        $logContent = Get-Content $LogPath -ErrorAction SilentlyContinue
                        $recentLines = $logContent | Select-Object -Last 30
                        
                        # Reset counters for this iteration
                        $tempFilesCopied = 0
                        $tempErrors = 0
                        $latestFile = ""
                        
                        # Parse log content for progress
                        foreach ($line in $logContent) {
                            # Count copied files (lines with timestamps and 100% or "New File")
                            if ($line -match "^\s*\d+\s+\S+\s+\S+\s+(100\.0%|New File)" -or $line -match "^\s*New File\s+") {
                                $tempFilesCopied++
                            }
                            
                            # Count errors
                            if ($line -match "ERROR|RETRY|FAILED") {
                                $tempErrors++
                            }
                            
                            # Parse bytes information
                            if ($line -match "Bytes\s*:\s*(\d+)\s+(\d+)") {
                                $totalBytes = [long]$matches[1]
                                $copiedBytes = [long]$matches[2]
                            }
                        }
                        
                        # Get the most recent file being processed
                        foreach ($line in $recentLines) {
                            if ($line -match "^\s*\d+.*\\([^\\]+)$" -or $line -match "New File.*\\([^\\]+)$") {
                                $latestFile = $matches[1]
                            }
                            if ($line -match "New Dir.*\\([^\\]+)\\?$") {
                                $directoriesProcessed++
                            }
                        }
                        
                        $filesCopied = $tempFilesCopied
                        $errors = $tempErrors
                        if ($latestFile) { $currentFile = $latestFile }
                        
                        # Calculate progress percentage
                        $progressPercent = 0
                        if ($sourceSize -gt 0 -and $copiedBytes -gt 0) {
                            $progressPercent = [math]::Round(($copiedBytes / ($sourceSize * 1GB)) * 100, 1)
                        }
                        
                        # Calculate elapsed time and speed
                        $elapsed = (Get-Date) - $startTime
                        $elapsedStr = "{0:hh\:mm\:ss}" -f $elapsed
                        $speed = if ($elapsed.TotalSeconds -gt 0 -and $copiedBytes -gt 0) { 
                            Format-Bytes ($copiedBytes / $elapsed.TotalSeconds) 
                        } else { 
                            "Calculating..." 
                        }
                        
                        # Spinning indicator
                        $spinner = $spinnerChars[$spinnerIndex % 4]
                        $spinnerIndex++
                        
                        # Current time
                        $currentTime = Get-Date -Format "HH:mm:ss"
                        
                        # Clear previous lines and display new progress
                        Write-Host "`r" -NoNewline
                        $statusLine1 = "[$currentTime] $spinner Copying: $currentFile"
                        $statusLine2 = "Files: $filesCopied | Dirs: $directoriesProcessed | Errors: $errors | Elapsed: $elapsedStr"
                        $statusLine3 = "Data: $(Format-Bytes $copiedBytes) / $(Format-Bytes ($sourceSize * 1GB)) ($progressPercent%) | Speed: $speed/sec"
                        
                        # Truncate long filenames
                        if ($statusLine1.Length -gt 100) {
                            $statusLine1 = $statusLine1.Substring(0, 97) + "..."
                        }
                        
                        Write-Host $statusLine1 -ForegroundColor Green
                        Write-Host $statusLine2 -ForegroundColor Yellow  
                        Write-Host $statusLine3 -ForegroundColor Cyan
                        Write-Host "`e[3A" -NoNewline  # Move cursor up 3 lines for next update
                        
                    }
                    catch {
                        # Show basic spinner if log parsing fails
                        $spinner = $spinnerChars[$spinnerIndex % 4]
                        $spinnerIndex++
                        $currentTime = Get-Date -Format "HH:mm:ss"
                        $elapsed = (Get-Date) - $startTime
                        $elapsedStr = "{0:hh\:mm\:ss}" -f $elapsed
                        Write-Host "`r[$currentTime] $spinner Robocopy running... | Elapsed: $elapsedStr | Analysing files..." -NoNewline -ForegroundColor Green
                    }
                } else {
                    # Show spinner while waiting for log file
                    $spinner = $spinnerChars[$spinnerIndex % 4]
                    $spinnerIndex++
                    $currentTime = Get-Date -Format "HH:mm:ss"
                    Write-Host "`r[$currentTime] $spinner Starting robocopy... Please wait..." -NoNewline -ForegroundColor Yellow
                }
            }
            
            $process.WaitForExit()
            $endTime = Get-Date
            $totalTime = $endTime - $startTime
            
            # Clear the progress display
            Write-Host "`n`n`n"
            
            # Final results
            Write-Host "`n"
            Write-ColorOutput "=== COPY OPERATION COMPLETED ===" "Green"
            
            # Parse final log for detailed results
            $finalResults = @{
                TotalFiles = 0
                CopiedFiles = 0
                SkippedFiles = 0
                ErrorFiles = 0
                TotalBytes = 0
                Speed = 0
                Errors = @()
            }
            
            if (Test-Path $LogPath) {
                $logContent = Get-Content $LogPath
                
                foreach ($line in $logContent) {
                    # Parse summary line
                    if ($line -match "Files\s*:\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)") {
                        $finalResults.TotalFiles = [int]$matches[1]
                        $finalResults.CopiedFiles = [int]$matches[2]
                        $finalResults.SkippedFiles = [int]$matches[3]
                        $finalResults.ErrorFiles = [int]$matches[5]
                    }
                    
                    # Parse bytes line
                    if ($line -match "Bytes\s*:\s*(\d+)") {
                        $finalResults.TotalBytes = [long]$matches[1]
                    }
                    
                    # Parse speed
                    if ($line -match "Speed\s*:\s*([\d\.]+)\s*Bytes/sec") {
                        $finalResults.Speed = [double]$matches[1]
                    }
                    
                    # Collect errors
                    if ($line -match "ERROR|RETRY") {
                        $finalResults.Errors += $line
                    }
                }
            }
            
            # Display final report
            Write-ColorOutput "=== FINAL REPORT ===" "Cyan"
            Write-Host "Start Time:     $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))"
            Write-Host "End Time:       $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))"
            Write-Host "Total Time:     $("{0:hh\:mm\:ss}" -f $totalTime)"
            Write-Host "Total Files:    $($finalResults.TotalFiles)"
            Write-ColorOutput "Copied Files:   $($finalResults.CopiedFiles)" "Green"
            Write-ColorOutput "Skipped Files:  $($finalResults.SkippedFiles)" "Yellow"
            if ($finalResults.ErrorFiles -gt 0) {
                Write-ColorOutput "Error Files:    $($finalResults.ErrorFiles)" "Red"
            }
            Write-Host "Total Data:     $(Format-Bytes $finalResults.TotalBytes)"
            if ($finalResults.Speed -gt 0) {
                Write-Host "Average Speed:  $(Format-Bytes $finalResults.Speed)/sec"
            }
            
            # Show errors if any
            if ($finalResults.Errors.Count -gt 0) {
                Write-ColorOutput "`n=== ERRORS ENCOUNTERED ===" "Red"
                foreach ($error in $finalResults.Errors | Select-Object -First 10) {
                    Write-ColorOutput $error "Red"
                }
                if ($finalResults.Errors.Count -gt 10) {
                    Write-ColorOutput "... and $($finalResults.Errors.Count - 10) more errors (check log file)" "Red"
                }
            }
            
            Write-Host
            Write-ColorOutput "Detailed log saved to: $LogPath" "Cyan"
            Write-Host "Robocopy exit code: $($process.ExitCode)"
            
            # Explain exit codes
            switch ($process.ExitCode) {
                0 { Write-ColorOutput "✓ No files were copied (no changes needed)" "Green" }
                1 { Write-ColorOutput "✓ Files were copied successfully" "Green" }
                2 { Write-ColorOutput "✓ Extra files or directories were detected" "Yellow" }
                3 { Write-ColorOutput "✓ Files were copied and extra files were detected" "Green" }
                4 { Write-ColorOutput "⚠ Some mismatched files were detected" "Yellow" }
                8 { Write-ColorOutput "✗ Some files or directories could not be copied" "Red" }
                16 { Write-ColorOutput "✗ Serious error - robocopy did not copy any files" "Red" }
                default { Write-ColorOutput "Exit code $($process.ExitCode) - Check robocopy documentation" "Yellow" }
            }
            
            # Open log file prompt (unless Quiet mode)
            if (-not $Quiet) {
                Write-Host
                $openLog = Read-Host "Open detailed log file? (Y/N)"
                if ($openLog -eq "Y" -or $openLog -eq "y") {
                    Start-Process notepad.exe -ArgumentList $LogPath
                }
            }
            
            # Return result object for programmatic use
            return [PSCustomObject]@{
                ExitCode = $process.ExitCode
                StartTime = $startTime
                EndTime = $endTime
                Duration = $totalTime
                TotalFiles = $finalResults.TotalFiles
                CopiedFiles = $finalResults.CopiedFiles
                SkippedFiles = $finalResults.SkippedFiles
                ErrorFiles = $finalResults.ErrorFiles
                TotalBytes = $finalResults.TotalBytes
                AverageSpeed = $finalResults.Speed
                LogPath = $LogPath
                Source = $Source
                Destination = $Destination
            }
        }
        catch {
            Write-Error "An error occurred during the Robocopy operation: $_"
            throw
        }
    }
}

# Export the main function
Export-ModuleMember -Function Invoke-RobocopyEnhanced
