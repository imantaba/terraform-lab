
# module "monitoring" {
#   source        = "./modules/helm_generic"
#   namespace_name = "monitoring"
#   create_namespace = true

#   chart_version                          = "46.5.0"

#   # find chart values from below code
#   # https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler#aws---using-auto-discovery-of-tagged-instance-groups
  
#   additional_set = [
#     {
#       name  = "autoDiscovery.clusterName"
#       value = module.eks.cluster_name
#     },
#     {
#       name  = "awsRegion"
#       value = local.aws_region
#     },
#     {
#       name  = "rbac.serviceAccount.name"
#       value = "cluster-autoscaler"
#     },
#     {
#       name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#       value = module.cluster_autoscaler_irsa_role.iam_role_arn
#     }
#   ]
# }


# module "kube_prometheus_stack_irsa_role" {
#   source = "./modules/iam/modules/iam-role-for-service-accounts-eks"

#   role_name      = "KUBE-PROMETHEUS-STACK-IRSA"

#   role_policy_arns = {
#     policy = aws_iam_policy.kube_prometheus_stack_policy.arn
#   }
#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["monitoring:cluster-autoscaler"]
#     }
#   }

#   tags = local.tags
# }


# resource "aws_iam_policy" "kube_prometheus_stack_policy" {
#   name        = "Kube_Prometheus_Stack_Policy"
#   path        = "/"
#   description = "Policy, which allows kube_prometheus_stack to Get metrics"

#   policy = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Action": [
#                 "logs:Describe*",
#                 "logs:Get*",
#                 "logs:List*",
#                 "logs:StartQuery",
#                 "logs:StopQuery",
#                 "logs:TestMetricFilter",
#                 "logs:FilterLogEvents",
#                 "cloudwatch:ListMetrics",
#                 "cloudwatch:GetMetricData",
#                 "cloudwatch:GetMetricStatistics",
#                 "cloudwatch:DescribeAlarmHistory",
#                 "cloudwatch:DescribeAlarms"
#             ],
#             "Effect": "Allow",
#             "Resource": "*"
#         }
#     ]
# })
# }