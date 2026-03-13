
# creating subdomain api.millstack.in pointing to provisioned alb
# for having a fix custom domain, instead of new DNS names for every new alb provision
resource "aws_route53_record" "api_dns" {
  zone_id = var.route53_hosted_zone_id
  name    = var.subdomain_api
  type    = "A"

  alias {
    name = module.alb.alb_dns_name
    zone_id = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}