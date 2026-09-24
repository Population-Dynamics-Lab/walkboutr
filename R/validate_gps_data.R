# Input validation for GPS data, mirroring validate_accelerometry_data.R.
# Previously buried in process_gps_data_into_gps_epochs.R while its twin had its own file.

#' Validate GPS data
#'
#' This function validates GPS data for required variables, correct variable class, and correct
#' data range.
#'
#' @param gps_data A data frame containing GPS data with the following variables: time,
#'   latitude, longitude, and speed.
#'
#' @returns This function does not return anything. It throws an error if the GPS data fails
#'   any of the validation checks.
#'
#' @export
validate_gps_data <- function(gps_data){

# Validation schema
  diff <- setdiff(names(gps_data), c("time", "latitude", "longitude", "speed"))
  missing <- setdiff(c("time", "latitude", "longitude", "speed"), names(gps_data))
  if(length(missing)>0){
    stop(paste0("Error: data provided are missing `", missing, "` columns."))
  }
  if(length(diff)>0){
    diff <- paste0(diff, collapse = ', ')
    stop(paste0("Error: data provided have the following extra columns: ", diff))
  }

# Validate time variable
  if(!lubridate::is.timepoint(gps_data$time)){
    stop(paste0("Error: time is not provided in date-time format. class of time variable should be: `POSIXct` `POSIXt`"))
  }
  if(any(is.na(gps_data$time))){
    stop(paste0("Error: time data contain NAs"))
  }
  if(!(lubridate::tz(gps_data$time) == "UTC")){
    stop(paste0("Error: time zone provided is not UTC."))
  }

# Validate latitude/longitude variable
  if(!(class(gps_data$latitude) %in% c("integer", "numeric"))){
    stop(paste0("Error: latitude column is not class integer or numeric."))
  }
  if(any(is.na(gps_data$latitude))){
    stop(paste0("Error: latitude column contains NAs"))
  }
  if(any(gps_data$latitude < -90 | gps_data$latitude > 90)){
    stop(paste0("Error: latitude column contains invalid latitude coordinates"))
  }
  if(!(class(gps_data$longitude) %in% c("integer", "numeric"))){
    stop(paste0("Error: longitude column is not class integer or numeric."))
  }
  if(any(is.na(gps_data$longitude))){
    stop(paste0("Error: longitude column contains NAs"))
  }
  if(any(gps_data$longitude < -180 | gps_data$longitude > 180)){
    stop(paste0("Error: longitude column contains invalid longitude coordinates"))
  }

# Validate speed variable
  if(!(class(gps_data$speed) %in% c("numeric"))){
    stop(paste0("Error: speed column is not class integer or numeric."))
  }
  if(any(is.na(gps_data$speed))){
    stop(paste0("Error: speed column contains NAs"))
  }
  if(any(gps_data$speed<0)){
    stop(paste0("Error: speed column contains negative values"))
  }
  if(any(gps_data$speed > 2000)){
    message("Warning: speed column contains implausibly large values")
  }

}
