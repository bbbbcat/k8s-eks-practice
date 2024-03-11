provider "aws" {
  region = local.region
}
provider "kubernetes" {
  host                   = module.keks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}
data "aws_availability_zones" "available" {
  state = "available"
}
locals {
  region   = "us-west-2"
  name     = basename(path.cwd)
  vpc_cidr = "10.1.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  tags = {
    Cluster = local.name
  }
}
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.0"

  cluster_name                   = local.name
  cluster_version                = "1.28"
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default_node_group = {
      instance_types = ["t3.small"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }
  tags = local.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name            = local.name
  cidr            = local.vpc_cidr
  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}
