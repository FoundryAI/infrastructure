/**
 * The bastion host acts as the "jump point" for the rest of the infrastructure.
 * Since most of our instances aren't exposed to the external internet, the bastion acts as the gatekeeper for any direct SSH access.
 * The bastion is provisioned using the key name that you pass to the stack (and hopefully have stored somewhere).
 * If you ever need to access an instance directly, you can do it by "jumping through" the bastion.
 *
 *    $ terraform output # print the bastion ip
 *    $ ssh -i <path/to/key> ubuntu@<bastion-ip> ssh ubuntu@<internal-ip>
 *
 * Usage:
 *
 *    module "bastion" {
 *      source            = "stack/bastion"
 *      region            = "us-west-2"
 *      security_groups   = "sg-1,sg-2"
 *      vpc_id            = "vpc-12"
 *      key_name          = "ssh-key"
 *      subnet_id         = "pub-1"
 *      environment       = "prod"
 *    }
 *
 */

variable "instance_type" {
  default = "t2.micro"
  description = "Instance type, see a list at: https://aws.amazon.com/ec2/instance-types/"
}

variable "region" {
  description = "AWS Region, e.g us-west-2"
}

variable "security_groups" {
  description = "a comma separated lists of security group IDs"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "key_name" {
  description = "The SSH key pair, key name"
}

variable "subnet_id" {
  description = "A external subnet id"
}

variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "zone_id" {
  description = "DNS Zone"
}

data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}

resource "aws_instance" "bastion" {
  ami = "${data.aws_ami.ubuntu.id}"
  source_dest_check = false
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  subnet_id = "${var.subnet_id}"
  vpc_security_group_ids = ["${split(",",var.security_groups)}"]
  monitoring = true
  user_data = "${file(format("%s/user_data.sh", path.module))}"

  tags {
    Name = "bastion"
    Environment = "${var.environment}"
  }
}

resource "aws_eip" "bastion" {
  instance = "${aws_instance.bastion.id}"
  vpc = true
}

resource "aws_route53_record" "bastion" {
  name = "${var.environment}-bastion"
  type = "A"
  zone_id = "${var.zone_id}"
  ttl = 300
  records = ["${aws_eip.bastion.public_ip}"]
}

// Bastion external IP address.
output "external_ip" {
  value = "${aws_eip.bastion.public_ip}"
}

output "external_domain" {
  value = "${aws_route53_record.bastion.fqdn}"
}
