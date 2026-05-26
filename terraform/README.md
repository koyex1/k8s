#
terraform init -upgrade
#
terrafrom init -reconfigure 

#
rm -rf .terraform
rm .terraform.lock.hcl
terraform init


#
aws eks delete-nodegroup \
  --cluster-name eks-dev \
  --nodegroup-name eks-dev-baseline

terraform state rm \
module.eks.module.eks.module.eks_managed_node_group["baseline"].aws_eks_node_group.this[0]

terraform apply -auto-approve



#
terraform plan
terraform apply
terraform refresh #deprecated
terrafrom plan -refresh-only
terrafrom apply -refresh-only
terraform import


#
terraform fmt - identation, spaces, misaligned equals  signs
terraform validate - missing arguments, incorrect attr name, invalid ref to a resource that doesn't  exist
tflint - deprecated instance types, missing tags, improper for_each
checkov- SAST. alerts about publicly exposed s3 buckets, unencrypted RDS instances, overly permissive security group.


# note about service provider
you can either use kubernetes provider to create a service account. or you create one with the helm of that resource(karpenter, alb controller) by provider a value to the serviceAccount.name 
note a serviceaccount needs to bind a role to it. but since we are not dealing with k8s roles here but aws iam roles. then we will be binding aws iam roles to these service accounts.

# varialbe files are auto when
terraform.tfvars or *.auto.tfvars

# not auto for
dev.tfvars

name: DevOps Pipeline

on:
  pull_request: (pullrequest to main -> merge pull request to main -> push to main)
    branches: [main]   # Pre-merge CI (feature → main)
  push:
    branches: [main]   # Post-merge CI (after PR is merged)

jobs:

  #########################################
  # 🔍 PRE-MERGE CI (PR VALIDATION)
  #########################################

  pre-merge-checks:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        # Clone repo for validation

      - name: Setup runtime (Node/Python/etc)
        # Install required language runtime

      - name: Run unit + integration tests
        # Ensure application logic works

      - name: Lint code
        # Enforce code quality standards

      - name: Run SAST scan
        # Static security analysis (e.g., code vulnerabilities)

      - name: Dependency scan
        # Check for vulnerable packages

      - name: Terraform fmt
        # Ensure Terraform code formatting

      - name: Terraform validate
        # Validate Terraform syntax

      - name: Terraform lint (tflint)
        # Catch bad practices in Terraform

      - name: Terraform security scan (checkov)
        # Detect misconfigurations (open SG, etc.)

      - name: Terraform plan
        # Show infra changes (no apply)
        # Output posted to PR for review

      - name: Enforce branch protection
        # Block merge if any step fails


  #########################################
  # 🔐 POST-MERGE CI (MAIN BRANCH)
  #########################################

  build-and-publish:
    if: github.event_name == 'push'
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        # Pull latest merged code

      - name: Build application
        # Compile/package application

      - name: Build Docker image
        # Create container image

      - name: Scan image with Trivy
        # Fail if HIGH/CRITICAL vulnerabilities found

      - name: Generate SBOM (CycloneDX)
        # Produce software bill of materials

      - name: Tag image
        # Use immutable version (no 'latest')

      - name: Push image to registry
        # Push to ECR / Docker Hub / JFrog


  #########################################
  # 🏗️ TERRAFORM APPLY (CONTROLLED) 
  ##################################################################################
    ATLANTIS WILL ONLY DO TERRAFORM APPLY AND LEAVE THE OTHERS FOR PULL REQUEST STAGE
  ###################################################################################

  terraform-apply:
    if: github.event_name == 'push'
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        # Pull infra code

      - name: Setup Terraform
        # Install Terraform CLI

      - name: Terraform init
        # Initialize backend (S3 + DynamoDB)

      - name: Terraform plan
        # Reconfirm changes in main branch

      - name: Approval gate (manual)
        # Require human approval for production

      - name: Terraform apply
        # Apply infra changes (ONLY after approval)


  #########################################
  # ⚙️ DEPLOY VIA GITOPS (ARGOCD)
  #########################################

  deploy:
    if: github.event_name == 'push'
    runs-on: ubuntu-latest

    steps:
      - name: Update manifests / Helm values
        # Update image tag in Kubernetes manifests

      - name: Commit changes to GitOps repo
        # Push updated manifests (ArgoCD watches this repo)

      - name: ArgoCD sync
        # ArgoCD pulls changes and deploys to cluster

        #############################################################################
        #########################################
      # 🌱 SEEDING (ENV-SPECIFIC)
      #########################################

      - name: Run DB migrations
        # Always run (dev, staging, prod)
        # Handles schema changes only

      - name: Run seeding (DEV ONLY)
        # Condition: environment == dev
        # Insert dummy/test data
        # Example: users, products, mock records

      - name: Run seeding (STAGING ONLY)
        # Condition: environment == staging
        # Use sanitized or masked production-like data
        # Smaller dataset for testing

      - name: Skip seeding (PROD)
        # Production NEVER gets seeded
        # Only schema migrations allowed

      #########################################
      # ✅ VALIDATION AFTER SEEDING
      #########################################

      - name: Smoke tests
        # Validate APIs after seeding
    ##############################################################################

      - name: Health checks
        # Ensure pods are ready (readiness/liveness)

      - name: Auto rollback on failure
        # Revert deployment if health checks fail


  #########################################
  # 📊 OBSERVABILITY & ALERTING
  #########################################

  post-deploy-monitoring:
    if: github.event_name == 'push'
    runs-on: ubuntu-latest

    steps:
      - name: Emit deployment metrics
        # Send deploy event to Prometheus / Grafana

      - name: Monitor SLOs
        # Check latency, error rate, availability

      - name: Alert on failure
        # Trigger alerts if thresholds breached

      - name: Post-deploy validation window
        # Observe system for regression issues