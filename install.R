# Packages the walkboutr pipeline needs.
#
# repo2docker runs this at image build time, and docker/Dockerfile runs it too.
# Versions come from the Posit Package Manager snapshot pinned by the date in
# runtime.txt, so this is reproducible without renv.
#
# Already-installed packages are skipped, which is what lets the Dockerfile call
# this instead of keeping its own list: its base image ships most of these
# prebuilt, and reinstalling them would add twenty minutes to the build.
#
# Keep this list in step with WALKBOUTR_DEPENDENCIES in load.R. That one omits
# knitr, since the pipeline runs fine without it -- it is only needed to render
# README.Rmd and the walkthroughs in docs/.

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
  "tidyr",        # drop_na, in step 3
  "knitr"         # rendering README.Rmd and docs/
)

# repo2docker and the rocker images both point `repos` at a pinned Posit Package
# Manager snapshot, which is what makes the versions reproducible. Leave that
# alone where it is set; supply a plain CRAN mirror only where it is not, since
# a non-interactive Rscript run otherwise dies with "trying to use CRAN without
# setting a mirror".
repos <- getOption("repos")
if (is.null(repos) || is.na(repos["CRAN"]) || identical(unname(repos["CRAN"]), "@CRAN@")) {
  options(repos = c(CRAN = "https://cloud.r-project.org"))
}
message("Installing from: ", unname(getOption("repos")["CRAN"]))

installed <- function(pkgs) {
  vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)
}

missing <- WALKBOUTR_DEPENDENCIES[!installed(WALKBOUTR_DEPENDENCIES)]

if (length(missing) == 0) {
  message("All ", length(WALKBOUTR_DEPENDENCIES), " packages already installed; nothing to do.")
} else {
  message("Installing ", length(missing), " of ", length(WALKBOUTR_DEPENDENCIES),
          " packages: ", toString(missing))
  install.packages(missing)

  # install.packages() warns rather than errors when a package fails to build,
  # so check again. Without this an image can finish building and only break
  # later, when someone sources load.R inside it.
  still_missing <- missing[!installed(missing)]
  if (length(still_missing) > 0) {
    stop("Failed to install: ", toString(still_missing), call. = FALSE)
  }
  message("Done.")
}
