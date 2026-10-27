# Agent Guidelines

This file provides context and instructions for AI coding agents (Copilot, Cursor, Codex, etc.) working on this repository.

## Project context

This is a Terraform module for [STACKIT](https://www.stackit.de/en/), the cloud platform by Schwarz Group.
It is part of the [terraform-stackit-modules](https://github.com/terraform-stackit-modules) organization, which aims to provide community-maintained, production-grade Terraform modules for STACKIT.

### This module: loadbalancer (unified network + application)

UNIFIED module: `var.type = "network"` (L4) or `"application"` (L7), default `network`. Inspired by
terraform-aws-alb. STACKIT has TWO separate resources (not one resource + a type flag like AWS's
`aws_lb`), so the module gates them with `count` on `var.type` and splits inputs per type.

**Resources managed**
- `stackit_loadbalancer` — L4 NLB (created when `type = network`).
- `stackit_loadbalancer_observability_credential` — optional, network only.
- `stackit_application_load_balancer` — L7 ALB (created when `type = application`).

**Key inputs** — common: `project_id` (req), `type`, `name` (req), `plan_id`, `external_address`,
`networks` (`{network_id, role}`), `labels` (application only).
network: `network_listeners` (`{port, protocol TCP/UDP/TCP_PROXY/TLS_PASSTHROUGH, target_pool,
display_name?, tcp?, udp?}`), `network_target_pools` (`{name, target_port, targets[{display_name,ip}],
active_health_check?, session_persistence?}`), `network_options`, `observability_credential`
(sensitive), `disable_security_group_assignment`.
application: `application_listeners` (`{name, port, protocol HTTP/HTTPS, http{hosts[{host,
rules[{target_pool, path?, headers?, query_parameters?, cookie_persistence?, web_socket?}]}]},
https? {certificate_config{certificate_ids}}, waf_config_name?}`), `application_target_pools`
(`{name, target_port, targets, active_health_check?, tls_config?}`), `application_options`,
`disable_target_security_group_assignment`.

**Outputs** — `type`, `loadbalancer_name`, `external_address`, `private_address` (all coalesced);
network-only: `security_group_id`, `load_balancer_security_group_id`, `observability_credentials_ref`
(sensitive); application-only: `target_security_group`, `load_balancer_security_group`.

**Gotchas**
- Provide ONLY the input set matching `type`; the other resource is not created (`count = 0`).
- All listeners/networks/target_pools/options are nested attributes → `= [ { ... } ]` / `= { ... }`,
  never `dynamic {}`.
- A listener/rule references a target pool by `name`; targets' `ip` are PRIVATE backend IPs.
- Do NOT cross variable references inside a `validation` block (only self-var allowed) — so the
  "right input set for the type" rule is documented, not validated.
- `network_listeners[*].server_name_indicators` intentionally omitted (deprecated in provider).
- A STACKIT load balancer FAILS creation (`STATUS_ERROR` / `TYPE_TARGET_NOT_ACTIVE`) if no backend
  answers on the target port — a reachable target is mandatory, not optional. The `basic` example
  therefore stands up a real backend: network + security group (ingress TCP:80) + compute server
  (nginx via cloud-init, fixed private IPv4) + `time_sleep` (lets cloud-init finish before the LB
  health-checks the target) + the LB. It composes the published `network` and `compute` modules and
  adds the `hashicorp/tls` (SSH key) and `hashicorp/time` (`time_sleep`) providers in the example.
- Examples: `basic` (network, end-to-end, long) runs in CI; `application` (L7) self-skips unless
  TERRATEST_RUN_ALL. `application` has the SAME mandatory-target constraint and still needs the same
  backend+`time_sleep` treatment before it can apply cleanly.

**Provisional: tests run on `tofu`, not `terraform`**
The `basic` example references the published `terraform-stackit-modules/{network,compute}` modules,
which are currently resolvable only via the OpenTofu Registry (the Terraform Registry is temporarily
unavailable for this org). So the Terratest files pin `TerraformBinary: "tofu"` and the terratest
workflow adds `opentofu/setup-opentofu`. This is specific to THIS module and provisional — revert to
the default `terraform` binary once the Terraform Registry is available again. Do not propagate this
to other modules.

## Repository structure

```
.
├── main.tf                  # Module resources (gated on var.type)
├── variables.tf             # Input variables (all must be documented)
├── outputs.tf               # Output values (all must be documented)
├── versions.tf              # Terraform and provider version constraints
├── examples/
│   ├── basic/               # Network/L4 end-to-end example (used by Terratest)
│   └── application/         # Application/L7 example (host/path routing)
├── test/
│   ├── examples_basic_test.go        # Terratest (network/L4), runs in CI
│   └── examples_application_test.go  # Terratest (application/L7), skipped unless TERRATEST_RUN_ALL
├── AGENTS.md                # This file
└── .github/
    └── workflows/           # CI/CD pipelines
```

## Coding conventions

- Terraform version: `>= 1.3`
- Provider: `stackitcloud/stackit >= 0.113.0` — do NOT use `hashicorp/stackit`
- All variables must have `description` and `type`
- All outputs must have `description`
- Naming convention: `snake_case` for all resources, variables, and outputs
- No hardcoded values — use variables
- `project_id` is always a required variable of type `string`
- Use `count` only for on/off toggles (and for the `var.type` network/application gate), use
  `for_each` for resource iteration
- Nested attributes in the STACKIT provider (listeners, networks, target_pools, options) use the
  `= {}` / `= [ { ... } ]` syntax, NOT `dynamic {}` blocks

## CI/CD

- `pre-commit` runs `terraform_fmt`, `terraform_validate`, `terraform_docs`, `terraform_tflint` on every PR
- `README.md` is auto-generated by `terraform-docs` — never edit it directly
- Releases are managed by `semantic-release` using conventional commits
- Terratest runs real infrastructure tests against STACKIT — requires `STACKIT_SERVICE_ACCOUNT_KEY` and `STACKIT_PROJECT_ID` secrets
- Terratest here is driven by `tofu` (provisional, see "This module" above); the terratest workflow installs it via `opentofu/setup-opentofu`

## Commit convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` new feature
- `fix:` bug fix
- `improvement:` enhancement
- `docs:` documentation
- `refactor:` refactoring
- `test:` tests
- `ci:` CI/CD changes
- `chore:` maintenance (skipped in changelog)

## What to avoid

- Do not edit `README.md` directly
- Do not use `count` for resource iteration — prefer `for_each`
- Do not pin provider versions to an exact version in modules — use `>=`
- Do not commit `.terraform/`, `*.tfstate`, or `*.tfstate.backup`
- Do not add `dynamic` blocks for `nested_type/single` attributes in the STACKIT provider

## Inspiration Note
Inspired by the excellent work of the [terraform-aws-modules](https://github.com/terraform-aws-modules) community and AWS A&I conventions.
