# Enhanced Robocopy Script

A PowerShell wrapper for Robocopy that provides real-time progress tracking, detailed reporting, and an improved user experience for server-to-server file migrations.

## Features

- **Interactive Setup**: Prompts for source/destination with path validation
- **Progress Monitoring**: Real-time file counts, error tracking, and elapsed time
- **Detailed Reporting**: Comprehensive statistics and error summaries
- **Permission Preservation**: Maintains all file security permissions and metadata
- **Resume Capability**: Smart handling of interrupted transfers
- **Professional Logging**: Timestamped logs with detailed operation history

## Default Configuration

The script uses these optimal switches by default:
- `/XO /XN` - Skip files that haven't changed (resume functionality)
- `/COPYALL` - Copy all file information including security permissions
- `/R:2 /W:2` - 2 retries with 2-second waits between attempts
- `/E` - Copy subdirectories, including empty ones
- `/B` - Use backup mode to bypass security restrictions
- `/V /TS /FP /BYTES` - Verbose logging with timestamps and full paths

## Usage

### Method 1: Interactive Mode
```powershell
.\RobocopyEnhanced.ps1
```
The script will prompt you for:
- Source path
- Destination path  
- Additional switches (optional)

### Method 2: Command Line Parameters
```powershell
.\RobocopyEnhanced.ps1 -Source "\\OLD-SERVER\d$" -Destination "D:\"
```

### Method 3: Mixed Mode
```powershell
.\RobocopyEnhanced.ps1 -Source "\\SERVER\share$"
# Will prompt for destination only
```

### Common Additional Switches
- `/MIR` - Mirror mode (copies and deletes to match source)
- `/L` - List only (dry run to preview changes)
- `/XC` - Exclude changed files
- `/XD folder` - Exclude specific directories
- `/MT:8` - Use 8 threads for faster copying

## Examples

### Basic Server Migration
```powershell
.\RobocopyEnhanced.ps1 -Source "\\OLD-SERVER\d$" -Destination "D:\" 
```

### Dry Run (Preview Only)
```powershell
.\RobocopyEnhanced.ps1 -Source "\\SERVER\data$" -Destination "C:\NewData" -AdditionalSwitches "/L"
```

### Mirror with Multi-Threading
```powershell
.\RobocopyEnhanced.ps1 -Source "\\SOURCE\share$" -Destination "D:\Data" -AdditionalSwitches "/MIR /MT:8"
```

## Output

### Real-Time Progress
```
[14:30:25] Files: 1,247 | Errors: 0 | Elapsed: 00:15:30 | Running...
```

### Final Report
```
=== FINAL REPORT ===
Start Time:     2025-08-18 14:15:00
End Time:       2025-08-18 15:42:30
Total Time:     01:27:30
Total Files:    15,847
Copied Files:   2,156
Skipped Files:  13,691
Total Data:     47.3 GB
Average Speed:  9.2 MB/sec
```

## Requirements

- **Windows PowerShell 5.1 or later**
- **Administrator privileges** (required for copying security permissions)
- **Network access** to source and destination paths
- **Sufficient disc space** at destination

## Installation

### Method 1: Direct Download from GitHub (Recommended)
1. **Download the script:**
   - Click the green "Code" button above
   - Select "Download ZIP" 
   - Extract the ZIP file to your preferred location (e.g., `C:\Scripts\`)
   
   OR
   
   - Click on `RobocopyEnhanced.ps1` in the file list
   - Click the "Raw" button
   - Right-click and "Save As" to download the file directly

2. **Prepare PowerShell:**
   - Right-click on PowerShell and select "Run as Administrator"
   - Navigate to where you saved the script: `cd C:\Scripts\`

3. **Set execution policy (if needed):**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

4. **Run the script:**
   ```powershell
   .\RobocopyEnhanced.ps1
   ```

### Method 2: Using Git Clone (Requires Git Installation)
