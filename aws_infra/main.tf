module "backend" {
  source       = "./modules/backend"
  project      = var.project
  api_domain   = var.api_domain
  dynamodb_arn = module.database.dynamodb_arn
}

module "database" {
  source  = "./modules/database"
  project = var.project
}

module "domain" {
  source                    = "./modules/domain"
  project                   = var.project
  domain                    = var.domain
  api_domain                = var.api_domain
  cloudfront_domain         = module.frontend.cloudfront_domain
  cloudfront_hosted_zone_id = module.frontend.cloudfront_hosted_zone_id
  region                    = var.region
  zone_id                   = var.zone_id
}

module "frontend" {
  source              = "./modules/frontend"
  project             = var.project
  domain              = var.domain
  acm_certificate_arn = module.domain.acm_certificate_arn
}
