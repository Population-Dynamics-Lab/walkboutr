# Simulated accelerometry scenarios: the make_* builders that construct activity
# count sequences for a given situation (smallest bout, full day, non-wearing period).
# Split out of the former sample_data.R.

#' Generate accelerometry datasets
#'
#' This function generates a list of activity epochs with specified minimum active counts per
#' epoch, minimum bout length,
#' maximum number of consecutive inactive epochs in a bout, minimum non-wearing length, and
#' minimum complete day length.
#'
#' @param length Length of the active period
#' @param is_bout Logical indicating if the active period is a bout
#' @param non_wearing Logical indicating if the active period is a non-wearing period
#' @param complete_day Logical indicating if the active period is a complete day
#'
#' @return A list of activity epochs
make_active_period <- function(length = 1, is_bout = TRUE, non_wearing = FALSE, complete_day = FALSE) {
  active_period <- data.frame(activity_counts = rep(parameters$active_counts_per_epoch_min, length),
         bout = as.integer(is_bout),
         non_wearing = as.logical(non_wearing),
         complete_day = as.logical(complete_day))
  return(active_period)
}



#' Create an inactive period
#'
#' This function creates an inactive period with a given length.
#'
#' @param length The length of the inactive period.
#' @param is_bout Logical value indicating whether this period is part of a bout of inactivity.
#' @param non_wearing Logical value indicating whether this period is due to non-wearing of the
#'   accelerometer.
#' @param complete_day Logical value indicating whether this period occurs during a complete
#'   day of wearing the accelerometer.
#'
#' @return A data frame with columns activity_counts, bout, non_wearing, and complete_day,
#'   where activity_counts is set to 0 for the entire length, and bout, non_wearing, and
#'   complete_day are set according to the input values.
#'
make_inactive_period <- function(length = 1, is_bout = FALSE, non_wearing = FALSE, complete_day = FALSE) {
  inactive_period <- data.frame(activity_counts = rep(0, length),
         bout = as.integer(is_bout),
         non_wearing = as.logical(non_wearing),
         complete_day = as.logical(complete_day))
  return(inactive_period)
}


#' Add date and format to activity counts
#'
#' This function takes a data frame of activity counts and adds a column of time stamps in
#' POSIXct format.
#' The time stamps start at "2012-04-07 00:00:30" and increase by 30 seconds for each row of
#' the data frame.
#'
#' @param counts a data frame containing activity counts
#' @return a data frame with time stamps added in POSIXct format
add_date_and_format <- function(counts) {
  time <- seq(lubridate::ymd_hms("2012-04-07 00:00:30"), length.out = nrow(counts), by = "30 sec")
  df <- base::cbind(counts, time)
  return(df)
  }



#' Create the smallest bout window
#'
#' This function creates an active period of minimum length defined by the parameter
#' \code{minimum_bout_length}.
#'
#' @param minimum_bout_length is the minimum number of epochs for something to be considered a
#'   bout
#' @param is_bout Logical indicating if the active period is a bout
#' @param non_wearing Logical indicating if the active period is a non-wearing period
#' @param complete_day Logical indicating if the active period is a complete day

#' @return A data.frame with columns `activity_counts`, `bout`, `non_wearing`, and
#'   `complete_day` representing the smallest bout window.
make_smallest_bout_window <- function(minimum_bout_length = parameters$minimum_bout_length,
                                      is_bout = TRUE, non_wearing = FALSE, complete_day = FALSE) {
  return(make_active_period(length = minimum_bout_length, is_bout = is_bout,
                            non_wearing = non_wearing, complete_day = complete_day))
}


#' Create a non-bout window
#'
#' This function creates a non-bout window, which is a period of inactivity that is not long
#' enough to be considered as an inactive bout.
#'
#' @param maximum_number_consec_inactive_epochs_in_bout maximum number of consecutive inactive
#'   epochs in a bout before it is terminated
#'
#' @return a data frame with columns "activity_counts", "bout", "non_wearing", "complete_day"
#'
#' @examples
#' make_non_bout_window()
#'
#' @export
make_non_bout_window <- function(maximum_number_consec_inactive_epochs_in_bout = parameters$maximum_number_consec_inactive_epochs_in_bout) {
  return(make_inactive_period(maximum_number_consec_inactive_epochs_in_bout + 1))
}


