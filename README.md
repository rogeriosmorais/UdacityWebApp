# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
This project is a packer template and Terraform template to deploy a customizable, scalable web server in Azure.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
1. Create a new resource group in Azure. You can use the portal for that: https://portal.azure.com/
2. In your Subscription control panel in the Azure portal, create a new Role Assignment with the Role "Contributor"
3. Create a new file (bat or shell) to set up environment variables, this example is for Windows. Replace with the proper values for your instance:

```
set ARM_CLIENT_ID=xxxxxx
set ARM_CLIENT_SECRET=xxxxxx
set ARM_SUBSCRIPTION_ID=xxxxxxxx
set ARM_TENANT_ID=xxxxxxx
set ARM_APP_ID=xxxxxx

set TF_VAR_subscription_id=xxxxxxx
set TF_VAR_client_id=xxxxxxx
set TF_VAR_client_secret=xxxxxxx
set TF_VAR_tenant_id=xxxxxxxx
```

4. Run `packer build server.json`

5. Run `terraform init`

6. Run `terraform import azurerm_resource_group.resourcegroup_name /subscriptions/<your_subscription_id>/resourceGroups/<your_resource_group_name>`

7. Run `terraform plan -out solution.plan`

8. Run `terraform apply solution.plan`


### Output
Terraform Apply-<br />
<img src="/Screenshots/Terraform apply execution result.png">


