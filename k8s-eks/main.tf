provider "aws" {
  region = local.region
}
provider "kubernetes" {
  host                   = module.keks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}
locals {
  region = "us-west-2"
}
