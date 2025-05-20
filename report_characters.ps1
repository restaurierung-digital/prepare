# Determine the characters used in file names with Powershell
# Provides information on potentially problematic characters in the file names
#
# Date: 2024-11-07 | Version 1.0

# Functions
function print-error-end {
	[CmdletBinding()]
	param(
		[Parameter()]
		[string]$error_message = "Unknown error"
	)

	Write-Host -ForegroundColor White -BackgroundColor Red "ERROR: $error_message"
	exit
}

# Welcome Message
Write-Host "Determine the characters used in file names"

# Prompt for the folder with the files
$filePath = Read-Host -Prompt "Path to the files"
if (-not ([string]::IsNullOrEmpty($filePath))) {
	if (-Not (Test-Path -Path "$filePath")) { print-error-end -error_message "Path not found" }
} else {
	print-error-end -error_message "The input must not be an empty string"
}

# Include file extensions 
$includeExtension = Read-Host -Prompt "Include file extensions (y/n) (default: yes)"
if ($includeExtension.ToLower() -eq "n") { 
	[bool]$includeExtension = $false 
} else {
	[bool]$includeExtension = $true
}

# Save results
$saveResults = Read-Host -Prompt "Save results (this includes the potentially problematic file names) (y/n) (default: no)"
if ($saveResults.ToLower() -eq "y") { 
	[bool]$saveResults = $true 
} else {
	[bool]$saveResults = $false
}

# Path under which the results are to be saved
if ($saveResults) {
	$saveResultsFilePath = Read-Host -Prompt "Under which path should the results be saved"
	if (-not ([string]::IsNullOrEmpty($saveResultsFilePath))) {
		if (-Not (Test-Path -Path "$saveResultsFilePath")) { print-error-end -error_message "Path not found" }
	} else {
		print-error-end -error_message "The input must not be an empty string"
	}
}

# Read the file names
$files = Get-ChildItem -Path "$filePath" -File -Force -Recurse

# Initialize variables
$characters = @{}	# Contains the characters found
$nonASCIIcharacters = @{}	 # Contains the non ASCII characters found
$nonASCIIfiles = @()	# Contains the paths to files with non ASCII characters
$extraDotFiles = @()	# Contains the paths to files with extra dots in the name

# Run through the file name for each file and calculate the character frequency
foreach ($file in $files) {

	if($includeExtension) {
		$filename = $file.Name
		$allowedDots = 1
	} else {
		$filename = $file.BaseName
		$allowedDots = 0
	}
	
	# File names with extra dots, a dot is only permitted to separate the file name and file name extension
	if (([regex]::Matches($filename, "\." )).count -gt $allowedDots) {
		$extraDotFiles += $file.FullName
	}

	# Analyze every character in the file name
	foreach ($character in $filename.ToCharArray()) {
		# Increase frequency or create new entry
		if ($characters.ContainsKey($character)) {
			$characters[$character]++
		} else {
			$characters[$character] = 1
		}
		
		# Determine non-Ascii characters
		if ($character -cmatch "[^\u0000-\u007F]") {
			if ($nonASCIIcharacters.ContainsKey($character)) {
				$nonASCIIcharacters[$character]++
			} else {
				$nonASCIIcharacters[$character] = 1
			}
			
			# Files with non-Ascii characters
			if ($nonASCIIfiles -notcontains $file.FullName) { $nonASCIIfiles += $file.FullName }
		}
	}
}

# Show statistics
Write-Host "`nTotal number of files: $($files.Count)"
Write-Host "Number of different characters: $($characters.Count)"
Write-Host "Non ASCII characters: $($nonASCIIcharacters.Count)"
Write-Host "Files with additional dots in the file name: $($extraDotFiles.Count)"

# Show characters
Write-Host "`nFrequency of all characters in file names ($($characters.Count)), potentially problematic characters are displayed in red:"
foreach ($character in $characters.Keys | Sort-Object) {
	if($character -notmatch "[a-zA-Z0-9-_]+") {
		Write-Host -ForegroundColor White -BackgroundColor Red "'$character': $($characters[$character])"
	} else {
		Write-Host "'$character': $($characters[$character])"
	}
	
}

# Show non ASCII characters
Write-Host "`nNon ASCII characters ($($nonASCIIcharacters.Count)):"
if ($nonASCIIcharacters.Count -eq 0) {
	Write-Host "No non-Ascii characters were found"	
} else {
	foreach ($character in $nonASCIIcharacters.Keys | Sort-Object) {
		Write-Host "'$character': $($nonASCIIcharacters[$character])"
	}
}

# Save results
if ($saveResults) {
	
	# Save characters
	try {
		$characters.GetEnumerator() | sort -Property Key | Select-Object -Property @{Name='Character';Expression={$_.Key}}, @{Name='Count';Expression={$_.Value}} | Export-Csv -Path "$saveResultsFilePath\characters.csv" -NoTypeInformation -Encoding utf8 -NoClobber -UseCulture
	} catch {
		print-error-end -error_message $_
	}
	
	# Save non ASCII characters
	try {
		$nonASCIIcharacters.GetEnumerator() | sort -Property Key | Select-Object -Property @{Name='Character';Expression={$_.Key}}, @{Name='Count';Expression={$_.Value}} | Export-Csv -Path "$saveResultsFilePath\nonASCIIcharacters.csv" -NoTypeInformation -Encoding utf8 -NoClobber -UseCulture
	} catch {
		print-error-end -error_message $_
	}	
	
	# Save non ASCII files
	try {
		$nonASCIIfiles | Select-Object -Property @{Name='Path';Expression={$_}} | Export-Csv -Path "$saveResultsFilePath\nonASCIIfiles.csv" -NoTypeInformation -Encoding utf8 -NoClobber -UseCulture
	} catch {
		print-error-end -error_message $_
	}
	
	# Save files with extra dots
	try {
		$extraDotFiles | Select-Object -Property @{Name='Path';Expression={$_}} | Export-Csv -Path "$saveResultsFilePath\extraDotFiles.csv" -NoTypeInformation -Encoding utf8 -NoClobber -UseCulture
	} catch {
		print-error-end -error_message $_
	}
}
