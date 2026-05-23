resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

#iam roles are for 
#ekscluster
#eksnodegroup
#pods(controllers) that triggers the creation of aws loadbalancer via irserviceaccount
#pods that create aws nodes via karpenter via irserviceaccount
#pods that need to access aws resources via irserviceaccount
#thenodes created - profile & iam 
#bastion nodes - profile & iam

module "eks_cluster_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.3.0"

  name = "${var.cluster_name}-eks-cluster-role-${random_integer.suffix.result}"

  trust_policy_permissions = {
    EKSAssumeRole = {
      actions = [
        "sts:AssumeRole"
      ]

      principals = [{
        type = "Service"
        identifiers = [
          "eks.amazonaws.com"
        ]
      }]
    }
  }


  policies = {
    AmazonEKSClusterPolicy = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  }
}

module "eks_nodegroup_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.3.0"

  name = "${var.cluster_name}-nodegroup-role-${random_integer.suffix.result}"

  trust_policy_permissions = {
    EKSAssumeRole = {
      actions = [
        "sts:AssumeRole"
      ]

      principals = [{
        type = "Service"
        identifiers = [
          "ec2.amazonaws.com"
        ]
      }]
    }
  }


  policies = {
    WorkerNodePolicy = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    CNI              = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    ECR              = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    EBS              = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }
}

# OIDC (IRSA ENABLED) - ie use eks as identity provider through OIDC that pods can use to authenticate to AWS services - in our own case 
#ALB ingress controller pod will use this to authenticate to AWS and create ALB resources. 
# AWS Load Balancer Controller — a pod running inside your Kubernetes cluster that watches for Service or Ingress resources and creates AWS load balancers in response
module "oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-oidc-provider"
  version = "6.3.0"

  url = var.oidc_provider_url

  client_id_list = ["sts.amazonaws.com"]
}

# the iam policy attached to the alb_irsa module is the string "attach_load_balancer_controller_policy" which is a variable in the module that when set to true will attach the correct policy for the alb controller to work.
# irserviceaccount for alb controller not alb
module "alb_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.3.0"

  name = "${var.cluster_name}-alb-controller-${random_integer.suffix.result}"

  #since it is not attach_policies but attach_load_balancer_controller_policy, then you do have to create a policies object.
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"] #namepsace : serviceaccount
    }
  }
}

module "custom_irsa" {# example of pod using s3 is an ecommerce application that needs to list buckets and get bucket location to know where to store the images of the products.
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.3.0"

  name = "eks-custom-irsa-${random_integer.suffix.result}"

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["default:aws-test"] #namepsace : serviceaccount
    }
  }

  # role_policy_arns = {
  #   custom = aws_iam_policy.custom_policy.arn
  # }
  inline_policy_permissions = {
    s3_access = {
      sid = "S3Access"

      actions = [
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation"
      ]

      resources = ["*"]
    }
  }

}


# resource "aws_iam_policy" "custom_policy" {
#   name = "custom-irsa-policy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Action = [
#         "s3:ListAllMyBuckets",
#         "s3:GetBucketLocation"
#       ]
#       Resource = "*"
#     }]
#   })
# }

module "bastion_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.3.0"

  name = "${var.cluster_name}-bastion-role-${random_integer.suffix.result}"

  trust_policy_permissions = {
    EKSAssumeRole = {
      actions = [
        "sts:AssumeRole"
      ]

      principals = [{
        type = "Service"
        identifiers = [
          "ec2.amazonaws.com"
        ]
      }]
    }
  }
  policies = {
    SSM = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.cluster_name}-bastion-profile-${random_integer.suffix.result}"
  role = module.bastion_role.name
}

