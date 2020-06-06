variable "env" {
  default = "prod"
}

variable "vpc_cidr" {
  default = "192.168.0.0/16"
}
variable "key_pair_path" {
  type = map
  default = {
    public_key_path  = "/home/pjangra/.ssh/id_rsa.pub"
    private_key_path = "/home/pjangra/.ssh/id_rsa"
  }
}

