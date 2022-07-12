provider "aws" {
  region = var.region
}

//noinspection MissingModule
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "11.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["11.0.1.0/24", "11.0.2.0/24", "11.0.3.0/24"]
  public_subnets  = ["11.0.101.0/24", "11.0.102.0/24", "11.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }


}

module "security_group" {
  source = "../services/modules/security_group"
  vpc_id = module.vpc.vpc_id
}

module "alb" {
  source            = "../services/modules/alb"
  vpc_id            = module.vpc.vpc_id
#  private_subnets   = module.vpc.private_subnets
  public_subnets    = module.vpc.public_subnets
  security_group_id = module.security_group.public_security_group_id
}
module "iam" {
  source = "../services/modules/iam"
}

module "asg" {
  source               = "../services/modules/asg"
  security_groups      = module.security_group.public_security_group_id
  iam_instance_profile = module.iam.iam_instance_profile
  vpc_zone_identifier  = module.vpc.public_subnets
  target_group_arns    = [module.alb.target_group_arn]
}

