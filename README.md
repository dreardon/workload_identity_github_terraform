# Workload Identity Pool with Github Actions and Terraform

This repository provides a working example of how to configure and use Google Cloud's **Workload Identity Federation** with **GitHub Actions** and **Terraform**. This setup allows your GitHub Actions workflows to securely authenticate to Google Cloud without needing to store and manage long-lived service account keys as GitHub secrets.

The example Terraform code provisions a single Google Cloud Storage bucket to demonstrate that the authentication is working correctly.

### How it Works

1.  A GitHub Actions workflow is triggered (e.g., by a `push` to a branch).
2.  The workflow requests a short-lived OIDC token from GitHub's token server. This token contains claims about the repository and workflow run.
3.  The workflow, using the `google-github-actions/auth` action, presents this OIDC token to Google's Security Token Service (STS).
4.  STS validates the token against a pre-configured Workload Identity Pool and Provider. The provider is configured to trust tokens issued by GitHub and has a condition that restricts access to a specific repository.
5.  Upon successful validation, STS issues a short-lived Google Cloud access token.
6.  The workflow uses this Google Cloud access token to authenticate Terraform, which can then manage resources in your Google Cloud project.

### Prerequisites
<ul type="square">
<li>An existing Google Project. This is where permissions will be set and Terraform runs will be targeted. You will need to reference its PROJECT_ID later in this setup</li>

```bash
export PROJECT_ID=[Project_ID for Terraform]
```
<li>A storage bucket where you'll reference Terraform state</li>

```bash
gcloud storage buckets create gs://$PROJECT_ID-terraform-state \
--location=US \
--project=$PROJECT_ID
```

<li>The following environment variables set in Github </li> 
In your forked GitHub repository, go to `Settings > Secrets and variables > Actions`. Select the **Variables** tab and create the following repository variables. These are used by the GitHub Actions workflow to authenticate.

*   `WORKLOAD_IDENTITY_POOL`: The name of your pool (e.g., `github-actions-pool`).
*   `WORKLOAD_IDENTITY_PROVIDER`: The name of your provider (e.g., `github-actions-provider`).
*   `WORKLOAD_IDENTITY_POOL_PROJECT_NUMBER`: The project number where the WIF pool was created.
*   `BACKEND_BUCKET`: The name of the Terraform state bucket (do not include `gs://`).
*   `TF_VAR_PROJECT_ID`: The project ID where Terraform will create resources.

For more information on GitHub variables, see [Github Variable Documentation](https://docs.github.com/en/actions/learn-github-actions/variables)
</ul>

## Create an Identity Pool and Provider
```bash
export WIF_PROJECT_ID=[WIF Project ID]
export WIF_PROJECT_NUMBER=[WIF Project Number]
export WORKLOAD_IDENTITY_POOL=[Workload Identity Pool] #New Workload Identity Pool Name
export WORKLOAD_IDENTITY_PROVIDER=[Workload Identity Provider] #New Workload Identity Provider Name
export CONDITION=[Identity Pool Condition] # e.g. dreardon/workload_identity_github_terraform

gcloud iam workload-identity-pools create $WORKLOAD_IDENTITY_POOL \
  --location="global" \
  --project="${WIF_PROJECT_ID}" \
  --description="Workload Identity Pool for Github Actions with Terraform" \
  --display-name="Github Actions WIF and Terraform"

#Gitlab Repository-Level Conditional Access
gcloud iam workload-identity-pools providers create-oidc $WORKLOAD_IDENTITY_PROVIDER \
  --project="${WIF_PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool=$WORKLOAD_IDENTITY_POOL \
  --display-name="Github Actions Provder" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="attribute.repository == '${CONDITION}'" \
  --issuer-uri="https://token.actions.githubusercontent.com"  
```

## Project IAM Permissions for Workload Identity Pool Provider
```bash
#Terraform State Bucket Access
gcloud storage buckets add-iam-policy-binding gs://$PROJECT_ID-terraform-state \
--member="principalSet://iam.googleapis.com/projects/${WIF_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_IDENTITY_POOL}/attribute.repository/${CONDITION}" \
--role=roles/storage.objectUser

#Additional Example from Terraform Build-out
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="principalSet://iam.googleapis.com/projects/${WIF_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_IDENTITY_POOL}/attribute.repository/${CONDITION}" \
    --role="roles/storage.admin"
```

## Google Disclaimer
This is not an officially supported Google product