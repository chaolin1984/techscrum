terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

//shared aws account need to add shared_credentials_file and profile if you use multi aws account
provider "aws" {
  # shared_credentials_file = "~/.aws/credentials"
  # profile                 = "secondaccount"
  region                  = var.aws_region
}

terraform {
  backend "s3" {
    //if you use multi aws account, add sahred-credentials_file and profile
    # shared_credentials_file = "~/.aws/credentials"
    # profile                 = "secondaccount"
    bucket                  = "techscrum-tfstate-bucket"
    key                     = "backend-tfstate/terraform.tfstate"
    region                  = "ap-southeast-2"

    # Enable during Step-09     
    # For State Locking
    dynamodb_table = "techscrum-lock-table"
  }
}
module "ses" {
  source = "./modules/ses" // path to your module
}

module "s3" {
  source      = "./modules/s3" // path to your module
  bucket_name = var.bucket_name
}

module "ecr_repository" {
  source            = "./modules/ecr_repository" // path to your module
  app_name          = var.app_name
  ecr_images_number = var.ecr_images_number
}

module "vpc" {
  source               = "./modules/vpc" // path to your module
  vpc_cidr_block_uat   = var.vpc_cidr_block_uat
  vpc_cidr_block_prod  = var.vpc_cidr_block_prod
  public_subnets_uat   = var.public_subnets_uat
  public_subnets_prod  = var.public_subnets_prod
  private_subnets_prod = var.private_subnets_prod
  aws_region           = var.aws_region
  availability_zones   = var.availability_zones
  app_name             = var.app_name
  app_environment_uat  = var.app_environment_uat
  app_environment_prod = var.app_environment_prod
}

module "sg" {
  source               = "./modules/sg" // path to your module
  uat_vpc_id           = module.vpc.uat_vpc_id
  prod_vpc_id          = module.vpc.prod_vpc_id
  app_name             = var.app_name
  port                 = var.port
  app_environment_uat  = var.app_environment_uat
  app_environment_prod = var.app_environment_prod
}

module "ACM" {
  source      = "./modules/ACM" // path to your module  
  domain_name = var.domain_name
}

module "alb" {
  source                 = "./modules/alb" // path to your module
  prod_vpc_id            = module.vpc.prod_vpc_id
  app_name               = var.app_name
  app_environment_uat    = var.app_environment_uat
  app_environment_prod   = var.app_environment_prod
  health_check_path      = var.health_check_path
  alb_sg_id              = module.sg.alb_sg_id
  prod_public_subnet_ids = module.vpc.prod_public_subnet_ids
  domain_name            = var.domain_name
  backend_bucket         = module.s3.backend_bucket
  certificate_arn        = module.ACM.certificate_arn
}

module "route53" {
  source       = "./modules/route53"
  domain_name  = var.domain_name
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}

module "ecs" {
  source                  = "./modules/ecs"
  app_name                = var.app_name
  app_environment_uat     = var.app_environment_uat
  app_environment_prod    = var.app_environment_prod
  uat_public_subnet_ids   = module.vpc.uat_public_subnet_ids
  prod_private_subnet_ids = module.vpc.prod_private_subnet_ids
  task_desired_count      = var.task_desired_count
  task_min_count          = var.task_min_count
  task_max_count          = var.task_max_count
  port                    = var.port
  uat_service_sg_id       = module.sg.uat_service_sg_id
  prod_service_sg_id      = module.sg.prod_service_sg_id
  repository_url          = module.ecr_repository.repository_url
  listener_arn            = module.alb.listener_arn
  tg_prod_arn             = module.alb.tg_prod_arn
}

module "cloudwatch" {
  source               = "./modules/cloudwatch"
  app_name             = var.app_name
  app_environment_uat  = var.app_environment_uat
  app_environment_prod = var.app_environment_prod
  sns_email            = var.sns_email
  alb_arn_suffix       = module.alb.alb_arn_suffix
}