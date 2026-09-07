# Using this template

This document describes the steps to follow after creating a new repository from this template.

## Checklist

### Repository setup

- [ ] Rename the repository to `terraform-stackit-<resource>` (e.g. `terraform-stackit-network`)
- [ ] Update the repository description on GitHub
- [ ] Add the repository to the `CODEOWNERS` file with the correct team
- [ ] Configure the `SEMANTIC_RELEASE_TOKEN` secret in the repository settings

### File updates

- [ ] Replace all occurrences of `MODULE_NAME` with the actual module name
  - `.github/contributing.md` (x2)
- [ ] Update `AGENTS.md` with the module-specific context (resources, variables, outputs)
- [ ] Update `examples/basic/main.tf` with a working example
- [ ] Update `examples/basic/.header.md` with the example description

### Template cleanup

- [ ] Remove the `## Acknowledgements` section in `.header.md` (marked `TEMPLATE ONLY`)
- [ ] Delete this file (`TEMPLATE_USAGE.md`)

> The `TEMPLATE ONLY` section removal can also be triggered automatically via the
> `.github/workflows/template-cleanup.yml` workflow, which runs once on the first push
> after the repository is created from this template.
