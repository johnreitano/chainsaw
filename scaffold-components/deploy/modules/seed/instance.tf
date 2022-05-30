resource "aws_instance" "seed" {
  count                       = var.num_instances
  ami                         = var.ami
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.seed.id
  key_name                    = "newchain-key"
  vpc_security_group_ids      = [aws_security_group.seed.id]
  associate_public_ip_address = false

  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-seed-${count.index}"
  }
}

resource "aws_eip" "seed" {
  count    = var.num_instances
  instance = aws_instance.seed[count.index].id
  vpc      = true
  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-seed-eip-${count.index}"
  }
}

locals {
  seed_ips_str      = join(",", [for node in aws_eip.seed : node.public_ip])
  validator_ips_str = join(",", var.validator_ips)
}

resource "null_resource" "setup_seed" {
  depends_on = [aws_eip.seed[0], aws_eip.seed[1], aws_eip.seed[2]]
  count      = var.num_instances

  provisioner "local-exec" {
    command = <<-EOF
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ubuntu@${var.validator_ips[0]}:.newchain/config/genesis.json genesis.json
      rm -rf /tmp/newchain/seed
      mkdir -p /tmp/newchain/seed
      cd ..
      git ls-files | tar -czf /tmp/newchain/seed/newchain.tar.gz -T -
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa /tmp/newchain/seed/newchain.tar.gz ubuntu@${aws_eip.seed[count.index].public_ip}:/tmp/newchain.tar.gz
    EOF
  }

  provisioner "remote-exec" {
    inline = [
      "echo setting up seed node",
      "pkill newchaind",
      "rm -rf ~/newchain",
      "mkdir ~/newchain",
      "cd ~/newchain",
      "tar -xzf /tmp/newchain.tar.gz",
      "deploy/modules/seed/setup-seed.sh ${count.index} '${local.seed_ips_str}' '${local.validator_ips_str}'",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.seed[count.index].public_ip
    }
  }
}