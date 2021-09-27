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
  provisioner "remote-exec" {
    inline = [
      # Create the /home/minecraft directory
      "mkdir /home/minecraft",
      "cd /home/minecraft",
      # Create all the directories and make them accessible for any user.
      "mkdir -p proxy server1 server2",
      "chmod -R 777 /home/minecraft/*",
      # Obtain the docker-compose file
      "wget https://gist.githubusercontent.com/InfinityZ25/cf2c7bc880a702af565032582b481c47/raw/7e21d68d8f8b158ed6b162b07f87558a8f91f906/docker-compose.yml",
      # Start the docker-compose process
      "docker-compose up -d",
    ]
  }
}
