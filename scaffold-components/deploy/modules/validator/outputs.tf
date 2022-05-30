output "ips" {
  depends_on = [null_resource.start_validator[0], null_resource.start_validator[1], null_resource.start_validator[2]]
  value      = [for i in range(0, var.num_instances) : aws_eip.validator[i].public_ip]
}
