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
.
