# Register providers
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.10.1"
    }
  }
}
# use -var="do_token=$HOME/.tokens/do_token" with terraform command to set the token
variable "do_token" {}
# use -var="private_key=$HOME/.ssh/id_rsa" to pass down a private key for the ssh connection
variable "private_key" {}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}
# Get ssh key
data "digitalocean_ssh_key" "terraform" {
  name = "jcedeno_mbpro"
}

# Deploy the droplet
resource "digitalocean_droplet" "dedsafio-droplet" {
  image      = "docker-20-04"
  name       = "dedsafio-droplet"
  region     = "nyc3"
  size       = "s-4vcpu-8gb-amd"
  ssh_keys   = [data.digitalocean_ssh_key.terraform.id]
  monitoring = true

  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    private_key = file(var.private_key)
    timeout     = "2m"
  }
  # Create the folders for the deployment 
  provisioner "remote-exec" {
    inline = [
      # Create the /home/minecraft directory
      "mkdir /home/minecraft",
      "cd /home/minecraft",
      # Create all the directories and make them accessible for any user.
      "mkdir -m 777 -p minecraft-data/proxy minecraft-data/server1 minecraft-data/server2",
      # Obtain the docker-compose file
      "wget https://gist.githubusercontent.com/InfinityZ25/cf2c7bc880a702af565032582b481c47/raw/7e21d68d8f8b158ed6b162b07f87558a8f91f906/docker-compose.yml",
    ]
  }
  # Copy the files to the proxy
  provisioner "file" {
    source      = "images/dedsafio-proxy/"
    destination = "/home/minecraft/minecraft-data/proxy"
  }
  # Copy the files to the server1
  provisioner "file" {
    source      = "images/dedsafio-server/"
    destination = "/home/minecraft/minecraft-data/server1"
  }
  # Copy the files to the server2
  provisioner "file" {
    source      = "images/dedsafio-server/"
    destination = "/home/minecraft/minecraft-data/server2"
  }
  # Run the docker-compose command
  provisioner "remote-exec" {
    inline = [
      # Change directories to the /home/minecraft directory
      "cd /home/minecraft",
      # Start the docker-compose process
      "docker-compose up -d",
    ]
  }
}
