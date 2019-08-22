#Connect to the Azure subscription for deployment
Connect-AzAccount

#Create a new deployment on Azure, starting with the Virtual Network and a Network Security Group
New-AzResourceGroupDeployment -ResourceGroupName RG-WEBAPPTEST -TemplateFile .\01-VMNetwork\VNtemplate.json -TemplateParameterFile .\01-VMNetwork\VNparameters.json
New-AzResourceGroupDeployment -ResourceGroupName RG-WEBAPPTEST -TemplateFile .\01-VMNetwork\NSGtemplate.json -TemplateParameterFile .\01-VMNetwork\NSGparameters.json
#For the deployment of the app in IaaS, deploy a Load Balancer with an Internal IP
New-AzResourceGroupDeployment -ResourceGroupName RG-WEBAPPTEST -TemplateFile .\01-VMNetwork\LBtemplate.json -TemplateParameterFile .\01-VMNetwork\LBparameters.json
#Deployment in a Free Trial subscription of App Service Environments for load balancing Web Apps in PaaS fails, but you could deploy it with this .json
#New-AzResourceGroupDeployment -ResourceGroupName RG-WEBAPPTEST -TemplateFile .\01-VMNetwork\ASEtemplate.json -TemplateParameterFile .\01-VMNetwork\ASEparameters.json
#Create a new storage account to use with the Web App or to create a share in Azure files in case you deploy in IaaS
New-AzResourceGroupDeployment -ResourceGroupName RG-WEBAPPTEST -TemplateFile .\02-Storage\template.json -TemplateParameterFile .\02-Storage\parameters.json

#After doing this, browse to Data Lake Storage and create a file system named fswebapptest and a share named webapptestshare
#Create a new Key Vault to store secrets and keys
New-AzResourceGroupDeployment -ResourceGroupName RG-WEBAPPTEST -TemplateFile .\03-Keyvault\template.json -TemplateParameterFile .\03-Keyvault\parameters.json

#If using IaaS, enable the key vault to store secure passwords during VM deployment
Set-AzKeyVaultAccessPolicy -VaultName 'KV-WEBAPPTEST' -EnabledForTemplateDeployment
$secretpassword = ConvertTo-SecureString "CarlosR!vera2019" -AsPlainText -Force
$secret = Set-AzKeyVaultSecret -VaultName 'KV-WEBAPPTEST' -Name 'VMAdminPassword' -SecretValue $secretpassword

#Create a new Web App in PaaS to serve .NET Core 2.2 apps
New-AzResourceGroupDeployment -ResourceGroupName RG-WEBAPPTEST -TemplateFile .\04-WebApp\WEBAPPtemplate.json -TemplateParameterFile .\04-WebApp\WEBAPPparameters.json

#Create System Managed ID for the app to access secrets in Key Vault
Set-AzWebApp -AssignIdentity $true -Name SentiaCRwebapptest -ResourceGroupName RG-WEBAPPTEST

#Afer doing this, modify Access Policy in key vault to allow App ID to retrieve secrets from the Azure portal
#Run in Azure CLI, allow access to the file system created in the Storage section to the app, modify with the proper access key in the Storage blade
az webapp config storage-account add -g RG-WEBAPPTEST -n SentiaCRwebapptest --custom-id SentiaCRwebapptestSTG --storage-type AzureFiles --account-name stgwebapptest --share-name webapptestshare --access-key 3WJusJLybl6QBM67Iy3tRem0MTMKZcTCbkv3u7+vluNf3HxNRGc+FHuV27z/h7v3CTcEQ+zGF1K2oyaepww2FQ== --name SentiaCRwebapptest --resource-group RG-WEBAPPTEST
az webapp config storage-account list --name SentiaCRwebapptest --resource-group RG-WEBAPPTEST

#If deploying the Web App in IaaS, deploy two VMs connected to the virtual network and configured behind the Load Balancer
New-AzResourceGroupDeployment -ResourceGroupName RG-WEBAPPTEST -TemplateFile .\04-WebApp\WEB01template.json -TemplateParameterFile .\04-WebApp\WEB01parameters.json
New-AzResourceGroupDeployment -ResourceGroupName RG-WEBAPPTEST -TemplateFile .\04-WebApp\WEB02template.json -TemplateParameterFile .\04-WebApp\WEB02parameters.json

#Set tags on the resource group with 3 tags for Department, Environment and Application/Business Unit
Set-AzResourceGroup -Name RG-WEBAPPTEST -Tag @{ Department="IT"; Environment="Test"; Application="Public Website" }

#Recursively set tags for all resources contained in the Resource Group
$groups = Get-AzResourceGroup -Name RG-WEBAPPTEST
foreach ($g in $groups)
{
    Get-AzResource -ResourceGroupName $g.ResourceGroupName | ForEach-Object {Set-AzResource -ResourceId $_.ResourceId -Tag $g.Tags -Force }
}
