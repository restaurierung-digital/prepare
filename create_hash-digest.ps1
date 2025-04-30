# Create the hash values of the files in a folder (recursively) as a CSV file with Powershell using Get-FileHash
#
# Get-FileHash
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash
#
# Date: 2023-02-21 | Version 1.0

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
Write-Host "Create Hash Digest from Folder (recursively) as CSV using Get-FileHash"

# Get path to source folder
Write-Host "Please select a folder for which the hash digest should be created"
[void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")
$folder = New-Object System.Windows.Forms.FolderBrowserDialog
$folder.Description = "Please select a folder for which the hash digest should be created"
$folder.RootFolder = "Desktop"
$folder.ShowNewFolderButton = $false
$show = $folder.ShowDialog()
if ($show -eq "OK")
{
	$folder_source_path = $folder.SelectedPath
}

if([string]::IsNullOrWhiteSpace($folder_source_path)) {
    print-error-end -error_message "Please specify the source folder path"
}

if(!(Test-Path -Path $folder_source_path)) {
    print-error-end -error_message "The specified path could not be found"
}

# Get path to destination folder
Write-Host "Please select a folder in which the hash digest should be saved"
[void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")
$folder = New-Object System.Windows.Forms.FolderBrowserDialog
$folder.Description = "Please select a folder in which the hash digest should be saved"
$folder.RootFolder = "Desktop"
$folder.SelectedPath = $folder_source_path
$folder.ShowNewFolderButton = $true
$show = $folder.ShowDialog()
if ($show -eq "OK")
{
	$folder_destination_path = $folder.SelectedPath
}

if([string]::IsNullOrWhiteSpace($folder_destination_path)) {
    print-error-end -error_message "Please specify the destination folder path"
}

if(!(Test-Path -Path $folder_destination_path)) {
    print-error-end -error_message "The specified path could not be found"
}

# Prompt for Algorithm
# Algorithm: SHA1, SHA256, SHA384, SHA512, MD5
$compatibleAlgorithms = "SHA1","SHA256","SHA384","SHA512","MD5"
$algorithm = Read-Host -Prompt "File type (SHA1, SHA256, SHA384, SHA512, MD5) (default: MD5)"
if ([string]::IsNullOrEmpty($algorithm)) { $algorithm = "MD5" }
if ($compatibleAlgorithms.contains($algorithm.toUpper())) {
	$algorithm = [string]$algorithm
} else {
	print-error-end -error_message "Not a compatible algorithm"
}

# Create CSV filename: [name-of-source-folder]_[now()]_[Algorithm.ToLower()]_[$hash_basename]
$hash_basename = "digest.csv"
$hash_now = Get-Date -UFormat "%Y%m%d%H%M%S"
$hash_source_folder_name = Split-Path $folder_source_path -Leaf
$hash_source_folder_basename = Split-Path $folder_source_path -Parent

if ([string]::IsNullOrEmpty($hash_source_folder_basename)) {
	$hash_out_filename = $folder_destination_path+(Get-Item -Path "$folder_source_path").PSDrive.Name+"_"+$hash_now+"_"+$algorithm.ToLower()+"_"+$hash_basename
} else {
	if (($hash_source_folder_basename)[-1] -eq "\") {
		$hash_out_filename = $hash_source_folder_basename+$hash_source_folder_name+"_"+$hash_now+"_"+$algorithm.ToLower()+"_"+$hash_basename
	}
	else {
		$hash_out_filename = $hash_source_folder_basename+"\"+$hash_source_folder_name+"_"+$hash_now+"_"+$algorithm.ToLower()+"_"+$hash_basename
	}	
}

# Create Hashes and write CSV
Write-Host "Creating Hash Digest ... Depending on the size and number of files, this may take some time ..."
Write-Host "Algorithm: $algorithm"
Write-Host "Source: $folder_source_path"

Get-FileHash -Algorithm $algorithm -Path (Get-ChildItem "$folder_source_path\*.*" -Recurse -Force) | Export-CSV -Path "$hash_out_filename" -Encoding utf8 -NoTypeInformation -UseCulture -NoClobber

Write-Host "Hash Digest: $hash_out_filename"
