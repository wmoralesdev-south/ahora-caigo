# GitHub Actions Setup Guide for Ahora Caigo Infrastructure

This guide provides step-by-step instructions to configure GitHub Actions for automatic Terraform deployment to Azure using OpenID Connect (OIDC) authentication.

## Prerequisites

- Azure subscription with appropriate permissions
- GitHub repository with the Terraform code
- Azure CLI installed locally (for initial setup)

## Step 1: Create Azure Service Principal with Federated Identity

### 1.1 Login to Azure CLI
```bash
az login
az account set --subscription "your-subscription-id"
```

### 1.2 Create Service Principal
```bash
# Replace with your subscription ID and GitHub repository details
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
GITHUB_ORG="your-github-username-or-org"
GITHUB_REPO="your-repository-name"

# Create service principal with Contributor role
az ad sp create-for-rbac \
  --name "ahora-caigo-terraform-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID"
```

### 1.3 Save the Output
The command will output JSON similar to this:
```json
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "ahora-caigo-terraform-sp",
  "password": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

**⚠️ Important**: Save the `appId` (Client ID) and `tenant` (Tenant ID) - you'll need them for GitHub secrets.

### 1.4 Configure Federated Identity Credential
```bash
# Get the Application ID from the previous step
APP_ID="your-app-id-from-step-1.3"

# Create federated identity credential for main branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "ahora-caigo-main-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/main",
    "description": "Main branch deployment",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create federated identity credential for pull requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "ahora-caigo-pull-requests",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':pull_request",
    "description": "Pull request validation",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

## Step 2: Configure GitHub Repository Secrets

Navigate to your GitHub repository and go to **Settings** → **Secrets and variables** → **Actions**.

### 2.1 Required Secrets (OIDC Authentication)

Create the following **Repository Secrets**:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AZURE_CLIENT_ID` | `appId` from Step 1.3 | Service Principal Client ID |
| `AZURE_SUBSCRIPTION_ID` | Your Azure Subscription ID | Azure Subscription ID |
| `AZURE_TENANT_ID` | `tenant` from Step 1.3 | Azure Tenant ID |

**Note**: With OIDC authentication, you no longer need to store the client secret (`AZURE_CLIENT_SECRET`) or the full credentials JSON (`AZURE_CREDENTIALS`) as secrets, making this approach more secure.

### 2.2 How to Add Secrets

1. Click **"New repository secret"**
2. Enter the **Name** (e.g., `AZURE_CREDENTIALS`)
3. Paste the **Value** (the JSON or specific value)
4. Click **"Add secret"**
5. Repeat for all required secrets

## Step 3: Configure Terraform Backend (Optional but Recommended)

For production deployments, store Terraform state in Azure Storage.

### 3.1 Create Storage Account for State
```bash
# Create resource group for Terraform state (if not exists)
az group create --name "ahora-caigo-terraform-state" --location "East US"

# Create storage account for Terraform state
az storage account create \
  --name "ahoracaigotfstate" \
  --resource-group "ahora-caigo-terraform-state" \
  --location "East US" \
  --sku "Standard_LRS" \
  --encryption-services blob

# Create container for state files
az storage container create \
  --name "tfstate" \
  --account-name "ahoracaigotfstate"
```

### 3.2 Update Terraform Configuration
Add this to your `terraform/main.tf` at the top:

```hcl
terraform {
  required_version = ">= 1.0"
  
  backend "azurerm" {
    resource_group_name   = "ahora-caigo-terraform-state"
    storage_account_name  = "ahoracaigotfstate"
    container_name        = "tfstate"
    key                   = "ahora-caigo.terraform.tfstate"
  }
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}
```

## Step 4: Configure GitHub Actions Variables (Optional)

For environment-specific configurations, you can set **Repository Variables**:

| Variable Name | Value | Description |
|---------------|-------|-------------|
| `AZURE_LOCATION` | `East US` | Default Azure region |
| `TERRAFORM_VERSION` | `1.5.0` | Terraform version to use |
| `RESOURCE_GROUP_NAME` | `ahora-caigo-rg` | Resource group name |

### 4.1 How to Add Variables
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click the **"Variables"** tab
3. Click **"New repository variable"**
4. Enter **Name** and **Value**
5. Click **"Add variable"**

## Step 5: Test the Setup

### 5.1 Verify Secrets Configuration
Create a test workflow to verify OIDC authentication is properly configured:

```yaml
# .github/workflows/test-secrets.yml
name: Test Azure Connection with OIDC
on:
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      id-token: write # Required to fetch an OIDC token
      contents: read  # Required to checkout repository
    
    steps:
    - name: Azure Login
      uses: azure/login@v2
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    
    - name: Test Azure CLI
      run: |
        az account show
        az group list --query "[?name=='ahora-caigo-rg']"
