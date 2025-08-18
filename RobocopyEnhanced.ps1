# Enhanced Robocopy Script with Progress Tracking and Reporting
# Author: Assistant
# Purpose: Server-to-server file copy with visual progress and detailed reporting

param(
    [string]$Source,
    [string]$Destination,
    [string]$AdditionalSwitches = ""
)

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

# Get additional switches if not provided
if (-not $AdditionalSwitches) {
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
$logFile = "$env:TEMP\RobocopyLog_$timestamp.txt"
$defaultSwitches = "/XO /XN /COPYALL /R:2 /W:2 /E /B /V /TS /FP /BYTES /NP"
$allSwitches = "$defaultSwitches $AdditionalSwitches /LOG:`"$logFile`""

Write-Host
Write-ColorOutput "=== COPY CONFIGURATION ===" "Green"
Write-ColorOutput "Source:      $Source" "White"
Write-ColorOutput "Destination: $Destination" "White"
Write-ColorOutput "Switches:    $allSwitches" "White"
Write-ColorOutput "Log File:    $logFile" "White"

# Calculate source size for progress estimation
Write-Host
Write-ColorOutput "Calculating source size..." "Yellow"
$sourceSize = Get-FolderSize $Source
Write-ColorOutput "Source size: $sourceSize GB" "Green"

# Confirm before proceeding
Write-Host
$confirm = Read-Host "Proceed with copy? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-ColorOutput "Operation cancelled." "Yellow"
    exit
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
$lastProgressTime = Get-Date
$bytesProcessed = 0
$filesCopied = 0
$errors = 0
$avgSpeed = 0

Write-ColorOutput "Monitoring progress... (Press Ctrl+C to view current status)" "Cyan"

# Monitor the process
while (-not $process.HasExited) {
    Start-Sleep -Seconds 5
    
    # Try to read current progress from log file
    if (Test-Path $logFile) {
        try {
            $logContent = Get-Content $logFile -Tail 20 -ErrorAction SilentlyContinue
            
            # Parse for progress information
            foreach ($line in $logContent) {
                if ($line -match "(\d+)\s+(\S+)\s+(\S+)\s+(\d+\.\d+%)\s+(\S+)") {
                    $filesCopied++
                }
                if ($line -match "ERROR|RETRY") {
                    $errors++
                }
            }
            
            # Calculate elapsed time and estimated completion
            $elapsed = (Get-Date) - $startTime
            $elapsedStr = "{0:hh\:mm\:ss}" -f $elapsed
            
            # Display progress
            $currentTime = Get-Date -Format "HH:mm:ss"
            Write-Host "`r[$currentTime] Files: $filesCopied | Errors: $errors | Elapsed: $elapsedStr | Running..." -NoNewline -ForegroundColor Green
        }
        catch {
            # Continue silently if log parsing fails
        }
    }
}

$process.WaitForExit()
$endTime = Get-Date
$totalTime = $endTime - $startTime

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

if (Test-Path $logFile) {
    $logContent = Get-Content $logFile
    
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
Write-ColorOutput "Detailed log saved to: $logFile" "Cyan"
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

Write-Host
$openLog = Read-Host "Open detailed log file? (Y/N)"
if ($openLog -eq "Y" -or $openLog -eq "y") {
    Start-Process notepad.exe -ArgumentList $logFile
}