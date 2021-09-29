#!/bin/bash
# Obtain the token from the environment
do_token=$(cat $HOME/.tokens/vultr_api_token)
# Apply the command
terraform destroy -var="vultr_api_token=$do_token" -var="private_key=none"
