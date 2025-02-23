locals {
  domain    = "resource-map.com"
  endpoints = ["production", "reserves", "gov_info", "prices", "balance"]
  project   = "resource-map"
  zone_id   = "Z04452601SK9K5QDAF5YG"

  common_tags = {
    Author      = "Max Ebert"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Repository  = "https://github.com/MaxE99/resource-map-backend/"
    Project     = "resource-map"
  }
}

module "frontend_domain" {
  source = "./modules/domain"

  domain  = local.domain
  tags    = local.common_tags
  zone_id = local.zone_id
}

module "backend_domain" {
  source = "./modules/domain"


  domain                    = "api.${local.domain}"
  enable_api_gateway_domain = true
  tags                      = local.common_tags
  zone_id                   = local.zone_id
}

module "website_bucket" {
  source = "./modules/bucket"

  bucket_name = "resource-map.com-website"
  cloudfront_args = {
    acm_certificate_arn = module.frontend_domain.acm_certificate_arn
    domain              = local.domain
    zone_id             = local.zone_id
  }
  tags = local.common_tags
}

module "media_bucket" {
  source = "./modules/bucket"

  bucket_name = "resource-map.com-media"
  is_media    = true
  tags        = local.common_tags
}

module "api_gateway" {
  source = "./modules/api_gateway"

  domain  = "api.${local.domain}"
  project = local.project
  tags    = local.common_tags
}

module "database" {
  source = "./modules/database"

  tags = local.common_tags
}

module "lambda_endpoints" {
  source = "./modules/endpoint"
  count  = 5

  api_gateway_details  = module.api_gateway.api_gateway_details
  domain               = local.domain
  dynamodb_access_role = module.database.dynamodb_access_role
  path                 = element(local.endpoints, count.index)
  project              = local.project
  tags                 = local.common_tags
}

module "ci_cd_pipeline" {
  source = "./modules/ci_cd_pipeline"

  cloudfront_arn      = module.website_bucket.cloudfront_arn
  github_repository   = "repo:MaxE99/resource-map-frontend:*"
  project             = local.project 
  s3_bucket_arn       = module.website_bucket.s3_bucket_arn
  tags                = local.common_tags
}