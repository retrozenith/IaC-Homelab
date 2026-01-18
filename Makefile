# IaC-pve Makefile
# Common commands for Terraform and Ansible operations

.PHONY: help init plan apply destroy lint test \
        storage media traefik site \
        tf-init tf-plan tf-apply tf-destroy tf-fmt \
        pre-commit clean

# Default target
help:
	@echo "IaC-pve Makefile Commands"
	@echo ""
	@echo "Terraform:"
	@echo "  make tf-init     - Initialize Terraform"
	@echo "  make tf-plan     - Plan Terraform changes"
	@echo "  make tf-apply    - Apply Terraform changes"
	@echo "  make tf-destroy  - Destroy Terraform resources"
	@echo "  make tf-fmt      - Format Terraform files"
	@echo ""
	@echo "Ansible Playbooks:"
	@echo "  make site        - Run full site playbook"
	@echo "  make storage     - Deploy storage LXC"
	@echo "  make media       - Deploy media stack LXC"
	@echo "  make traefik     - Deploy traefik LXC"
	@echo ""
	@echo "Linting & Testing:"
	@echo "  make lint        - Run all linters"
	@echo "  make pre-commit  - Run pre-commit hooks"
	@echo "  make test        - Validate Terraform + lint Ansible"
	@echo ""
	@echo "Other:"
	@echo "  make clean       - Clean Terraform cache"

# =============================================================================
# Terraform Commands
# =============================================================================

tf-init:
	cd terraform && terraform init

tf-plan:
	cd terraform && terraform plan

tf-apply:
	cd terraform && terraform apply

tf-destroy:
	cd terraform && terraform destroy

tf-fmt:
	cd terraform && terraform fmt -recursive

# Aliases
init: tf-init
plan: tf-plan
apply: tf-apply
destroy: tf-destroy

# =============================================================================
# Ansible Playbooks
# =============================================================================

site:
	cd ansible && ansible-playbook playbooks/site.yml

storage:
	cd ansible && ansible-playbook playbooks/storage.yml

docker-services:
	cd ansible && ansible-playbook playbooks/docker-services.yml

traefik:
	cd ansible && ansible-playbook playbooks/traefik.yml

monitoring:
	cd ansible && ansible-playbook playbooks/monitoring.yml

# =============================================================================
# Linting & Testing
# =============================================================================

lint: tf-fmt
	cd terraform && terraform validate
	cd ansible && ansible-lint -c ../.ansible-lint .
	yamllint -c .yamllint.yml ansible/

pre-commit:
	pre-commit run --all-files

test: tf-fmt
	cd terraform && terraform init -backend=false && terraform validate
	cd ansible && ansible-lint -c ../.ansible-lint .

# =============================================================================
# Cleanup
# =============================================================================

clean:
	rm -rf terraform/.terraform
	rm -rf .pre-commit-cache
