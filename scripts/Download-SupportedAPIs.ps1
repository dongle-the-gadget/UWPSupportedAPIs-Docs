param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_}, ErrorMessage="The builds file path must exist.")]
    [string]
    $BuildsFilePath,

    [Parameter(Mandatory=$true)]
    [string]
    $OutputFolderPath
)

# Check if the script is running on Windows,
# regardless of whether it's running on Windows PowerShell
# or PowerShell Core
if ([System.Environment]::OSVersion.Platform -ne "Win32NT") {
    throw "This script can only be run on Windows."
}

$progresspreference = 'silentlyContinue'

# Try to create the output folder
$OutputFolder = New-Item -Force $OutputFolderPath -ItemType Directory

# Read the build numbers from the file, line by line
Get-Content $BuildsFilePath -ReadCount 1 | ForEach-Object {
    # Check if the line is empty
    if ($_.Trim() -eq "") {
        return
    }

    # Check if the line is a comment
    if ($_.StartsWith("#")) {
        return
    }

    # Retrieve information in the following format from the line:
    # <build number> : <type (either "retail" or "insider")> : <download URL>
    $BuildInfo = $_.Split(" : ")
    $BuildNumber = $BuildInfo[0]
    $DownloadUrl = $BuildInfo[2]

    # Check if the files <output folder>\<build number>\SupportedAPIs-[x64|x86|arm].xml files exist
    # If it does, skip the build
    $DestinationPath = Join-Path -Path $OutputFolder.FullName -ChildPath $BuildNumber
    $SupportedAPIsx86 = Join-Path -Path $DestinationPath -ChildPath "SupportedAPIs-x86.xml"
    $SupportedAPIsx64 = Join-Path -Path $DestinationPath -ChildPath "SupportedAPIs-x64.xml"
    $SupportedAPIsarm = Join-Path -Path $DestinationPath -ChildPath "SupportedAPIs-arm.xml"
    If ((Test-Path $SupportedAPIsx86) -and (Test-Path $SupportedAPIsx64) -and (Test-Path $SupportedAPIsarm)) {
        Write-Host "The $BuildNumber supported APIs files already exist. Skipping."
        Write-Host ""
        break
    }

    # Create a temporary folder in the TEMP directory
    $TempFolder = New-Item -Force -Path $env:TEMP -Name "WindowsSDK-$BuildNumber" -ItemType Directory

    # Download the Windows 10 SDK installer
    $InstallerPath = Join-Path -Path $TempFolder.FullName -ChildPath "winsdksetup.exe"
    Write-Host "Downloading the $BuildNumber SDK installer."
    try
    {
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath -UseBasicParsing | Out-Null
    }
    catch
    {
        # Clean up the temporary folder and re-throw the exception
        Remove-Item -Path $TempFolder.FullName -Recurse -Force
        throw $_
    }

    # Run the installer using the following command line arguments:
    # /features OptionId.WindowsSoftwareLogoToolkit
    # /q /norestart
    # /layout <path>\Windows Kits
    # The script should wait until the program exits.

    Write-Host "Executing the $BuildNumber SDK installer."
    $KitsPath = Join-Path -Path $TempFolder -ChildPath "Windows Kits"
    $KitsProcess = Start-Process -FilePath $InstallerPath -ArgumentList "/features OptionId.WindowsSoftwareLogoToolkit /q /norestart /layout `"$KitsPath`"" -PassThru -Wait

    # Check if the program has succeeded. If not, clean up the folder and throw an exception.
    if ($KitsProcess.ExitCode -ne 0) {
        Remove-Item -Path $TempFolder.FullName -Recurse -Force
        throw "The $BuildNumber SDK installer has failed with exit code $($KitsProcess.ExitCode)."
    }

    # Run msiexec with the following parameters
    # /a
    # <KitsPath>\StandaloneSDK\Installers\Windows App Certification Kit SupportedApiList x86-x86_en-us.msi
    # TARGETDIR=<path>\SupportedAPIs
    # /qn
    # The script should wait until the program exits.
    
    Write-Host "Extracting supported APIs installer from $BuildNumber SDK."
    $SupportedApisPath = Join-Path -Path $TempFolder.FullName -ChildPath "Supported APIs Installer Files"
    $SupportedApisInstallerProcess = Start-Process -FilePath msiexec -ArgumentList ("/a", "`"$KitsPath\Installers\Windows App Certification Kit SupportedApiList x86-x86_en-us.msi`"", "TARGETDIR=`"$SupportedApisPath`"") -PassThru -Wait

    # Check if the program has succeeded. If not, clean up the folder and throw an exception.
    if ($SupportedApisInstallerProcess.ExitCode -ne 0) {
        Remove-Item -Path $TempFolder.FullName -Recurse -Force
        throw "Extraction of the $BuildNumber supported APIs installer has failed with exit code $($SupportedApisProcess.ExitCode)."
    }

    # Copy files named SupportedAPIs-[architecture].xml to <output folder>\<build number>
    Write-Host "Copying $BuildNumber supported APIs files to output folder."
    $SupportedApisFiles = Get-ChildItem -Path $SupportedApisPath -Filter "SupportedAPIs-*.xml" -Recurse

    foreach ($SupportedApisFile in $SupportedApisFiles) {
        Copy-Item -Path $SupportedApisFile.FullName -Destination $DestinationPath -Force | Out-Null
    }

    # Clean up the temporary folder
    Write-Host "Cleaning up the $BuildNumber SDK installer."
    Remove-Item -Path $TempFolder.FullName -Recurse -Force

    Write-Host ""
}