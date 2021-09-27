#!/bin/bash
# Obtain the token from the environment
do_token=$(cat $HOME/.tokens/do_token)
# Apply the command
terraform destroy -var="do_token=$do_token" -var="private_key=none"
