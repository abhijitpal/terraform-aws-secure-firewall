# Copyright (c) 2022 Cisco Systems, Inc. and its affiliates
# All rights reserved.
# # ##################################################################################################################################
# # # Create the Cisco FMC and FTD Instances
# # ##################################################################################################################################

#Ignoring IMDSv2 check temporarily as it is not currently supported on the available Cisco FTDv marketplace version.
#The support will be available soon on the marketplace version
#tfsec:ignore:aws-ec2-enforce-http-token-imds
resource "aws_instance" "ftdv" {
  count         = var.instances_per_az * var.availability_zone_count
  ami           = data.aws_ami.ftdv.id
  instance_type = var.ftd_size
  key_name      = var.keyname
  
  root_block_device {
      encrypted = var.block_encrypt
  }
    
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 52
    volume_type = "gp2"
    delete_on_termination = true
    encrypted = var.block_encrypt
  }

  network_interface {
    network_interface_id = element(var.ftd_mgmt_interface, count.index)
    device_index         = 0
  }
  network_interface {
    network_interface_id = element(var.ftd_diag_interface, count.index)
    device_index         = 1
  }
  network_interface {
    network_interface_id = element(var.ftd_outside_interface, count.index)
    device_index         = 2
  }
  network_interface {
    network_interface_id = element(var.ftd_inside_interface, count.index)
    device_index         = 3
  }
  user_data = data.template_file.ftd_startup_file[count.index].rendered
  tags = merge({
    Name = "Cisco ftdv${count.index}"
  }, var.tags)
}

resource "aws_instance" "fmcv" {
  count         = var.create_fmc ? 1 : 0
  ami           = data.aws_ami.fmcv[0].id
  instance_type = "c5.4xlarge"
  key_name = var.keyname
  network_interface {
    network_interface_id = var.fmcmgmt_interface
    device_index         = 0
  }
  user_data = data.template_file.fmc_startup_file[0].rendered
  tags = {
    Name = "Cisco FMCv"
  }
}
