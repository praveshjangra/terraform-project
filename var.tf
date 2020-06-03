variable "private_cidr" {
  type    = list
  default = ["192.168.1.0/24", "192.168.2.0/24"]
}

variable "public_cidr" {
  type    = list
  default = ["192.168.3.0/24", "192.168.4.0/24"]

}

variable "key_pair_path" {
  type = map
  default = {
    public_key_path  = "/home/pjangra/.ssh/id_rsa.pub"
    private_key_path = "/home/pjangra/.ssh/id_rsa"
  }
}