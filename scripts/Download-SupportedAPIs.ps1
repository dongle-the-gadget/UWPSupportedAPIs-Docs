param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_}, ErrorMessage="The builds file path must exist.")]
    [string]
    $BuildsFilePath,

    [Parameter(Mandatory=$true)]
    [string]
    $OutputFolderPath
)

function Get-DownloadPath {
    param (
        [string]$BuildNumber
    )

    # Get the Windows 10 SDK download (installer) link
    Switch ($BuildNumber)
    {
        "22621.1178" { return "https://download.microsoft.com/download/b/8/5/b85bd06f-491c-4c1c-923e-75ce2fe2378e/windowssdk/winsdksetup.exe" }
        "22621.755" { return "https://download.microsoft.com/download/7/9/6/7962e9ce-cd69-4574-978c-1202654bd729/windowssdk/winsdksetup.exe" }
        "22000" { return "https://download.microsoft.com/download/1/0/e/10e6da02-01f7-40d4-8942-b98b53b36cf9/windowssdk/winsdksetup.exe" }
        "20348" { return "https://download.microsoft.com/download/9/7/9/97982c1d-d687-41be-9dd3-6d01e52ceb68/windowssdk/winsdksetup.exe" }
        "19041" { return "https://download.microsoft.com/download/4/d/2/4d2b7011-606a-467e-99b4-99550bf24ffc/windowssdk/winsdksetup.exe" }
        "18362" { return "https://download.microsoft.com/download/4/2/2/42245968-6A79-4DA7-A5FB-08C0AD0AE661/windowssdk/winsdksetup.exe" }
        "17763" { return "https://download.microsoft.com/download/5/C/3/5C3770A3-12B4-4DB4-BAE7-99C624EB32AD/windowssdk/winsdksetup.exe" }
        "17134" { return "https://download.microsoft.com/download/5/A/0/5A08CEF4-3EC9-494A-9578-AB687E716C12/windowssdk/winsdksetup.exe?ocid=wdgcx1803-download-installer" }
        "16299" { return "https://download.microsoft.com/download/8/C/3/8C37C5CE-C6B9-4CC8-8B5F-149A9C976035/windowssdk/winsdksetup.exe" }
        "15063" { return "https://download.microsoft.com/download/E/1/B/E1B0E6C0-2FA2-4A1B-B322-714A5586BE63/windowssdk/winsdksetup.exe" }
        "14393" { return "https://download.microsoft.com/download/C/D/8/CD8533F8-5324-4D30-824C-B834C5AD51F9/standalonesdk/sdksetup.exe" }
        "10586" { return "https://download.microsoft.com/download/2/1/2/2122BA8F-7EA6-4784-9195-A8CFB7E7388E/StandaloneSDK/sdksetup.exe" }
        "10240" { return "https://download.microsoft.com/download/E/1/F/E1F1E61E-F3C6-4420-A916-FB7C47FBC89E/standalonesdk/sdksetup.exe" }
        default { throw "The build number '$BuildNumber' is not supported!" }
    }
}

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
    # Get the download URL
    $DownloadUrl = Get-DownloadPath -BuildNumber $_

    # Create a temporary folder in the TEMP directory
    $TempFolder = New-Item -Force -Path $env:TEMP -Name "WindowsSDK-$_" -ItemType Directory

    # Download the Windows 10 SDK installer
    $InstallerPath = Join-Path -Path $TempFolder.FullName -ChildPath "winsdksetup.exe"
    Write-Host "Downloading the $_ SDK installer."
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

    Write-Host "Executing the $_ SDK installer."
    $KitsPath = Join-Path -Path $TempFolder -ChildPath "Windows Kits"
    $KitsProcess = Start-Process -FilePath $InstallerPath -ArgumentList "/features OptionId.WindowsSoftwareLogoToolkit /q /norestart /layout `"$KitsPath`"" -PassThru -Wait

    # Check if the program has succeeded. If not, clean up the folder and throw an exception.
    if ($KitsProcess.ExitCode -ne 0) {
        Remove-Item -Path $TempFolder.FullName -Recurse -Force
        throw "The $_ SDK installer has failed with exit code $($KitsProcess.ExitCode)."
    }

    # Run msiexec with the following parameters
    # /a
    # <KitsPath>\StandaloneSDK\Installers\Windows App Certification Kit SupportedApiList x86-x86_en-us.msi
    # TARGETDIR=<path>\SupportedAPIs
    # /qn
    # The script should wait until the program exits.
    
    Write-Host "Extracting supported APIs installer from $_ SDK."
    $SupportedApisPath = Join-Path -Path $TempFolder.FullName -ChildPath "Supported APIs Installer Files"
    $SupportedApisInstallerProcess = Start-Process -FilePath msiexec -ArgumentList ("/a", "`"$KitsPath\Installers\Windows App Certification Kit SupportedApiList x86-x86_en-us.msi`"", "TARGETDIR=`"$SupportedApisPath`"") -PassThru -Wait

    # Check if the program has succeeded. If not, clean up the folder and throw an exception.
    if ($SupportedApisInstallerProcess.ExitCode -ne 0) {
        Remove-Item -Path $TempFolder.FullName -Recurse -Force
        throw "Extraction of the $_ supported APIs installer has failed with exit code $($SupportedApisProcess.ExitCode)."
    }

    # Copy files named SupportedAPIs-[architecture].xml to <output folder>\<build number>
    Write-Host "Copying $_ supported APIs files to output folder."
    $DestinationPath = Join-Path -Path $OutputFolder.FullName -ChildPath $_
    New-Item -Force $DestinationPath -ItemType Directory | Out-Null
    $SupportedApisFiles = Get-ChildItem -Path $SupportedApisPath -Filter "SupportedAPIs-*.xml" -Recurse

    foreach ($SupportedApisFile in $SupportedApisFiles) {
        Copy-Item -Path $SupportedApisFile.FullName -Destination $DestinationPath -Force | Out-Null
    }

    # Clean up the temporary folder
    Write-Host "Cleaning up the $_ SDK installer."
    Remove-Item -Path $TempFolder.FullName -Recurse -Force

    Write-Host ""
}