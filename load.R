# Load the walkboutr pipeline by sourcing R/.
#
# Usage, from the repository root:
#   source("load.R")
#
# There is no package to build or install. This reads every function in R/ into
# your session, which keeps the edit-run loop immediate and keeps a build step
# out of the container.

# Find the repository root by walking up from the working directory, so this works
# whether it is sourced from the root, from docs/, or from an editor that sets the
# working directory to the file being edited.
WALKBOUTR_ROOT <- local({
  d <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  repeat {
    if (dir.exists(file.path(d, "R")) && file.exists(file.path(d, "load.R"))) {
      return(d)
    }
    parent <- dirname(d)
    if (identical(parent, d)) {
      stop("Could not find the walkboutr repository root above ", getwd(),
           call. = FALSE)
    }
    d <- parent
  }
})

# Packages the pipeline needs. This list used to live in DESCRIPTION's Imports;
# it lives here now so that loading fails with a useful message rather than an
# "object not found" from somewhere deep in a pipe.
WALKBOUTR_DEPENDENCIES <- c(
  "data.table",   # frollsum, in step 1
  "dplyr",        # used throughout
  "geosphere",    # areaPolygon, in step 3
  "ggforce",      # geom_circle, in plot.R
  "ggplot2",      # plot.R
  "lubridate",    # date-time handling throughout
  "lwgeom",       # st_minimum_bounding_circle, in step 3
  "magrittr",     # the %>% pipe
  "measurements", # unit conversion, in step 3
  "sf",           # st_multipoint, in step 3
  "sp",           # SpatialPoints/spDists, in step 3
  "tidyr"         # drop_na, in step 3
)

local({
  missing <- WALKBOUTR_DEPENDENCIES[
    !vapply(WALKBOUTR_DEPENDENCIES, requireNamespace, logical(1), quietly = TRUE)
  ]
  if (length(missing) > 0) {
    stop(
      "Missing required packages: ", toString(missing), "\n",
      'Install them with: install.packages(c("',
      paste(missing, collapse = '", "'), '"))\n',
      "Or use the container, which has them already: make docker-run",
      call. = FALSE
    )
  }
})

# %>% has to be attached explicitly. It reached the old package through a
# NAMESPACE importFrom directive, and sourcing files does not process NAMESPACE.
library(magrittr)

# Source order does not matter: every file in R/ only defines functions, except
# parameters.R which defines two lists. Nothing runs at load time.
invisible(lapply(
  list.files(file.path(WALKBOUTR_ROOT, "R"), pattern = "\\.R$", full.names = TRUE),
  source
))
