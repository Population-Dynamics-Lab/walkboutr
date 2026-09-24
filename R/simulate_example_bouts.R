# ------------------------------------------------------------------------------
# SUPPORTING - not a pipeline step. Used by the figures and the docs.
#
# The make_* builders in simulate_accelerometry_data.R produce square waves: every
# active epoch is exactly the 500 CPE threshold and every inactive one is zero.
# That is what you want for testing a threshold, and useless for a figure - the
# mean lands on the threshold line and nothing varies.
#
# Likewise generate_gps_data() is a random walk at up to 5 km/h, so a bout's
# bounding circle comes out tens of thousands of feet across and the 66 ft dwell
# threshold is invisible next to it.
#
# These two builders produce data shaped like real data instead, so the plotting
# functions in plot.R have something worth drawing.
# ------------------------------------------------------------------------------

#' Simulate an activity bout with varied counts
#'
#' A quiet period, a bout whose counts vary the way real accelerometry does, then
#' another quiet period. Unlike `make_smallest_bout()` and friends, the active
#' epochs are not all identical, so a plot of it shows a trace rather than a
#' square wave.
#'
#' @param quiet_epochs Epochs of inactivity before and after the bout.
#' @param bout_epochs Epochs in the bout itself.
#' @param mean_counts,sd_counts Mean and standard deviation of the active counts.
#' @param seed Random seed, so the result is reproducible.
#'
#' @returns A data frame with columns `activity_counts` and `time`.
#'
#' @examples
#' make_activity_bout_example()
#' @export
make_activity_bout_example <- function(quiet_epochs = 8, bout_epochs = 24,
                                       mean_counts = 620, sd_counts = 260,
                                       seed = 4321) {
  set.seed(seed)
  active <- pmax(0, round(stats::rnorm(bout_epochs, mean = mean_counts, sd = sd_counts)))
  # Guarantee the run is long enough to register as a bout: the middle epochs sit
  # comfortably above the threshold even when the draw is unlucky.
  active[seq(2, bout_epochs - 1)] <- pmax(
    active[seq(2, bout_epochs - 1)],
    parameters$active_counts_per_epoch_min + 20
  )
  counts <- data.frame(activity_counts = c(
    rep(0, quiet_epochs), active, rep(0, quiet_epochs)
  ))
  add_date_and_format(counts)
}


#' Simulate a dwell bout and a walk bout, with matching GPS
#'
#' Two bouts in one dataset: the first spent in one place, the second spent
#' walking in a straight line. Their bounding circles fall either side of the
#' dwell bout threshold, which is what `generate_dwell_vs_walk_plot()` needs in
#' order to show anything.
#'
#' @param start_lat,start_long Where the data start, in decimal degrees.
#' @param start_time Timestamp of the first epoch, as a string.
#' @param dwell_radius_ft How far the dwell bout wanders. Below the 66 ft
#'   threshold by default, so it classifies as a dwell bout.
#' @param walking_speed_km_h Speed during the walking bout. Between the walking
#'   bounds in `constants` by default.
#' @param bout_epochs Epochs in each bout.
#' @param quiet_epochs Epochs of inactivity around and between the bouts.
#' @param seed Random seed, so the result is reproducible.
#'
#' @returns A list with `accelerometry_counts` and `gps_data`, ready to pass to
#'   the pipeline or to any of the plotting functions.
#'
#' @examples
#' example_data <- make_dwell_and_walk_example()
#' names(example_data)
#' @export
make_dwell_and_walk_example <- function(start_lat = 47.6062, start_long = -122.3321,
                                        start_time = "2012-04-07 09:00:30",
                                        dwell_radius_ft = 45,
                                        walking_speed_km_h = 2.5,
                                        bout_epochs = 14, quiet_epochs = 8,
                                        seed = 8675) {
  set.seed(seed)
  epoch_length <- parameters$epoch_length

  # --- accelerometry: quiet, bout, quiet, bout, quiet -------------------------
  active_counts <- function(n) {
    pmax(
      parameters$active_counts_per_epoch_min + 20,
      round(stats::rnorm(n, mean = 900, sd = 200))
    )
  }
  counts <- c(
    rep(0, quiet_epochs),
    active_counts(bout_epochs),
    rep(0, quiet_epochs),
    active_counts(bout_epochs),
    rep(0, quiet_epochs)
  )
  n_epochs <- length(counts)
  times <- seq(lubridate::ymd_hms(start_time, tz = "UTC"),
    length.out = n_epochs, by = paste(epoch_length, "sec")
  )
  accelerometry_counts <- data.frame(activity_counts = counts, time = times)

  # --- GPS: still during the first bout, walking during the second ------------
  meters_per_degree_lat <- 111320
  meters_per_degree_long <- 111320 * cos(start_lat * pi / 180)
  ft_to_deg_lat <- function(ft) measurements::conv_unit(ft, "ft", "m") / meters_per_degree_lat
  ft_to_deg_long <- function(ft) measurements::conv_unit(ft, "ft", "m") / meters_per_degree_long

  dwell_idx <- seq(quiet_epochs + 1, quiet_epochs + bout_epochs)
  walk_idx <- seq(2 * quiet_epochs + bout_epochs + 1, 2 * quiet_epochs + 2 * bout_epochs)

  latitude <- rep(NA_real_, n_epochs)
  longitude <- rep(NA_real_, n_epochs)
  speed <- rep(NA_real_, n_epochs)

  # Dwell: uniform over a disc, which is what standing still plus GPS jitter
  # looks like. sqrt() keeps the points evenly spread rather than clustered.
  angle <- stats::runif(length(dwell_idx), 0, 2 * pi)
  spread <- dwell_radius_ft * sqrt(stats::runif(length(dwell_idx)))
  latitude[dwell_idx] <- start_lat + ft_to_deg_lat(spread * sin(angle))
  longitude[dwell_idx] <- start_long + ft_to_deg_long(spread * cos(angle))
  speed[dwell_idx] <- stats::runif(length(dwell_idx), 0, 0.6)

  # Walk: a straight line on a fixed bearing, with a little wobble either side.
  meters_per_epoch <- walking_speed_km_h * 1000 / 3600 * epoch_length
  step_ft <- measurements::conv_unit(meters_per_epoch, "m", "ft")
  along <- seq_along(walk_idx) * step_ft
  wobble <- stats::rnorm(length(walk_idx), 0, 12)
  bearing <- 65 * pi / 180
  walk_start_lat <- start_lat + ft_to_deg_lat(400)
  latitude[walk_idx] <- walk_start_lat +
    ft_to_deg_lat(along * cos(bearing) + wobble * sin(bearing))
  longitude[walk_idx] <- start_long +
    ft_to_deg_long(along * sin(bearing) - wobble * cos(bearing))
  speed[walk_idx] <- stats::rnorm(length(walk_idx), walking_speed_km_h, 0.25)

  gps_data <- data.frame(
    time = times, latitude = latitude, longitude = longitude, speed = speed
  )
  gps_data <- gps_data[!is.na(gps_data$latitude), ]
  gps_data$speed <- pmax(0, gps_data$speed)
  rownames(gps_data) <- NULL

  list(accelerometry_counts = accelerometry_counts, gps_data = gps_data)
}