module "karpenter_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.3.0"

  name = "karpenter-${random_integer.suffix.result}"

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }

  inline_policy_permissions = {
    KarpenterController = {
      sid    = "KarpenterCorePermissions"
      effect = "Allow"

      actions = [
        # EC2 lifecycle
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:CreateFleet",

        # Instance discovery
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeImages",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeSpotPriceHistory",
        "ec2:DescribeInstanceTypeOfferings",

        # Tagging (CRITICAL for Karpenter)
        "ec2:CreateTags",
        "ec2:DeleteTags",

        # Networking
        "ec2:DescribeNetworkInterfaces",

        # Capacity / Spot
        "ec2:DescribeCapacityReservations",
        "ec2:DescribeCapacityReservationFleets",

        # Pricing (for decisions)
        "pricing:GetProducts",

        # IAM (instance profiles)
        "iam:PassRole"
      ]

      resources = ["*"]
    }

  }

}

module "karpenter_node_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.3.0"

  name = "karpenter-node-role-${random_integer.suffix.result}"

  trust_policy_permissions = {
    EKSAssumeRole = {
      actions = [
        "sts:AssumeRole"
      ]

      principals = [{
        type = "Service"
        identifiers = [
          "ec2.amazonaws.com"
        ]
      }]
    }
  }


  policies = {
    WorkerNodePolicy = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    CNI              = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    ECR              = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    SSM              = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "karpenter-instance-profile-${random_integer.suffix.result}"
  role = module.karpenter_node_role.name
}

# locals {
#   cluster_name = var.cluster_name
# }

# resource "random_integer" "random_suffix" {
#   min = 1000
#   max = 9999
# }

# resource "aws_iam_role" "eks-cluster-role" {
#   count = var.is_eks_role_enabled ? 1 : 0
#   name  = "${local.cluster_name}-role-${random_integer.random_suffix.result}"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "eks.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
#   count      = var.is_eks_role_enabled ? 1 : 0
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.eks-cluster-role[count.index].name
# }

# resource "aws_iam_role" "eks-nodegroup-role" {
#   count = var.is_eks_nodegroup_role_enabled ? 1 : 0
#   name  = "${local.cluster_name}-nodegroup-role-${random_integer.random_suffix.result}"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "eks-AmazonWorkerNodePolicy" {
#   count      = var.is_eks_nodegroup_role_enabled ? 1 : 0
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.eks-nodegroup-role[count.index].name
# }

# resource "aws_iam_role_policy_attachment" "eks-AmazonEKS_CNI_Policy" {
#   count      = var.is_eks_nodegroup_role_enabled ? 1 : 0
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.eks-nodegroup-role[count.index].name
# }
# resource "aws_iam_role_policy_attachment" "eks-AmazonEC2ContainerRegistryReadOnly" {
#   count      = var.is_eks_nodegroup_role_enabled ? 1 : 0
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.eks-nodegroup-role[count.index].name
# }

# resource "aws_iam_role_policy_attachment" "eks-AmazonEBSCSIDriverPolicy" {
#   count      = var.is_eks_nodegroup_role_enabled ? 1 : 0
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
#   role       = aws_iam_role.eks-nodegroup-role[count.index].name
# }

# # ALB Controller Attach Policy

# resource "aws_iam_role_policy_attachment" "alb-controller-policy-attach" {
#   count      = var.is_alb_controller_enabled ? 1 : 0
#   policy_arn = aws_iam_policy.alb_controller_policy.arn
#   role       = aws_iam_role.alb_controller_role[count.index].name
# }



# # OIDC
# data "aws_iam_policy_document" "eks_oidc_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
#       values   = ["system:serviceaccount:default:aws-test"]
#     }

#     principals {
#       identifiers = [var.oidc_provider_arn]
#       type        = "Federated"
#     }
#   }
# }

# resource "aws_iam_role" "eks_oidc" {
#   assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role_policy.json
#   name               = "eks-oidc"
# }

# resource "aws_iam_policy" "eks-oidc-policy" {
#   name = "test-policy"

#   policy = jsonencode({
#     Statement = [{
#       Action = [
#         "s3:ListAllMyBuckets",
#         "s3:GetBucketLocation",
#         "*"
#       ]
#       Effect   = "Allow"
#       Resource = "*"
#     }]
#     Version = "2012-10-17"
#   })
# }




