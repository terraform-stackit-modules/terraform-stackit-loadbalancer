package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExamplesBasic(t *testing.T) {

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/basic",
		// This example references the published terraform-stackit-modules/{network,compute}
		// modules, which are on the OpenTofu Registry (the Terraform Registry is temporarily
		// unavailable for this org). Drive the run with `tofu` so those sources resolve.
		TerraformBinary: "tofu",
		Vars: map[string]interface{}{
			"project_id": os.Getenv("STACKIT_PROJECT_ID"),
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}
