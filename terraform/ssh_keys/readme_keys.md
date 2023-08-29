SSH Key Pair should be present in this folder

For local deployment:
- generate rsa key pair called my-rsa-key and my-rsa-key.pub
 (ssh-keygen -t rsa -b 4096 -C "your_email@domain")
  and store them in this folder

For GitHub action deployments:
- generate rsa key pair and store keys in GitHub Secrets
- in workflow file take the secrets and save in this directory as my-rsa-key and my-rsa-key.pub before the Terraform steps

