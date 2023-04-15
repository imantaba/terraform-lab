module "acm" {
  source  = "./modules/acm"

  domain_name  = "lab.avidcloud.io"
  zone_id      = "Z1OAW8ALR2XBLJ"

  # subject_alternative_names = [
  #   "*.my-domain.com",
  #   "app.sub.my-domain.com",
  # ]

  wait_for_validation = true

  tags = {
    Name = "lab.avidcloud.io"
  }
}


module "alb" {
  source  = "./modules/alb"

  name = "lab-alb"

  load_balancer_type = "application"

  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.alb_sg.security_group_id]

  # access_logs = {
  #   bucket = "lab-alb-logs"
  # }

  target_groups = [
    {
      name_prefix      = "tg-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]

  https_listeners = [
    {
      port                 = 443
      protocol             = "HTTPS"
      certificate_arn      = module.acm.acm_certificate_arn
      target_group_index   = 0
    }
  ]


  tags = {
    Environment = "Test"
  }
}

