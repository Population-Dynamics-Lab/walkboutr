# ------------------------------------------------------------------------------
# SUPPORTING - not a pipeline step. Used by the docs and smoke.R.
#
# Generates GPS data for a walk in Seattle: a random walk of positions and
# speeds from a fixed seed. Nothing here reads real data.
#
# Its counterpart is simulate_accelerometry_data.R.
# ------------------------------------------------------------------------------

#' Generate a dataset with date-time, speed, and latitude and longitude of someone moving
#' through space on a walk in Seattle
#'
#' @param start_lat The starting latitude of the walk.
#' @param start_long The starting longitude of the walk.
#' @param start_time The start time of a series of data
#' @param time_interval The time interval between points in seconds.
#' @param n_epochs The number of epochs in the series
#' @param seed random seed
#'
#' @returns A data frame with four columns: `time`, `latitude`, `longitude` and `speed`.
#'
#' @export
generate_gps_data <- function(start_lat, start_long, start_time, n_epochs = 110, time_interval = 30.0, seed = 1234) {
  # set random number generator seed for reproducibility, before any draw
  set.seed(seed)

  # set the initial location and speed
  current_lat <- start_lat
  current_long <- start_long
  current_speed <- stats::runif(1, 0.5, 5) # km/h

  # generate a series of locations and speeds
  directions <- stats::runif(n_epochs, 0, 2 * pi)
  dts <- stats::runif(n_epochs, 25, 35)

  # create a time vector
  times <- seq.POSIXt(as.POSIXct(start_time), length.out = n_epochs + 1, by = time_interval)

  # create a data frame with columns [time, latitude, longitude, speed]
  df <- data.frame(
    time = lubridate::ymd_hms(times, tz = "UTC"),
    latitude = numeric(n_epochs + 1),
    longitude = numeric(n_epochs + 1),
    speed = numeric(n_epochs + 1)
  )

  # generate latitudes, longitudes, and speeds using a loop
  df$latitude[1] <- start_lat
  df$longitude[1] <- start_long
  df$speed[1] <- current_speed

  for (i in seq_along(directions)) {
    df[i + 1, c("latitude", "longitude")] <- next_lat_long(df[i, "latitude"], df[i, "longitude"], df[i, "speed"], directions[i], dts[i])
    df$speed[i + 1] <- stats::runif(1, .5, 5)
  }

  return(df)
}



#' Calculate next latitude and longitude based on current location, speed, direction, and time
#' elapsed.
#'
#' Given a current location (latitude and longitude), speed, direction (in radians), and time
#' elapsed (in seconds),
#' this function calculates the next latitude and longitude. The calculations are based on the
#' assumption of a constant
#' speed and direction during the elapsed time.
#'
#' @param latitude The current latitude in decimal degrees.
#' @param longitude The current longitude in decimal degrees.
#' @param speed The speed in kilometers per hour.
#' @param direction The direction of movement in radians from due north (0 radians).
#' @param dt The elapsed time in seconds.
#'
#' @return A numeric vector of length 2 containing the next latitude and longitude in decimal
#'   degrees.
next_lat_long <- function(latitude, longitude, speed, direction, dt) {
  # convert the direction from radians to degrees
  direction_degrees <- direction * 180 / pi

  # convert the speed from km/h to m/s
  speed_mps <- speed / 3.6

  # calculate the distance traveled in meters
  distance_m <- speed_mps * dt

  # calculate the bearing in degrees from due north
  bearing_degrees <- (90 - direction_degrees) %% 360

  # convert the current latitude and longitude to radians
  lat1 <- latitude * pi / 180
  lon1 <- longitude * pi / 180

  # calculate the next latitude and longitude in radians
  lat2 <- lat1 + (distance_m / 6378137) * (180 / pi)
  lon2 <- lon1 + (distance_m / 6378137) * (180 / pi) / cos(lat1 * pi / 180)

  # convert the next latitude and longitude to decimal degrees
  lat2_degrees <- lat2 * 180 / pi
  lon2_degrees <- lon2 * 180 / pi

  return(c(lat2_degrees, lon2_degrees))
}




#' Generate GPS data for a walking activity in Seattle, WA
#'
#' This function generates a data frame containing GPS data for a walking activity in Seattle,
#' WA on April 7th, 2012. It calls the function generate_gps_data to create a series of GPS
#' locations and speeds. The resulting data frame has columns for time, latitude, longitude,
#' and speed.
#'
#' @param start_lat The starting latitude of the walk.
#' @param start_long The starting longitude of the walk.
#' @param start_time The start time of a series of data
#'
#' @return A data frame with columns `time`, `latitude`, `longitude`, `speed`
#' @export
generate_walking_in_seattle_gps_data <- function(start_lat = 47.6062,
                                                 start_long = -122.3321,
                                                 start_time = "2012-04-07 00:00:30") {
  # Generating a sample dataset of walking in Seattle, WA, USA on April 7th, 2012
  gps_data <- generate_gps_data(start_lat = start_lat, start_long = start_long, start_time = start_time)
  return(gps_data)
}
