param(
    [Parameter(Mandatory=$false)]
    [String]$CertificatePath,

    [Parameter(Mandatory=$false)]
    [String]$DomainName = "contoso-internal.us",

    [Parameter(Mandatory)]
    [securestring]$CertificatePassword,

    [Parameter(Mandatory=$false)]
    [String]$OutFile = ".\azuredeploy.parameters.json"

)

#Check if the user is administrator
if (-not [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")) {
    throw "You must have administrator priveleges to run this script."
}

if ([String]::IsNullOrEmpty($CertificatePath)) {
    $CertificatePath = [System.IO.Path]::GetTempFileName()

    $certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname "*.$DomainName","*.scm.$DomainName"
    $certThumbprint = "cert:\localMachine\my\" + $certificate.Thumbprint    
    Export-PfxCertificate -cert $certThumbprint -FilePath $CertificatePath -Password $CertificatePassword
} else {
    $certificate = Get-PfxCertificate -FilePath $CertificatePath -Password $CertificatePassword
}

$fileContentBytes = Get-Content $CertificatePath -Encoding Byte
$pfxBlobString = [System.Convert]::ToBase64String($fileContentBytes)

$templateParameters = @{
    "pfxBlobString" = @{
        "value" = $pfxBlobString
    }
    "certificatePassword" = @{
        "value" = $CertificatePassword
    }
    "certificateThumbprint" = @{
        "value" = $certificate.Thumbprint
    }
}

$templateParameters | ConvertTo-Json -Depth 10 | Out-File $OutFile

Write-Host "Parameters written to $OutFile."
