param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType Leaf}, ErrorMessage="The builds file path must exist.")]
    [string]
    $BuildsFilePath,

    [Parameter(Mandatory=$true)]
    [string]
    $OutputFilePath
)

# Read the lines of the two files.

$BuildsFileLines = Get-Content $BuildsFilePath -ReadCount 1

# Go through the builds file lines, split it by the colon, and get the first element.
# Ignore lines that are empty or start with a hash.
$BuildsFileLines = $BuildsFileLines | ForEach-Object {
    if ($_.Trim() -eq "") {
        return
    }

    if ($_.StartsWith("#")) {
        return
    }

    $_.Split(" : ")[0].Trim()
}

# If the output file path doesn't exist, use an empty array instead.
$OutputFileLines = @()
if (Test-Path $OutputFilePath -PathType Leaf) {
    $OutputFileLines = Get-Content $OutputFilePath -ReadCount 1
}

# Union the two arrays, do not produce duplicates.
# The result should be alphanumerically sorted from the leftmost character.
# Ignore length, case, and culture.

$UnionLines = $BuildsFileLines + $OutputFileLines | Where-Object {[string]::IsNullOrWhiteSpace($_)} | Select-Object -uniq | Sort-Object -Property { [System.Version]::Parse($_ + ".0") }

# Replace the output file with the created union
Set-Content $OutputFilePath -Value $UnionLines