# # Bastion IAM Role
# resource "aws_iam_role" "bastion_role" {
#   name = "${local.cluster_name}-bastion-role-${random_integer.random_suffix.result}"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
# }



# resource "aws_iam_role_policy_attachment" "bastion_admin_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
#   role       = aws_iam_role.bastion_role.name
# }

# resource "aws_iam_instance_profile" "bastion_profile" {
#   name = "${local.cluster_name}-bastion-profile-${random_integer.random_suffix.result}"
#   role = aws_iam_role.bastion_role.name
# }

####################################
# https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html

# data "aws_iam_policy_document" "alb_controller_trust_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
#       values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
#     }

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
#       values   = ["sts.amazonaws.com"]
#     }

#     principals {
#       identifiers = [var.oidc_provider_arn]
#       type        = "Federated"
#     }
#   }
# }

# resource "aws_iam_role" "alb_controller_role" {
#   count              = var.is_alb_controller_enabled ? 1 : 0
#   name               = "${local.cluster_name}-alb-controller-role-${random_integer.random_suffix.result}"
#   assume_role_policy = data.aws_iam_policy_document.alb_controller_trust_policy.json
# }

# resource "aws_iam_policy" "alb_controller_policy" {
#   name        = "alb-controller-policy"
#   description = "IAM policy for AWS Load Balancer Controller"

