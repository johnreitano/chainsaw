resource "aws_instance" "explorer" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.explorer_fe.id
  key_name                    = "newchain-key"
  vpc_security_group_ids      = [aws_security_group.explorer_fe.id]
  associate_public_ip_address = false

  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-explorer"
  }

}
resource "aws_eip" "explorer" {
  instance = aws_instance.explorer.id
  vpc      = true
  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-explorer-eip"
  }
}

resource "null_resource" "setup_instance" {
  provisioner "file" {
    source      = "modules/explorer/setup.sh"
    destination = "/tmp/setup.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.explorer.public_ip
    }
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh",
      "echo setting up block explorer"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.explorer.public_ip
    }
  }
}
