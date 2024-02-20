$PrintixInstallerURL = ('https://api.printix.net/v1/software/tenants/{0}/appl/CLIENT/os/WIN/type/MSI' -f $PrintixTenantId)

function Install-PrintixClient {

    [CmdletBinding()]
    Param
    (
        [Parameter(position = 0)]
        [String]$TenantDomain,
        [Parameter(position = 1)]
        [String]$TenantId

    )

    try{
        $PrintixFileName = "CLIENT_{$PrintixTenantDomain}_{$PrintixTenantId}.msi"
        $PrintixSavePath = "$Env:SystemDrive\Temp\Printix"
        if(!(Test-Path $PrintixSavePath)){
            New-Item -Path $PrintixSavePath -ItemType Directory | Out-Null
        }
        $PrintixInstallerPath = "$PrintixSavePath\$PrintixFileName"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $PrintixInstallerURL -OutFile $PrintixInstallerPath -Headers @{'Accept' = 'application/octet-stream'}
        if(Test-Path $PrintixInstallerPath){
            Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i $PrintixInstallerPath WRAPPED_ARGUMENTS=/id:$PrintixTenantID" -Wait
        } 
        else{
            Write-Warning "Printix installer not found at $PrintixInstallerPath"
        }
    } 
    catch{
        Write-Warning "Failed to install Printix Client:`r`n $_"
    }

    if(((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\printix' -ErrorAction SilentlyContinue).UninstallString)){
            Write-Host "Printix client installed successfully!"
    }
}

function KickOff {

    if(((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\printix' -ErrorAction SilentlyContinue).UninstallString)){
        ### Printix client is installed
        $DetectedPrintixTenantId = (Get-ItemProperty 'HKLM:\SOFTWARE\printix.net\Printix Client\Tenant').TenantId
        $DetectedPrintixTenantName = (Get-ItemProperty 'HKLM:\SOFTWARE\printix.net\Printix Client\Tenant').TenantName
    
        if($DetectedPrintixTenantName | Select-String "PrintixAutoName"){
            Write-Host "Printix Client is already installed, but has not been authenticated to.`r`nDetails:`r`nTenant ID: $DetectedPrintixTenantId`r`nTenant Name: $DetectedPrintixTenantName"
        }
        else{
            Write-Host "Printix Client is already installed!`r`nDetails:`r`nTenant ID: $DetectedPrintixTenantId`r`nTenant Name: $DetectedPrintixTenantName"
        }
    }
    else{
        ### Printix client is not installed
        Write-Host "Printix client is not installed...downloading and installing now..."
        Install-PrintixClient
    }

}