#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "iam:CreateServiceLinkedRole"
#         ],
#         "Resource" : "*",
#         "Condition" : {
#           "StringEquals" : {
#             "iam:AWSServiceName" : "elasticloadbalancing.amazonaws.com"
#           }
#         }
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "ec2:DescribeAccountAttributes",
#           "ec2:DescribeAddresses",
#           "ec2:DescribeAvailabilityZones",
#           "ec2:DescribeInternetGateways",
#           "ec2:DescribeVpcs",
#           "ec2:DescribeVpcPeeringConnections",
#           "ec2:DescribeSubnets",
#           "ec2:DescribeSecurityGroups",
#           "ec2:DescribeInstances",
#           "ec2:DescribeNetworkInterfaces",
#           "ec2:DescribeTags",
#           "ec2:GetCoipPoolUsage",
#           "ec2:DescribeCoipPools",
#           "ec2:GetSecurityGroupsForVpc",
#           "ec2:DescribeIpamPools",
#           "ec2:DescribeRouteTables",
#           "elasticloadbalancing:DescribeLoadBalancers",
#           "elasticloadbalancing:DescribeLoadBalancerAttributes",
#           "elasticloadbalancing:DescribeListeners",
#           "elasticloadbalancing:DescribeListenerCertificates",
#           "elasticloadbalancing:DescribeSSLPolicies",
#           "elasticloadbalancing:DescribeRules",
#           "elasticloadbalancing:DescribeTargetGroups",
#           "elasticloadbalancing:DescribeTargetGroupAttributes",
#           "elasticloadbalancing:DescribeTargetHealth",
#           "elasticloadbalancing:DescribeTags",
#           "elasticloadbalancing:DescribeTrustStores",
#           "elasticloadbalancing:DescribeListenerAttributes",
#           "elasticloadbalancing:DescribeCapacityReservation"
#         ],
#         "Resource" : "*"
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "cognito-idp:DescribeUserPoolClient",
#           "acm:ListCertificates",
#           "acm:DescribeCertificate",
#           "iam:ListServerCertificates",
#           "iam:GetServerCertificate",
#           "waf-regional:GetWebACL",
#           "waf-regional:GetWebACLForResource",
#           "waf-regional:AssociateWebACL",
#           "waf-regional:DisassociateWebACL",
#           "wafv2:GetWebACL",
#           "wafv2:GetWebACLForResource",
#           "wafv2:AssociateWebACL",
#           "wafv2:DisassociateWebACL",
#           "shield:GetSubscriptionState",
#           "shield:DescribeProtection",
#           "shield:CreateProtection",
#           "shield:DeleteProtection"
#         ],
#         "Resource" : "*"
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "ec2:AuthorizeSecurityGroupIngress",
#           "ec2:RevokeSecurityGroupIngress"
#         ],
#         "Resource" : "*"
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "ec2:CreateSecurityGroup"
#         ],
#         "Resource" : "*"
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "ec2:CreateTags"
#         ],
#         "Resource" : "arn:aws:ec2:*:*:security-group/*",
#         "Condition" : {
#           "StringEquals" : {
#             "ec2:CreateAction" : "CreateSecurityGroup"
#           },
#           "Null" : {
#             "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
#           }
#         }
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "ec2:CreateTags",
#           "ec2:DeleteTags"
#         ],
#         "Resource" : "arn:aws:ec2:*:*:security-group/*",
#         "Condition" : {
#           "Null" : {
#             "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
#             "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
#           }
#         }
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "ec2:AuthorizeSecurityGroupIngress",
#           "ec2:RevokeSecurityGroupIngress",
#           "ec2:DeleteSecurityGroup"
#         ],
#         "Resource" : "*",
#         "Condition" : {
#           "Null" : {
#             "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
#           }
#         }
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "elasticloadbalancing:CreateLoadBalancer",
#           "elasticloadbalancing:CreateTargetGroup"
#         ],
#         "Resource" : "*",
#         "Condition" : {
#           "Null" : {
#             "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
#           }
#         }
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "elasticloadbalancing:CreateListener",
#           "elasticloadbalancing:DeleteListener",
#           "elasticloadbalancing:CreateRule",
#           "elasticloadbalancing:DeleteRule"
#         ],
#         "Resource" : "*"
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "elasticloadbalancing:AddTags",
#           "elasticloadbalancing:RemoveTags"
#         ],
#         "Resource" : [
#           "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
#           "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
#           "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
#         ],
#         "Condition" : {
#           "Null" : {
#             "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
#             "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
#           }
#         }
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "elasticloadbalancing:AddTags",
#           "elasticloadbalancing:RemoveTags"
#         ],
#         "Resource" : [
#           "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
#           "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
#           "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
#           "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
#         ]
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "elasticloadbalancing:ModifyLoadBalancerAttributes",
#           "elasticloadbalancing:SetIpAddressType",
#           "elasticloadbalancing:SetSecurityGroups",
#           "elasticloadbalancing:SetSubnets",
#           "elasticloadbalancing:DeleteLoadBalancer",
#           "elasticloadbalancing:ModifyTargetGroup",
#           "elasticloadbalancing:ModifyTargetGroupAttributes",
#           "elasticloadbalancing:DeleteTargetGroup",
#           "elasticloadbalancing:ModifyListenerAttributes",
#           "elasticloadbalancing:ModifyCapacityReservation",
#           "elasticloadbalancing:ModifyIpPools"
#         ],
#         "Resource" : "*",
#         "Condition" : {
#           "Null" : {
#             "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
#           }
#         }
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "elasticloadbalancing:AddTags"
#         ],
#         "Resource" : [
#           "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
#           "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
#           "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
#         ],
#         "Condition" : {
#           "StringEquals" : {
#             "elasticloadbalancing:CreateAction" : [
#               "CreateTargetGroup",
#               "CreateLoadBalancer"
#             ]
#           },
#           "Null" : {
#             "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
#           }
#         }
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "elasticloadbalancing:RegisterTargets",
#           "elasticloadbalancing:DeregisterTargets"
#         ],
#         "Resource" : "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "elasticloadbalancing:SetWebAcl",
#           "elasticloadbalancing:ModifyListener",
#           "elasticloadbalancing:AddListenerCertificates",
#           "elasticloadbalancing:RemoveListenerCertificates",
#           "elasticloadbalancing:ModifyRule",
#           "elasticloadbalancing:SetRulePriorities"
#         ],
#         "Resource" : "*"
#       }
#     ]
#   })
# }
