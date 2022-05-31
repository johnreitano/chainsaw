resource "aws_instance" "validator" {
  count                       = var.num_instances
  ami                         = var.ami
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.validator.id
  key_name                    = "newchain-key"
  vpc_security_group_ids      = [aws_security_group.validator.id]
  associate_public_ip_address = false

  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-validator-${count.index}"
  }

}
resource "aws_eip" "validator" {
  depends_on = [aws_instance.validator[0], aws_instance.validator[1], aws_instance.validator[2]]
  count      = var.num_instances
  instance   = aws_instance.validator[count.index].id
  vpc        = true
  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-validator-eip-${count.index}"
  }
}

locals {
  depends_on        = [aws_eip.validator[0], aws_eip.validator[1], aws_eip.validator[2]]
  validator_ips_str = join(",", [for node in aws_eip.validator : node.public_ip])
}

resource "null_resource" "build_client" {
  depends_on = [aws_eip.validator[0], aws_eip.validator[1], aws_eip.validator[2], aws_security_group.validator]
  count      = var.num_instances

  provisioner "local-exec" {
    command = <<-EOF
      if [[ "${count.index}" = "0" ]]; then
        rm -rf /tmp/newchain/validator/code
        mkdir -p /tmp/newchain/validator/code
        cd ..
        git ls-files | tar -czf /tmp/newchain/validator/code/newchain.tar.gz -T -
      else
        # wait for newchain.tar.gz to be available
        sleep 20
        until [ -f /tmp/newchain/validator/code/newchain.tar.gz ]; do sleep 1; echo -n "."; done; echo
      fi      
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa /tmp/newchain/validator/code/newchain.tar.gz ubuntu@${aws_eip.validator[count.index].public_ip}:/tmp/newchain.tar.gz
    EOF
  }

  provisioner "remote-exec" {
    inline = [
      "echo building client on validator node...",
      "pkill newchaind",
      "rm -rf ~/newchain",
      "mkdir ~/newchain",
      "cd ~/newchain",
      "tar -xzf /tmp/newchain.tar.gz",
      "deploy/modules/validator/build-client.sh"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index].public_ip
    }
  }
}

resource "null_resource" "configure_validator_and_generate_gentx" {
  depends_on = [null_resource.build_client[0], null_resource.build_client[1], null_resource.build_client[2], aws_security_group.validator]
  count      = var.num_instances

  provisioner "remote-exec" {
    inline = [
      "echo configuring validator and generating gentx...",
      "cd ~/newchain",
      "deploy/modules/validator/configure-validator.sh ${count.index} '${local.validator_ips_str}'",
      "deploy/modules/validator/generate-gentx.sh ${count.index}",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index].public_ip
    }
  }

  # copy gentxs to first validator node from other secondary validator nodes
  provisioner "local-exec" {
    command = <<-EOF
      if [[ "${count.index}" != "0" ]]; then
        rm -rf /tmp/newchain/validator/gentx
        mkdir -p /tmp/newchain/validator/gentx
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ubuntu@${aws_eip.validator[count.index].public_ip}:.newchain/config/gentx/* /tmp/newchain/validator/gentx/
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa /tmp/newchain/validator/gentx/* ubuntu@${aws_eip.validator[0].public_ip}:.newchain/config/gentx/
      fi
      EOF
  }
}

resource "null_resource" "obtain_genesis_file" {
  depends_on = [null_resource.configure_validator_and_generate_gentx[0], null_resource.configure_validator_and_generate_gentx[1], null_resource.configure_validator_and_generate_gentx[2]]
  count      = var.num_instances

  provisioner "remote-exec" {
    inline = count.index == 0 ? [
      "echo generating genesis file on first validator node",
      "cd ~/newchain",
      "deploy/modules/validator/generate-genesis-file.sh",
      ] : [
      ":"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[0].public_ip
    }
  }

  provisioner "local-exec" {
    command = <<-EOF
      if [[ "${count.index}" = "0" ]]; then
        # download genesis file from first validator to temporary file
        rm -rf /tmp/newchain/validator/genesis
        mkdir -p /tmp/newchain/validator/genesis
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ubuntu@${aws_eip.validator[0].public_ip}:.newchain/config/genesis.json /tmp/newchain/validator/genesis/genesis.json
      else
        # wait for genesis.json to be available
        sleep 20
        until [ -f /tmp/newchain/validator/genesis/genesis.json ]; do sleep 1; echo -n "."; done; echo # wait for genesis file to be available

        # upload genesis file from temporary file to secondary validator
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa /tmp/newchain/validator/genesis/genesis.json ubuntu@${aws_eip.validator[count.index].public_ip}:.newchain/config/genesis.json
      fi      
    EOF
  }
}

resource "null_resource" "start_validator" {
  depends_on = [null_resource.obtain_genesis_file[0], null_resource.obtain_genesis_file[1], null_resource.obtain_genesis_file[2]]
  count      = var.num_instances

  provisioner "remote-exec" {
    inline = [
      "echo starting validator node",
      "cd ~/newchain",
      "deploy/modules/validator/start-validator.sh ${count.index}",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index].public_ip
    }
  }
}
