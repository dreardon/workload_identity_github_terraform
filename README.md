# Workload Identity Pool with Github Actions and Terraform

## Prerequisites
<ul type="square">
<li>An existing Google Project, this is where permissions will be set and Terraform runs will be targeted. You will need to reference its PROJECT_ID later in this setup</li>

```
export PROJECT_ID=[Project_ID for Terraform]
```

<li>The following environment variables set in Github </li> 

[Github Variable Documentation](https://docs.github.com/en/actions/learn-github-actions/variables)

```
WORKLOAD_IDENTITY_POOL
WORKLOAD_IDENTITY_PROVIDER
WORKLOAD_IDENTITY_POOL_PROJECT_NUMBER
TF_VAR_PROJECT_ID (Project_ID for Terraform)
```
</ul>

## Create an Identity Pool and Provider
```
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
```
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="principalSet://iam.googleapis.com/projects/${WIF_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_IDENTITY_POOL}/attribute.repository/${CONDITION}" \
    --role="roles/storage.admin"
```

## Google Disclaimer
This is not an officially supported Google product