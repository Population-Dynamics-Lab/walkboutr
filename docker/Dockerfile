# walkboutr pipeline runtime.
#
# Based on rocker/geospatial rather than rocker/r-ver: sf, lwgeom and geosphere need
# GDAL, GEOS and PROJ, which this image ships prebuilt. That turns a ~20 minute system
# dependency build into a pull.
#
# The tag pins R 4.4.1. rocker images also pin a dated Posit Package Manager snapshot,
# so install.packages() resolves to fixed CRAN versions without needing renv.
#
# Build and run from the repository root:
#   docker build -t walkboutr -f docker/Dockerfile .
#   docker run --rm -v "$PWD:/work" -w /work walkboutr Rscript -e 'source("load.R")'

FROM rocker/geospatial:4.4.1

# Declared in DESCRIPTION Imports and not present in the base image.
RUN install2.r --error --skipinstalled \
      geosphere \
      measurements \
      ggforce \
    && rm -rf /tmp/downloaded_packages

WORKDIR /work

# The pipeline is sourced, not installed, so the image carries no package build step.
# R/ is mounted at run time rather than copied, keeping the image stable across edits.
CMD ["R"]
