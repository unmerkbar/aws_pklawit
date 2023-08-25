Generate rsa key pair called my-rsa-key and my-rsa-key.pub
and store them in this folder

Keys may be generated with the command:

ssh-keygen -t rsa -b 4096 -C "pklawit@gmail.com"

For GitHub action it will be necessary to:
1. store generated priv/pub keys in secrets
2. save them in the terraform/ssh_keys under my-rsa-key and my-rsa-key.pub  before executing the terraform
