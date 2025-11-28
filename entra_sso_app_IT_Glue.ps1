
function display_info {

    param (
        [string]$fingerprint
    )


    $tenantId = (Get-MgContext).TenantId

    $loginUrl    = "https://login.microsoftonline.com/$tenantId/saml2"
    $entityId    = "https://sts.windows.net/$tenantId/"
    $logoutUrl   = "https://login.microsoftonline.com/$tenantId/saml2"

    Write-Host "Issuer URL: $entityId" -ForegroundColor Green

    Write-Host "SAML Login Endpoint URL: $loginUrl" -ForegroundColor Green
    
    Write-Host "SAML Logout Endpoint URL: $logoutUrl" -ForegroundColor Green

    Write-Host "Fingerprint: $fingerprint" -ForegroundColor Green

    Write-Host "Please download the certificate from Enterprise App in Base 64 format" -ForegroundColor Yellow

    Write-Host "You can now assign the Groups or User to the app, so that they can access this Microsoft app when they login Microsoft MyApps" -ForegroundColor Yellow


}

function add_cert {

    param (
        [string]$obj_id
    )


    $params = @{
     displayName = "CN=ITG_SSO"
     endDateTime = (Get-Date).AddYears(3)
    }

   $cert = Add-MgServicePrincipalTokenSigningCertificate -ServicePrincipalId $obj_id -BodyParameter $params

   $thumbprint = $($cert.Thumbprint)

   display_info($thumbprint)

}


function basic_SAML {

    param (
        [string]$0bj_id
    
    )


    $saml_consume = "https://$subdomain.itglue.com/saml/consume"
 
    $logout_URL = "https://$subdomain.itglue.com/logout"
 
    $identifier_url = "https://$subdomain.itglue.com"

    $params = @{
    
        Web = @{

            RedirectUris = @($saml_consume)
            LogoutUrl = "$logout_URL"

        }
    
        IdentifierUris = @("$identifier_url")
    }

    Update-MgApplication -ApplicationId $0bj_id -BodyParameter $params



}


function configure_saml {

    param (
        [string]$object_id
    
    )
        
    $SAML_params = @{
        PreferredSingleSignOnMode = "saml"
    }

    Update-MgServicePrincipal -ServicePrincipalId $object_id -BodyParameter $SAML_Params

}


function deploy_app {

 Connect-MgGraph

 $Display_Name = Read-Host "Enter the name for the SSO App (For e.g.: ITGlueSSO)"
    
 
 $Global:Enterpriseapp = Invoke-MgInstantiateApplicationTemplate -ApplicationTemplateId '8adf8e6e-67b2-4cf2-a259-e3dc5476c621'  -DisplayName $Display_Name -ErrorAction Stop

    Start-Sleep -Seconds 5

    $enter_app = (Get-MgServicePrincipal -All | Where-Object { $_.DisplayName -eq $Display_Name })
    $Id = $($enter_app.Id)

    $app_reg = (Get-MgApplication -All | Where-Object { $_.DisplayName -eq $Display_Name })

    $app_obj_id = $($app_reg.Id)

    $Global:subdomain = Read-Host "Enter your subdomain"


    configure_saml($Id)

    basic_SAML($app_obj_id)

    add_cert($Id)
 
}

deploy_app
