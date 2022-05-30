resource "aws_key_pair" "deployer" {
  key_name   = "newchain-key"
  public_key = file(var.ssh_public_key_path)
}

