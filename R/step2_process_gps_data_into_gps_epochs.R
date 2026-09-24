# ==============================================================================
# STEP 2 of 3 - GPS fixes -> epoch-aligned GPS
#
# In:  gps_data (time, latitude, longitude, speed)
# Out: the same columns, with `time` snapped to the epoch grid
#
# Independent of step 1; the two are joined in step 3. Where several fixes land
# in one epoch, the latest one wins.
#
# Next: step3_process_bouts_and_gps_epochs_into_walkbouts.R
# ==============================================================================

#' Convert GPS data into GPS epochs
#'
#' The input schema for the accelerometry data is `time`, `latitude`, `longitude`, and `speed`.
#' - `time` should be a column in date-time format, in the UTC time zone, with no null values.
#' - `latitude` should be a numeric, non-null latitude coordinate between -90 and 90
#' - `longitude` should be a numeric, non-null longitude coordinate between -180 and 180
#' - `speed` should be a numeric, non-null value in kilometers per hour
#'
#' This function processes GPS data into GPS epochs, with each epoch having a duration
#' specified by \code{epoch_length}.
#'
#' @param gps_data A data frame containing GPS data. Must have columns "Latitude", "Longitude"
#' @param ... Additional arguments to be passed to the function.
#' @param collated_arguments A named list of arguments, used to avoid naming conflicts when
#'   calling this function as part of a pipeline. Optional.
#'
#' @returns A data frame with columns latitude, longitude, time, and speed, where time is now
#'   the nearest epoch start time
#'
#' @export
process_gps_data_into_gps_epochs <- function(gps_data, ..., collated_arguments = NULL) {
  collated_arguments <- collate_arguments(..., collated_arguments = collated_arguments)
  validate_gps_data(gps_data)
  gps_epochs <- assign_epoch_start_time(
    gps_data,
    collated_arguments$epoch_length
  )
  return(gps_epochs)
}


#' Assign Epoch Start Time
#'
#' @param gps_data A data frame with GPS data including a column of timestamps and columns for
#'   latitude and longitude
#' @param epoch_length The duration of an epoch in seconds
#' @details Selects the closest 30 second increment to assign epoch start time and takes the
#'   GPS coordinates associated with the latest time if there are multiple GPS data points in a
#'   given 30 second increment. This function returns a data frame of GPS data with a column of
#'   epoch times.
#'
#' @returns A data frame of GPS data with an additional column indicating epoch start time
#'
#' @export
assign_epoch_start_time <- function(gps_data, epoch_length) {
  # select the closest 30 second increment to assign epoch start time
  # if there are multiple gps data points in a given 30 second increment,
  # takes the gps coordinates associated with the latest time
  gps_epochs <- gps_data %>%
    dplyr::mutate(epoch_time = as.numeric(time)) %>%
    dplyr::mutate(dx_p = epoch_time %% epoch_length) %>%
    dplyr::mutate(epoch_time = epoch_time - dx_p) %>%
    dplyr::group_by(epoch_time) %>%
    dplyr::filter(as.numeric(time) == max(as.numeric(time))) %>%
    dplyr::mutate(time = lubridate::as_datetime(epoch_time, tz = "UTC")) %>%
    dplyr::ungroup() %>%
    dplyr::select(-c(dx_p, epoch_time))
  return(gps_epochs)
}
