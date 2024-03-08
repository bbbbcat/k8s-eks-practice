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
