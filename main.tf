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
      "mkdir -m 777 -p minecraft-data/proxy minecraft-data/server1 minecraft-data/server2"
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
      "cp -r images/dedsafio-proxy/* /home/minecraft/minecraft-data/proxy/",
      # Move the docker-compose file to the /home/minecraft directory
      "mv images/docker-compose.yml /home/minecraft/",
      # Start the docker-compose process
      "docker-compose up -d",
    ]
  }
}
