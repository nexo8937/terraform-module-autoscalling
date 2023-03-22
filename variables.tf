variable "instance-type" {
 default = "t2.micro"
}

variable "scale-up-threshold" {
 default = "80"
}

variable "scale-down-threshold" {
 default = "20"
}

variable "scale-up-period" {
 default = "120"
}

variable "scale-down-period" {
 default = "120"
}

variable "image-id" {}
variable "sg" {}
variable "priv-sub-A" {}
variable "priv-sub-B" {}
variable "load-balancer" {}
