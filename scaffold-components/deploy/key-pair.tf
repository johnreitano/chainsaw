resource "aws_key_pair" "deployer" {
  key_name   = "communio-key.${var.env}"
  public_key = file(var.ssh_public_key_path)
}
