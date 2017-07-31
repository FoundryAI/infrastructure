# Foundry.ai Infrastructure

[terraform]: https://terraform.io

This repository hosts as a set of [Terraform][terraform] to be used in Foundry.ai projects. To use:


```hcl
module "api" {
  source      = "github.com/FoundryAI/infrastructure"
  environment = "production"
  key_name    = "my-key-name"
  name        = "my-app"
}
```  

Note: Docs still a work in progress.