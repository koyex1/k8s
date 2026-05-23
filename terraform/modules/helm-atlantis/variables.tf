variable "region" {}

variable "repo_allowlist" {
  description = "GitHub repos Atlantis can access"
}

variable "github_user" {}
variable "github_token" {}
variable "github_webhook_secret" {}

variable "terraform_version" {}

variable "atlantis_url" {}

variable "alb_dependency" {
  description = "Dependency on ALB controller"
}