#' Create smallest non-wearing window
#'
#' Create an inactive period that represents the smallest non-wearing window.
#' This function uses the \code{make_inactive_period()} function to create the non-wearing
#' window.
#'
#' @param min_non_wearing_length minimum non_wearing time before a bout is terminated
#'
#' @return An inactive period data frame that represents the smallest non-wearing window.
#'
#' @examples
#' make_smallest_nonwearing_window()
#' @export
make_smallest_nonwearing_window <- function(min_non_wearing_length = constants$non_wearing_min_threshold_epochs) {
  return(make_inactive_period(min_non_wearing_length, non_wearing = TRUE))
}


#' Generate an activity sequence for a complete day with minimal activity
#'
#' This function generates an activity sequence for a complete day with a minimal activity
#' count.
#'
#' @param min_complete_day minimum number of epochs for something to be a complete day
#'
#' @return An activity sequence data frame with minimum activity counts for a complete day.
#'
#' @examples
#' make_smallest_complete_day_activity()
#'
#' @export
make_smallest_complete_day_activity <- function(min_complete_day = 8602) {
  return(make_active_period(min_complete_day, non_wearing = FALSE, complete_day = TRUE))
}


#' Make the smallest bout dataset
#'
#' Generates a dataset representing the smallest bout, consisting of a sequence of inactive
#' periods followed by the smallest active period.
#'
#' @return A data frame containing the activity counts and bout information for the smallest
#'   bout.
#'
#' @examples
#' make_smallest_bout()
#' @export
make_smallest_bout <- function() {
  counts <- dplyr::bind_rows(
    make_non_bout_window(),
    make_smallest_bout_window(),
    make_non_bout_window()
  )
  return(add_date_and_format(counts))
}



#' Create the smallest bout window without metadata
#'
#' This function creates the smallest bout window without the metadata columns. It calls the
#' \code{\link{make_smallest_bout}} function and then removes the columns "non_wearing",
#' "complete_day", and "bout" using \code{dplyr::select}.
#'
#' @return A data frame containing the smallest bout window without metadata.
#'
#' @examples
#' make_smallest_bout_without_metadata()
#' @export
make_smallest_bout_without_metadata <- function() {
  return(make_smallest_bout() %>%
           dplyr::select(-c("non_wearing", "complete_day", "bout")))
}


#' Generate a sequence of accelerometer counts representing the smallest bout with the largest
#' inactive period
#'
#' This function generates a sequence of accelerometer counts representing the smallest bout
#' with the largest inactive period.
#' The length of the inactive period is determined by the value of
#' `maximum_number_consec_inactive_epochs_in_bout` variable.
#'
#' @param maximum_number_consec_inactive_epochs_in_bout maximum number of consecutive inactive
#'   epochs in a bout before it is terminated
#'
#' @return A data frame with columns `activity_counts` and `time`, representing the
#'   accelerometer counts and the corresponding time stamps.
#'
#' @examples
#' make_smallest_bout_with_largest_inactive_period()
#' @export
make_smallest_bout_with_largest_inactive_period <- function(maximum_number_consec_inactive_epochs_in_bout = parameters$maximum_number_consec_inactive_epochs_in_bout) {
  nbw <- make_non_bout_window()
  inactive_period <- make_inactive_period(maximum_number_consec_inactive_epochs_in_bout, is_bout = TRUE)
  sbw <- make_smallest_bout_window()
  halfway <- nrow(sbw)/2

  counts <- dplyr::bind_rows(
    nbw,
    sbw[1:halfway, ],
    inactive_period,
    sbw[(halfway+1):nrow(sbw), ],
    nbw
  )
  return(add_date_and_format(counts))
}


