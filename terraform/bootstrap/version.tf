terraform {
  required_version = "1.14.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # ~> 6.0 means any version in the 6.x series, but not 7.0 or higher
    }
  }
}
