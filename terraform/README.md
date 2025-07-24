# Azure Infrastructure for Ahora Caigo Project

This Terraform configuration provisions the Azure infrastructure for the "Ahora Caigo" project based on the specifications in `infra.md`.

## Infrastructure Components

- **Resource Group**: Central resource group for all project resources
- **Azure Static Web App**: For hosting the frontend application
- **Azure App Service**: For hosting the backend API
- **Storage Account**: For static website hosting (alternative to Static Web App)

## Prerequisites

1. **Azure CLI**: Install and authenticate with Azure
2. **Terraform**: Version 1.0 or higher
3. **Azure Subscription**: Active subscription with appropriate permissions

## Quick Start

1. **Authenticate with Azure**:
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Initialize Terraform**:
   ```bash
   cd terraform
   terraform init
   ```

3. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Configuration

### Variables

- `resource_group_name`: Name of the resource group (default: "ahora-caigo-rg")
- `location`: Azure region (default: "East US")
- `storage_account_name`: Storage account name (default: "ahoracaigostorage")
- `app_service_plan_name`: App Service Plan name (default: "ahora-caigo-app-plan")
- `app_service_name`: App Service name (default: "ahora-caigo-backend")
- `static_web_app_name`: Static Web App name (default: "ahora-caigo-frontend")
- `app_service_sku`: App Service Plan SKU (default: "F1" - Free tier)
- `tags`: Resource tags

### Important Notes

- Storage account names must be globally unique
- App Service names must be globally unique
- Static Web App names must be globally unique

## Outputs

After successful deployment, Terraform will output:
- Resource group information
- Storage account details
- App Service URL
- Static Web App URL and API key

## GitHub Actions Integration

For CI/CD integration, you can use the outputs in your GitHub Actions workflow:

```yaml
- name: Deploy to Azure Static Web App
  uses: Azure/static-web-apps-deploy@v1
  with:
    azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
    repo_token: ${{ secrets.GITHUB_TOKEN }}
    app_location: "/frontend"
    api_location: "/backend"
```

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Security Considerations

- All resources are tagged for cost tracking
- App Service uses Linux runtime for better security
- Static Web App provides built-in authentication capabilities
- Consider enabling Azure Key Vault for secrets management

## Cost Optimization

- **F1 SKU**: Free tier for App Service (default) - includes 1GB RAM, 1 GB storage, 60 CPU minutes/day
- **Storage Account**: Uses LRS replication and Cool access tier for cost efficiency
- **Static Web App**: Free tier includes 100GB bandwidth and custom domains
- **B1 SKU**: Cheapest paid tier ($13.14/month) if F1 limitations are exceeded
- Monitor usage with Azure Cost Management
- Use appropriate tags for cost allocation

### Cost Breakdown (Monthly estimates):
- **Resource Group**: Free
- **Static Web App**: Free (up to 100GB bandwidth)
- **App Service F1**: Free (with limitations)
- **Storage Account**: ~$1-5/month depending on usage
- **Total estimated cost**: $1-5/month for basic usage 