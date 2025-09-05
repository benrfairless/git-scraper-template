# Git Scraper Template

Git scraper template is a bash-based web scraping system that uses GitHub Actions for scheduled data collection. The template provides two main bash scripts for downloading content from websites: a simple downloader and a recursive web crawler.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Bootstrap and Dependencies
- All required dependencies are pre-installed in Ubuntu environments: `curl`, `jq`, `wget`, `file`, `mktemp`
- No build process required - scripts are executable bash files
- Ensure scripts are executable: `chmod +x download.sh recursive_download.sh`

### Core Functionality Testing
- Validate shell syntax: `bash -n download.sh && bash -n recursive_download.sh` -- takes <1 second. NEVER CANCEL.
- Run linting: `shellcheck download.sh recursive_download.sh` -- takes 1 second. NEVER CANCEL. May show minor warnings but scripts are functional.
- Test script usage help: `./download.sh` and `./recursive_download.sh` -- shows usage information immediately

### Network Limitations
- **CRITICAL**: External network access is blocked in sandboxed environments
- Scripts will fail with "Failed to download" when testing with real URLs
- This is expected behavior - document as limitation: "Network access blocked in development environment"
- Real functionality validation must be done in GitHub Actions environment

### GitHub Actions Workflow
- Automated scraping configured in `.github/workflows/scrape.yml`
- Runs daily at 6:23 AM UTC: `cron: '23 6 * * *'`
- Workflow automatically creates `scrape.sh` based on repository description
- Manual trigger available via `workflow_dispatch`

## Validation

### Manual Validation Scenarios
- **ALWAYS** validate script syntax before committing changes
- **ALWAYS** test script help output to ensure usage information is correct
- Test scrape.sh generation process:
  ```bash
  # Simulate workflow behavior
  echo '#!/bin/bash' > scrape.sh
  echo "./download.sh 'https://example.com/data.json'" >> scrape.sh
  chmod +x scrape.sh
  cat scrape.sh  # Verify content
  ```
- **Cannot test actual downloading** due to network restrictions - this is expected
- Verify all scripts remain executable: `ls -la *.sh`

### Repository Structure Validation
- Confirm key files exist: `README.md`, `download.sh`, `recursive_download.sh`, `.github/workflows/scrape.yml`
- Check script permissions: `ls -la *.sh` should show `-rwxr-xr-x`

## Script Behavior and Usage

### download.sh
- **Purpose**: Downloads single files from URLs with automatic filename generation and MIME type detection
- **Usage**: `./download.sh URL`
- **Requirements**: URL must start with `http://` or `https://`
- **Features**: Auto-detects file type, pretty-prints JSON with jq, generates safe filenames
- **Output**: Saves file in current directory with format: `domain-path.extension`

### recursive_download.sh  
- **Purpose**: Recursively crawls websites with configurable depth
- **Usage**: `./recursive_download.sh URL [">RECURSIVE=N<"]`
- **Depth limits**: 1-5 (capped at 3 for safety)
- **Features**: Creates subdirectory, respects robots.txt, includes delays between requests
- **Output**: Saves files in `domain_recursive/` directory

### scrape.yml Workflow
- **Trigger conditions**: Push, manual dispatch, daily schedule
- **Auto-generation**: Creates `scrape.sh` from repository description if it contains URLs
- **Recursive support**: Detects `>RECURSIVE=N<` parameter in description
- **Python support**: Available but commented out - uncomment relevant sections if needed

## Common Tasks

### Creating a New Scraper
1. Use this repository as a template
2. Set repository description to target URL (e.g., `https://api.example.com/data.json`)
3. For recursive scraping, add parameter: `https://example.com >RECURSIVE=3<`
4. Workflow will automatically generate appropriate `scrape.sh`

### Modifying Existing Scripts
- Always run `bash -n scriptname.sh` to validate syntax
- Always run `shellcheck scriptname.sh` for additional validation  
- Test script help output after changes
- **Do not test with real URLs** in development environment

### Debugging Workflow Issues
- Check `.github/workflows/scrape.yml` for configuration
- Verify `scrape.sh` exists and is executable
- Review workflow logs in GitHub Actions tab
- Common issue: Repository description missing or malformed URL

## Important Timing and Expectations

### Command Timing (Development Environment)
- Script syntax validation: <1 second
- Shellcheck linting: ~1 second  
- Script creation/modification: <1 second
- Network operations: Will fail immediately due to access restrictions

### Production Timing (GitHub Actions)
- Simple downloads: 1-30 seconds depending on file size
- Recursive downloads: 1-15 minutes depending on depth and site size
- **NEVER CANCEL** network operations in production - timeout should be 30+ minutes for recursive downloads

### Critical Timeout Settings
- For GitHub Actions workflow: Default timeouts are appropriate
- For recursive downloads with depth >2: Allow 15-30 minutes
- **NEVER CANCEL** wget operations in production environment

## File Structure Reference

### Repository Root
```
.
├── .github/
│   └── workflows/
│       └── scrape.yml          # GitHub Actions workflow
├── README.md                   # Template documentation  
├── download.sh                 # Single file downloader (executable)
└── recursive_download.sh       # Recursive web crawler (executable)
```

### Generated Files (After First Run)
```
├── scrape.sh                   # Auto-generated scraping script
└── [downloaded-files]          # Scraped content with auto-generated names
```

## Key Dependencies and Tools
- `curl`: HTTP client for downloading content
- `jq`: JSON pretty-printer (optional but recommended)
- `wget`: Recursive downloading tool
- `file`: MIME type detection
- `mktemp`: Temporary file creation
- `bash`: Shell interpreter (version 4.0+)

All dependencies are pre-installed in GitHub Actions Ubuntu environment.