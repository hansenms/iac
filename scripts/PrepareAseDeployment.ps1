[CmdletBinding(DefaultParameterSetName="nodevops")]
param(
    [Parameter(Mandatory=$false)]
    [String]$CertificatePath,

    [Parameter(Mandatory=$false)]
    [String]$DomainName = "contoso-internal.us",

    [Parameter(Mandatory)]
    [securestring]$CertificatePassword,

    [Parameter(Mandatory=$false,ParameterSetName="devops")]
    [String]$AdminUsername = "EnterpriseAdmin",

    [Parameter(Mandatory=$true,ParameterSetName="devops")]
    [securestring]$AdminPassword,
   
    [Parameter(Mandatory=$true,ParameterSetName="devops")]
    [String]$TSServerUrl,

    [Parameter(Mandatory=$true,ParameterSetName="devops")]
    [String]$AgentPool,

    [Parameter(Mandatory=$true,ParameterSetName="devops")]
    [String]$PAToken,

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
    $certificate = Import-PfxCertificate -CertStoreLocation Cert:\LocalMachine\My -FilePath $CertificatePath -Password $CertificatePassword
    $certThumbprint = "cert:\localMachine\my\" + $certificate.Thumbprint    
}

$fileContentBytes = Get-Content $CertificatePath -Encoding Byte
$pfxBlobString = [System.Convert]::ToBase64String($fileContentBytes)

$templateParameters = @{
    "pfxBlobString" = @{
        "value" = $pfxBlobString
    }
    "certificatePassword" = @{
        "value" = (New-Object PSCredential "user", $CertificatePassword).GetNetworkCredential().Password
    }
    "certificateThumbprint" = @{
        "value" = $certificate.Thumbprint
    }
    "domainName" = @{
        "value" = $DomainName
    }
}

if (-not [String]::IsNullOrEmpty($AdminPassword)) {
    $templateParameters.Add("AdminUsername", @{ "value" = $AdminUsername})
    $templateParameters.Add("AdminPassword", @{ "value" = (New-Object PSCredential "user", $AdminPassword).GetNetworkCredential().Password})
    $templateParameters.Add("TSServerUrl", @{ "value" = $TSServerUrl})
    $templateParameters.Add("AgentPool", @{ "value" = $AgentPool})
    $templateParameters.Add("PAToken", @{ "value" = $PAToken})
}


$templateParameters | ConvertTo-Json -Depth 10 | Out-File $OutFile

Write-Host "Parameters written to $OutFile."