#' Generate the smallest bout with the smallest non-wearing period dataset
#'
#' This function creates a dataset consisting of the smallest bout and the smallest non-wearing
#' period. The bout length, non-wearing period length, and epoch length are defined in the
#' global variables: minimum_bout_length, maximum_number_consec_inactive_epochs_in_bout, and
#' min_non_wearing_length, respectively.
#'
#' @return A data frame with columns for activity counts and date-time stamps.
#'
#' @examples
#' make_smallest_bout_with_smallest_non_wearing_period()
#' @export
make_smallest_bout_with_smallest_non_wearing_period <- function() {
  counts <- dplyr::bind_rows(
    make_non_bout_window(),
    make_smallest_bout_window(),
    make_smallest_nonwearing_window()
  )
  return(add_date_and_format(counts))
}


#' Create activity counts for a full day bout
#'
#' This function creates a data frame with activity counts for a full day bout. A full day bout
#' is defined as an uninterrupted period of activity with a length of at least
#' \code{min_complete_day}. The function calls the \code{make_non_bout_window()},
#' \code{make_smallest_bout_window()}, and \code{make_smallest_complete_day_activity()}
#' functions to generate the activity counts for the non-bout window, smallest bout window, and
#' smallest complete day activity, respectively.
#'
#' @return A data frame with activity counts for a full day bout
#' @export
make_full_day_bout <- function() {
  counts <- dplyr::bind_rows(
    make_non_bout_window(),
    make_smallest_bout_window(),
    make_smallest_complete_day_activity()
  )
  counts <- add_date_and_format(counts)
  counts <- counts %>%
    dplyr::mutate(complete_day = TRUE)
  return(counts)
}


#' Create activity counts for a full day bout without metadata
#'
#' This function creates a data frame with activity counts for a full day bout. A full day bout
#' is defined as an uninterrupted period of activity with a length of at least
#' \code{min_complete_day}. The function calls the \code{make_non_bout_window()},
#' \code{make_smallest_bout_window()}, and \code{make_smallest_complete_day_activity()}
#' functions to generate the activity counts for the non-bout window, smallest bout window, and
#' smallest complete day activity, respectively.
#'
#' @return A data frame with activity counts for a full day bout without metadata
#' @export
make_full_day_bout_without_metadata <- function() {
  counts <- dplyr::bind_rows(
    make_non_bout_window(),
    make_smallest_bout_window(),
    make_non_bout_window(),
    make_smallest_bout_window(),
    make_smallest_complete_day_activity()
  )
  counts <- add_date_and_format(counts)
  counts <- counts %>%
    dplyr::mutate(complete_day = TRUE) %>%
    dplyr::select(-c("complete_day", "non_wearing", "bout"))
  return(counts)
}


#' Create a data frame of walking bouts with GPS data
#'
#' This function combines accelerometer and GPS data to create a data frame of walking bouts.
#' It generates a full day of activity with bouts of minimum and non-bout periods, and GPS data
#' for walking in Seattle.
#' The accelerometer data is processed into bouts using the
#' \code{\link{process_accelerometry_counts_into_bouts}} function.
#' The GPS data is processed into epochs using the
#' \code{\link{process_gps_data_into_gps_epochs}} function.
#'
#' @return A data frame of walking bouts with GPS data
#' @examples
#' make_full_walk_bout_df()
#' @export
make_full_walk_bout_df <- function() {
  accelerometry_counts <- make_full_day_bout() %>%
    dplyr::select(-c("bout","non_wearing","complete_day"))
  gps_data <- generate_walking_in_seattle_gps_data()
  bouts <- process_accelerometry_counts_into_bouts(accelerometry_counts)
  gps_epochs <- process_gps_data_into_gps_epochs(gps_data)

  walk_bouts <- gps_epochs %>%
    dplyr::full_join(bouts, by = "time") %>%
    dplyr::arrange(time) %>%
    dplyr::mutate(bout = ifelse(bout==0,NA,bout)) # replace 0s with NAs since they arent bouts

  return(walk_bouts)
}
