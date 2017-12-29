[CmdletBinding(DefaultParameterSetName="nossl")]
param(
    # Domain Name
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
    [String]$Location
)

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
Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $DomainAdminPasswordSecretName -SecretValue $AdminPassword

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
        "value" = @( $secret )
    }

    "sslThumbPrint" = @{
        "value" = $cer.Thumbprint
    }
}

return $templateParameters