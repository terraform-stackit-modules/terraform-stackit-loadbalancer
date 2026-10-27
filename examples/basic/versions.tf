terraform {
  required_version = ">= 1.3"

  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.113.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}