```

### 5.2 Run the Test
1. Go to **Actions** tab in your repository
2. Select **"Test Azure Connection with OIDC"**
3. Click **"Run workflow"**
4. Verify it completes successfully

## Step 6: Trigger Terraform Deployment

### 6.1 Automatic Triggers
The workflow automatically runs when:
- Files in `terraform/` directory are changed
- Changes are pushed to `main` branch
- Pull requests are created with Terraform changes

### 6.2 Manual Trigger
You can also trigger manually:
1. Go to **Actions** tab
2. Select **"Terraform Infrastructure Deployment"**
3. Click **"Run workflow"**

## Step 7: Monitor Deployment

### 7.1 View Workflow Progress
- Go to **Actions** tab
- Click on the running workflow
- Monitor each step's progress and logs

### 7.2 Check Terraform Plan in PRs
- Create a pull request with Terraform changes
- The workflow will comment with the Terraform plan
- Review changes before merging

## Troubleshooting

### Common Issues and Solutions

#### 1. Authentication Errors
**Error**: `Error: building AzureRM Client: obtain subscription` or OIDC token errors

**Solution**: 
- Verify all Azure secrets are correctly set (CLIENT_ID, TENANT_ID, SUBSCRIPTION_ID)
- Ensure federated identity credentials are properly configured
- Check that the repository and branch names match exactly in the federated credential
- Verify the service principal has proper permissions

#### 2. Permission Denied
**Error**: `AuthorizationFailed: does not have authorization`

**Solution**:
```bash
# Grant additional permissions to service principal
az role assignment create \
  --assignee "your-service-principal-client-id" \
  --role "Contributor" \
  --scope "/subscriptions/your-subscription-id"
```

#### 3. Resource Already Exists
**Error**: `A resource with the ID already exists`

**Solution**: 
- Import existing resources to Terraform state
- Or destroy existing resources if safe to do so

#### 4. Storage Account Name Conflict
**Error**: `StorageAccountAlreadyTaken`

**Solution**: 
- Change `storage_account_name` in `terraform.tfvars`
- Storage account names must be globally unique

### Debug Commands

Run these locally to debug issues:

```bash
# Test Azure authentication (traditional method for local testing)
az login

# Or test with service principal (if you have the password)
az login --service-principal \
  --username $AZURE_CLIENT_ID \
  --password "your-service-principal-password" \
  --tenant $AZURE_TENANT_ID

# Test Terraform configuration
cd terraform
terraform init
terraform validate
terraform plan

# Check federated identity credentials
az ad app federated-credential list --id $AZURE_CLIENT_ID
```

## Security Best Practices

### 1. Least Privilege Access
- Grant minimal required permissions to service principal
- Use separate service principals for different environments

### 2. Secret Rotation
- Rotate service principal secrets regularly (every 90 days)
- Update GitHub secrets when rotating

### 3. Environment Protection
- Use GitHub environment protection rules for production
- Require reviews for production deployments

### 4. Audit and Monitoring
- Enable Azure Activity Log monitoring
- Review GitHub Actions logs regularly
- Set up alerts for failed deployments

## Next Steps

After successful setup:

1. **Test the deployment** with a small change
2. **Set up branch protection** rules for main branch
3. **Configure environment-specific** variables if needed
4. **Add monitoring and alerting** for the infrastructure
5. **Document the deployment process** for your team

## Support

If you encounter issues:

1. Check the **Actions** logs for detailed error messages
2. Verify all secrets are correctly configured
3. Test Azure CLI authentication locally
4. Review Azure portal for resource conflicts
5. Check Terraform state for inconsistencies

---

**✅ Checklist for Completion:**
- [ ] Azure Service Principal created with OIDC support
- [ ] Federated identity credentials configured for main branch and pull requests
- [ ] GitHub secrets configured (CLIENT_ID, TENANT_ID, SUBSCRIPTION_ID only)
- [ ] Terraform backend configured (optional)
- [ ] Test workflow runs successfully with OIDC authentication
- [ ] Main workflow deploys infrastructure
- [ ] Team has access to monitor deployments

## Benefits of OIDC Authentication

✅ **Enhanced Security**: No long-lived secrets stored in GitHub
✅ **Automatic Token Rotation**: Tokens are short-lived and automatically refreshed
✅ **Fine-grained Access Control**: Federated credentials can be scoped to specific branches/environments
✅ **Microsoft Recommended**: Latest best practice from Microsoft Azure documentation
✅ **Audit Trail**: Better logging and monitoring of authentication events

Reference: [Microsoft Learn - Use Azure Login action with OpenID Connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect) 
