# Automatic deployment of WordPress EC2 and RDS on AWS using Terraform

1. Clone the repository
1. Configure variables in 'settings.tfvars'
1. Prepare S3 bucket on AWS for storing tf_state - put S3 details in 'backend' section of 'main.tf'
1. Prepare SSH Key Pair as described [here](terraform/ssh_keys/readme_keys.md)
1. Install AWS CLI
1. Install Terraform
1. Connect to AWS infrastructure: 'aws configure'
1. Initialize Terraform: 'terraform init'


Now the following actions are possible:
- check deployment plan:
    ```
    terraform plan -var-file="settings.tfvars"
    ```
- deploy changes to AWS:
    ```
    terraform plan -var-file="settings.tfvars"
    ```
- check plan for destroy:
    ```
    terraform plan -destroy -var-file="settings.tfvars"
    ```
- destroy the infrastructure:
    ```
    terraform apply -destroy -var-file="settings.tfvars"
    ```
