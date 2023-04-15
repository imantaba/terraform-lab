# By default this module will provision new Elastic IPs for the VPC's NAT Gateways. This means that when creating a new VPC, new IPs are allocated, 
# and when that VPC is destroyed those IPs are released. Sometimes it is handy to keep the same IPs even after the VPC is destroyed and re-created. 
# To that end, it is possible to assign existing IPs to the NAT Gateways. This prevents the destruction of the VPC from releasing those IPs,
#  while making it possible that a re-created VPC uses the same IPs.

resource "aws_eip" "nat" {
  count = 3
  vpc = true
}


module "vpc" {
  source = "./modules/vpc"

  name = "lab-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway  = true
  # enable_vpn_gateway  = true
  single_nat_gateway  = false
  reuse_nat_ips       = true             # <= Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids = aws_eip.nat.*.id # <= IPs specified here as input to the module


  tags = local.tags
}


