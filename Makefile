# walkboutr pipeline. Run from the repository root.

IMAGE := walkboutr
DOCKER_RUN := docker run --rm -v "$$PWD:/work" -w /work $(IMAGE)

.PHONY: help docker-build docker-run smoke lint tables readme

help:
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | sed -E 's/:.*## /\t/'

docker-build: ## Build the pipeline image
	docker build -t $(IMAGE) -f docker/Dockerfile .

docker-run: ## Open an R session in the image, repo mounted at /work
	$(DOCKER_RUN) R

smoke: ## Run the pipeline end to end on sample data, in the image
	$(DOCKER_RUN) Rscript smoke.R

lint: ## Lint R/ on the host
	Rscript -e 'lintr::lint_dir("R")'

tables: ## Regenerate the paper's data dictionary tables from pipeline output
	Rscript analysis/make_tables.R

readme: ## Regenerate README.md from README.Rmd (needs pandoc)
	Rscript -e 'rmarkdown::render("README.Rmd")'
