package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExamplesApplication(t *testing.T) {

	// Provisioning a Load Balancer is slow; CI runs only the "basic" example.
	// This L7 example self-skips unless TERRATEST_RUN_ALL is set. Run it locally with:
	//   TERRATEST_RUN_ALL=1 go test -v -timeout 45m ./...
	if os.Getenv("TERRATEST_RUN_ALL") == "" {
		t.Skip("skipping long-running example in CI; set TERRATEST_RUN_ALL=1 to run")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/application",
		// See TestExamplesBasic: driven with `tofu` so the OpenTofu-Registry module
		// sources resolve while the Terraform Registry is unavailable for this org.
		TerraformBinary: "tofu",
		Vars: map[string]interface{}{
			"project_id": os.Getenv("STACKIT_PROJECT_ID"),
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}
