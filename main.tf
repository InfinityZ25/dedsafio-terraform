# Register providers
terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "2.4.2"
    }
  }
}
# use -var="do_token=$HOME/.tokens/vultr_api_token" with terraform command to set the token
variable "vultr_api_token" {}
# use -var="private_key=$HOME/.ssh/id_rsa" to pass down a private key for the ssh connection
variable "private_key" {}

# Configure the Vultr Provider
provider "vultr" {
  token = var.vultr_api_token
}
# Get ssh key
data "vultr_ssh_key" "jcedenoSSH" {
  filter {
    name = "name"
    # Name of your ssh key in Vultr
    values = ["mac-jc"]
  }
}
data "vultr_ssh_key" "aleSSH" {
  filter {
    name = "name"
    # Name of your ssh key in Vultr
    values = ["ale"]
  }
}

# Deploy the droplet
resource "vultr_baremetal_instance" "dedsafio-droplet" { # To use baremetal, change vultr_instance to vultr_baremetal_instance
  plan        = "vbm-8c-132gb"                           # Dedicated 8vcpu 32gb ram, change to vbm-8c-132gb to use baremetal
  app_id      = "37"                                     # Docker on Ubuntu 20.04
  region      = "ewr"                                    # NYC/NJ region
  hostname    = "dedsafio"
  label       = "dedsafioBingo" # Label in Vultr
  ssh_key_ids = [data.vultr_ssh_key.jcedenoSSH.id, data.vultr_ssh_key.aleSSH.id]

  connection {
    host        = self.main_ip
    user        = "root"
    type        = "ssh"
    private_key = file(var.private_key)
    timeout     = "3m"
  }
  # Create the folders for the deployment 
  provisioner "remote-exec" {
    inline = [
      # Create the /home/minecraft directory
      "mkdir /home/minecraft",
      "cd /home/minecraft",
      # Create all the directories and make them accessible for any user.
      "mkdir -m 777 -p minecraft-data/proxy minecraft-data/lobby minecraft-data/server1 minecraft-data/server2 minecraft-data/server3",
      # Open ports
      "ufw allow 25560:25565/tcp"
    ]
  }
  # Copy the files to the proxy
  provisioner "file" {
    source      = "images"
    destination = "/home/minecraft/"
  }
  # Run the docker-compose command
  provisioner "remote-exec" {
    inline = [
      # Change directories to the /home/minecraft directory
      "cd /home/minecraft",
      # Copy the contents of the images folder to the respective server folder
      "cp -r images/dedsafio-server/* /home/minecraft/minecraft-data/server1/",
      "cp -r images/dedsafio-server/* /home/minecraft/minecraft-data/server2/",
      "cp -r images/dedsafio-server/* /home/minecraft/minecraft-data/server3/",
      "cp -r images/dedsafio-lobby/* /home/minecraft/minecraft-data/lobby/",
      "cp -r images/dedsafio-proxy/* /home/minecraft/minecraft-data/proxy/",
      # Move the docker-compose file to the /home/minecraft directory
      "mv images/docker-compose.yml /home/minecraft/",
      # Start the docker-compose process
      "docker-compose up -d",
    ]
  }
}
