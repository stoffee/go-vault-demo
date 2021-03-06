#!/bin/bash

#Get our TF ouputs
VAULT_JSON_KEY=$(terraform output -state ../terraform/terraform.tfstate vault_sa_key)
ORDER_SA=$(terraform output -state ../terraform/terraform.tfstate order_sa_email)
GCP_ZONE=$(terraform output -state ../terraform/terraform.tfstate gcp_zone)
GCP_PROJECT_ID=$(terraform output -state ../terraform/terraform.tfstate gcp_project_id)

#Auth methods
vault auth enable -path=gcp-iam gcp
vault auth enable -path=gcp-gce gcp

#Upload the key
#echo ${VAULT_JSON_KEY} > vault.json
vault write auth/gcp-iam/config credentials="${VAULT_JSON_KEY}"
vault write auth/gcp-gce/config credentials="${VAULT_JSON_KEY}"

#Configure the roles
vault write auth/gcp-iam/role/order\
    type="iam" \
    project_id="${GCP_PROJECT_ID}" \
    policies="order" \
    bound_service_accounts="${ORDER_SA}"

vault write auth/gcp-gce/role/order\
    type="gce" \
    project_id="${GCP_PROJECT_ID}" \
    policies="order" \
    bound_zone="${GCP_ZONE}" \
    bound_instance_group="go-gce-apps"
