# Load the walkboutr pipeline by sourcing R/, without building or installing a package.
#
# Usage, from the repository root:
#   source("load.R")
#
# Why not library(walkboutr)? The pipeline is run as scripts, not installed. Sourcing
# R/ keeps the edit-run loop immediate and removes any build step from the container.
#
# Two things worth knowing:
#
#   - magrittr is attached explicitly. R/utils-pipe.R is roxygen with a NULL body, so
#     `%>%` reaches the package only through the importFrom directive in NAMESPACE.
#     Sourcing the files does not process NAMESPACE, so without this every dplyr
#     pipeline in R/ fails.
#   - Source order does not matter. The only top-level objects in R/ are `parameters`
#     and `constants` in R/parameters.R; everything else is a function definition and
#     nothing is called at load time.

if (!dir.exists("R")) {
  stop("load.R must be sourced from the repository root (no R/ directory here).")
}

library(magrittr)

invisible(lapply(
  list.files("R", pattern = "\\.R$", full.names = TRUE),
  source
))
