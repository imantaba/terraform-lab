module "asg" {
  source  = "./modules/asg"

  # Autoscaling group
  name = "lab-asg"

  min_size                  = 1
  max_size                  = 4
  desired_capacity          = 2
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = module.vpc.private_subnets


  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      checkpoint_delay       = 600
      checkpoint_percentages = [35, 70, 100]
      instance_warmup        = 300
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }
  
  target_group_arns = module.alb.target_group_arns

  # Launch template
  launch_template_name        = "lab-asg-lt"
  launch_template_description = "lab Launch template"
  update_default_version      = true

  image_id          = "ami-0d1ddd83282187d18"
  instance_type     = "t2.micro"
  key_name          = "lab" 
  enable_monitoring = true
  instance_name     = "lab-instance"

  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = "lab-asg"
  iam_role_path               = "/ec2/"
  iam_role_description        = "lab IAM role"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # block_device_mappings = [
  #   {
  #     # Root volume
  #     device_name = "/dev/xvda"
  #     no_device   = 0
  #     ebs = {
  #       delete_on_termination = true
  #       encrypted             = true
  #       volume_size           = 20
  #       volume_type           = "gp2"
  #     }
  #   }, {
  #     device_name = "/dev/sda1"
  #     no_device   = 1
  #     ebs = {
  #       delete_on_termination = true
  #       encrypted             = true
  #       volume_size           = 30
  #       volume_type           = "gp2"
  #     }
  #   }
  # ]

  # network_interfaces = [
  #   {
  #     delete_on_termination = true
  #     description           = "eth0"
  #     device_index          = 0
  #     security_groups       = [module.asg_instance_sg.security_group_id]
  #   },
  #   {
  #     delete_on_termination = true
  #     description           = "eth1"
  #     device_index          = 1
  #     security_groups       = [module.asg_instance_sg.security_group_id]
  #   }
  # ]


  tags = local.tags

  depends_on = [
    module.alb.target_group_arns,
  ]
}