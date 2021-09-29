#!/bin/bash
# Obtain the token from the environment
vultr_api_token=$(cat $HOME/.tokens/vultr_api_token)
# Apply the command
terraform apply -var="vultr_api_token=$vultr_api_token" -var "private_key=$HOME/.ssh/id_rsa"
