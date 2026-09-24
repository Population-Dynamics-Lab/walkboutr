# Packages the walkboutr pipeline needs.
#
# repo2docker runs this at image build time. Versions come from the Posit Package
# Manager snapshot pinned by the date in runtime.txt, so this is reproducible
# without renv.
#
# Keep this list in step with WALKBOUTR_DEPENDENCIES in load.R, which checks the
# same packages at load time and reports any that are missing.

install.packages(c(
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
  "knitr",        # rendering README.Rmd and docs/
  "kableExtra"    # tables in README.Rmd
))
