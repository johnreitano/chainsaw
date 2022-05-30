variable "region" {
  description = "AWS region"
  default     = "us-west-2"
  type        = string
}

variable "profile" {
  description = "AWS profile"
  default     = "default"
  type        = string
}
variable "env" {
  description = "The env - either 'testnet' or 'mainnet' -- used as suffix of resource names"
  default     = "testnet"
  type        = string
}

variable "project" {
  description = "The name of this project -- used as prefix of resource names"
  default     = "newchain"
  type        = string
}

variable "ssh_private_key_path" {
  description = "path to private SSH key file"
  default     = "~/.ssh/id_rsa"
  type        = string
}

variable "ssh_public_key_path" {
  description = "path to public SSH key file"
  default     = "~/.ssh/id_rsa.pub"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the vpc"
  default     = "10.0.0.0/16"
}

variable "seed_subnet_cidr" {
  description = "CIDR block for seed subnet"
  default     = "10.0.1.0/24"
}

variable "validator_subnet_cidr" {
  description = "CIDR block for validator subnet"
  default     = "10.0.2.0/24"
}

variable "explorer_subnet_cidr" {
  description = "CIDR block for db subnet"
  default     = "10.0.3.0/24"
}

variable "num_validator_instances" {
  description = "number of validator instances"
  default     = 3
}

variable "num_seed_instances" {
  description = "number of seed instances"
  default     = 1
}
