[CmdletBinding(DefaultParameterSetName="nossl")]
param(
    [Parameter(Mandatory)]
    [String]$DomainName,

    [Parameter(Mandatory)]
    [String]$AdminUsername,

    [Parameter(Mandatory)]
    [SecureString]$AdminPassword,

    [Parameter(Mandatory)]
    [String]$KeyVaultResourceGroupName,

    [Parameter(Mandatory)]
    [String]$KeyVaultName,

    [Parameter(Mandatory=$false,ParameterSetName="ssl")]
    [String]$CertificatePath,

    [Parameter(Mandatory,ParameterSetName="ssl")]
    [SecureString]$CertificatePassword,

    [Parameter(Mandatory)]
    [String]$Location,

    [Parameter(Mandatory=$false)]
    [String]$OutFile = ".\azuredeploy.parameters.json"
)

if (Test-Path $OutFile) {
    throw "Output file already exists. Please delete or rename"
}

#Check if the user is administrator
if (-not [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")) {
    throw "You must have administrator priveleges to run this script."
}

$azcontext = Get-AzureRmContext
if ([string]::IsNullOrEmpty($azcontext.Account)) {
    throw "User not logged into Azure."   
} 

#Some settings
$DomainAdminPasswordSecretName = "DomainAdminPassword"
$SslCertificateSecretName = "SslCert"

$kvrg = New-AzureRmResourceGroup -Name $KeyVaultResourceGroupName -Location $Location

$kv = New-AzureRmKeyVault -VaultName $KeyVaultName -Location $kvrg.Location -ResourceGroupName $KeyVaultResourceGroupName
Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -EnabledForDiskEncryption -EnabledForDeployment -EnabledForTemplateDeployment

#Store domain password in keyvault. 
$passwdsecret = Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $DomainAdminPasswordSecretName -SecretValue $AdminPassword

$secrets = @()
if (-not [String]::IsNullOrEmpty($CertificatePath)) { 
    #Upload SSL cert to keyvault
    $cer = Import-AzureKeyVaultCertificate -VaultName $KeyVaultName -Name $SslCertificateSecretName -FilePath $CertificatePath -Password $CertificatePassword
    $secret = @{
        "sourceVault" = @{
            "id" = $kv.ResourceId
        }
        "vaultCertificates" = @(
            @{
                "certificateUrl" = $cer.SecretId
                "certificateStore" = "My"
            }
        )
    }
    $secrets = @( $secret )
}


$templateParameters = @{

    "domainName" = @{
        "value" = $DomainName
    }

    "adminUsername" = @{
        "value" = $AdminUsername
    }

    "adminPassword" = @{
        "reference" = @{
            "keyvault" = @{
                "id" = $kv.ResourceId
            }
            "secretName" = $DomainAdminPasswordSecretName
        }
    }

    "secrets" = @{
        "value" = $secret
    }

    "sslThumbPrint" = @{
        "value" = $cer.Thumbprint
    }
}

$templateParameters | ConvertTo-Json -Depth 10 | Out-File $OutFile

Write-Host "Parameters written to $OutFile."
