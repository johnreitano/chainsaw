module "validator" {
  source               = "./modules/validator"
  env                  = var.env
  project              = var.project
  ssh_private_key_path = var.ssh_private_key_path
  ssh_public_key_path  = var.ssh_public_key_path
  vpc_id               = aws_vpc.vpc.id
  igw_id               = aws_internet_gateway.igw.id
  subnet_cidr          = var.validator_subnet_cidr
  ami                  = "ami-0ee8244746ec5d6d4" # Get deatils on this ami in https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#AMICatalog:
  # ami         = data.aws_ami.latest-ubuntu.id
  num_instances = var.num_validator_instances
}

module "seed" {
  source               = "./modules/seed"
  env                  = var.env
  project              = var.project
  ssh_private_key_path = var.ssh_private_key_path
  ssh_public_key_path  = var.ssh_public_key_path
  vpc_id               = aws_vpc.vpc.id
  igw_id               = aws_internet_gateway.igw.id
  subnet_cidr          = var.seed_subnet_cidr
  validator_ips        = module.validator.ips
  ami                  = "ami-0ee8244746ec5d6d4" # Get deatils on this ami in https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#AMICatalog:
  # ami         = data.aws_ami.latest-ubuntu.id
  num_instances = var.num_seed_instances
}

module "explorer" {
  source               = "./modules/explorer"
  env                  = var.env
  project              = var.project
  ssh_private_key_path = var.ssh_private_key_path
  ssh_public_key_path  = var.ssh_public_key_path
  vpc_id               = aws_vpc.vpc.id
  igw_id               = aws_internet_gateway.igw.id
  fe_subnet_cidr       = var.explorer_fe_subnet_cidr
  be_0_subnet_cidr     = var.explorer_be_0_subnet_cidr
  be_1_subnet_cidr     = var.explorer_be_1_subnet_cidr
  ami                  = "ami-0ee8244746ec5d6d4" # Get deatils on this ami in https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#AMICatalog:
  # ami         = data.aws_ami.latest-ubuntu.id
}

# resource "null_resource" "prepare-source" {
#   triggers = {
#     always_run = "${timestamp()}"
#   }

#   provisioner "local-exec" {
#     command = <<-EOF
#       rm -rf /tmp/newchain/code
#       mkdir -p /tmp/newchain/code
#       cd ..
#       git ls-files | tar -czf /tmp/newchain/code/newchain.tar.gz -T -
#     EOF
#   }
# }
