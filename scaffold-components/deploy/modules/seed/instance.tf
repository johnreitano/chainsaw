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
  depends_on        = concat(aws_eip.seed, var.validator_ips)
  seed_ips_str      = join(",", [for node in aws_eip.seed : node.public_ip])
  validator_ips_str = join(",", var.validator_ips)
}

resource "null_resource" "build_client" {
  depends_on = [aws_eip.seed[0], aws_eip.seed[1], aws_eip.seed[2], aws_security_group.seed]
  count      = var.num_instances

  provisioner "local-exec" {
    command = <<-EOF
      if [[ "${count.index}" = "0" ]]; then
        rm -rf /tmp/newchain/seed/code
        mkdir -p /tmp/newchain/seed/code
        cd ..
        git ls-files | tar -czf /tmp/newchain/seed/code/newchain.tar.gz -T -
      else
        # wait for newchain.tar.gz to be available
        sleep 20
        until [ -f /tmp/newchain/seed/code/newchain.tar.gz ]; do sleep 1; echo -n "."; done; echo
      fi
      sleep 20
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa /tmp/newchain/seed/code/newchain.tar.gz ubuntu@${aws_eip.seed[count.index].public_ip}:/tmp/newchain.tar.gz
    EOF
  }

  provisioner "remote-exec" {
    inline = [
      "echo building client on seed node...",
      "pkill newchaind",
      "rm -rf ~/newchain",
      "mkdir ~/newchain",
      "cd ~/newchain",
      "tar -xzf /tmp/newchain.tar.gz",
      "deploy/modules/validator/build-client.sh" # TODO: move this to script dir
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.seed[count.index].public_ip
    }
  }
}

resource "null_resource" "configure_seed" {
  depends_on = [null_resource.build_client[0], null_resource.build_client[1], null_resource.build_client[2]]
  count      = var.num_instances

  provisioner "remote-exec" {
    inline = [
      "echo configuring seed node",
      "pkill newchaind",
      "cd ~/newchain",
      "deploy/modules/seed/configure-seed.sh ${count.index} '${local.seed_ips_str}' '${local.validator_ips_str}'",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.seed[count.index].public_ip
    }
  }
}

resource "null_resource" "obtain_genesis_file" {
  depends_on = [null_resource.configure_seed[0], null_resource.configure_seed[1], null_resource.configure_seed[2]]
  count      = var.num_instances

  provisioner "local-exec" {
    command = <<-EOF
      if [[ "${count.index}" = "0" ]]; then
        # download genesis file from first validator to temporary file
        rm -rf /tmp/newchain/seed/genesis
        mkdir -p /tmp/newchain/seed/genesis
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ubuntu@${var.validator_ips[0]}:.newchain/config/genesis.json /tmp/newchain/seed/genesis/genesis.json
      else
        # wait for genesis.json to be available
        sleep 20
        until [ -f /tmp/newchain/seed/genesis/genesis.json ]; do sleep 1; echo -n "."; done; echo
      fi
      # upload genesis file from temporary file to seed node
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa /tmp/newchain/seed/genesis/genesis.json ubuntu@${aws_eip.seed[count.index].public_ip}:.newchain/config/genesis.json
    EOF
  }
}

resource "null_resource" "start_seed" {
  depends_on = [null_resource.obtain_genesis_file[0], null_resource.obtain_genesis_file[1], null_resource.obtain_genesis_file[2]]
  count      = var.num_instances

  provisioner "remote-exec" {
    inline = [
      "echo starting seed node",
      "cd ~/newchain",
      "deploy/modules/seed/start-seed.sh ${count.index}",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.seed[count.index].public_ip
    }
  }
}
