#' walkboutr: generate walk bouts from GPS and accelerometry data
#'
#' @description
#' The pipeline turns raw per-epoch accelerometry counts and GPS fixes into labelled
#' walk bouts. It runs in four stages, and the files in `R/` are named for them.
#'
#' @section Entry points:
#' Two functions are meant to be called directly:
#'
#' - `identify_walk_bouts_in_gps_and_accelerometry_data()` runs the whole pipeline and
#'   returns the input data with bout labels and categories attached. Not de-identified.
#' - `summarize_walk_bouts()` collapses that to one row per bout. De-identified, and the
#'   output intended for sharing.
#'
#' @section The three steps:
#' \enumerate{
#'   \item **Accelerometry to bouts.** `process_accelerometry_counts_into_bouts()` finds
#'     candidate bouts from activity counts, then flags non-wearing periods and complete
#'     wearing days.
#'   \item **GPS to epochs.** `process_gps_data_into_gps_epochs()` snaps GPS fixes onto
#'     the accelerometry epoch grid. Independent of step 1.
#'   \item **Combine and categorise.** `process_bouts_and_gps_epochs_into_walkbouts()`
#'     joins the two, measures each bout's bounding circle, judges GPS completeness, and
#'     assigns a category.
#' }
#'
#' Each step validates its own input first, via `validate_accelerometry_data()` and
#' `validate_gps_data()`.
#'
#' @section Bout categories:
#' Every bout starts as `walk_bout` and is then overwritten in turn, so the last rule to
#' match wins. In precedence order, highest first: `non_walk_incomplete_gps`, `dwell_bout`,
#' `non_walk_too_vigorous`, `non_walk_slow`, `non_walk_fast`, `walk_bout`.
#' A bout reaching the end of that list is a walk bout.
#'
#' @section Files:
#' The three pipeline stages are numbered, so reading `R/` in order follows the data.
#' \describe{
#'   \item{`pipeline.R`}{**Start here.** The two entry points, which run steps 1-3.}
#'   \item{`step1_process_accelerometry_counts_into_bouts.R`}{Step 1. Bout detection, non-wearing periods, complete days.}
#'   \item{`step2_process_gps_data_into_gps_epochs.R`}{Step 2. Snaps GPS fixes onto the epoch grid.}
#'   \item{`step3_process_bouts_and_gps_epochs_into_walkbouts.R`}{Step 3. Bounding radii, GPS completeness, categorisation.}
#'   \item{`parameters.R`}{The `parameters` and `constants` lists, and `collate_arguments()`, which merges caller overrides into them. Every step takes its settings from here.}
#'   \item{`validate_accelerometry_data.R`}{Input schema and range checks for accelerometry counts, called by step 1.}
#'   \item{`validate_gps_data.R`}{The same for GPS data, called by step 2.}
#'   \item{`plot.R`}{`generate_bout_plot()`, which draws one bout against the activity threshold with its GPS radius inset.}
#'   \item{`simulate_gps_data.R`}{Generated GPS data for examples and development.}
#'   \item{`simulate_accelerometry_data.R`}{Generated accelerometry scenarios, the `make_*` builders.}
#'   \item{`utils-pipe.R`}{Re-exports `%>%`.}
#' }
#'
#' @section Running it:
#' The pipeline is sourced, not installed. From the repository root:
#'
#' ```
#' source("load.R")
#' ```
#'
#' `smoke.R` runs every stage on generated data. `docker/Dockerfile` provides a runtime
#' with the geospatial dependencies already built.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL
