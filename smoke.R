# Run the pipeline end to end on generated sample data and print what it produced.
#
# This is not a test suite and it asserts nothing. It is the one thing in the repo
# that exercises every stage, so run it after any change to R/.
#
#   Rscript smoke.R          (host)
#   make smoke               (in the container)

source("load.R")

gps_data <- generate_walking_in_seattle_gps_data()
accelerometry_counts <- make_full_day_bout_without_metadata()

walk_bouts <- identify_walk_bouts_in_gps_and_accelerometry_data(
  gps_data, accelerometry_counts
)
summary_walk_bouts <- summarize_walk_bouts(walk_bouts)

# complete_day is computed against the LOCAL calendar day, not the UTC one, so group
# the same way the pipeline does or the output looks inconsistent.
local_date <- lubridate::as_date(walk_bouts$time, tz = parameters$local_time_zone)

cat("\n-- epochs per local calendar day ------------------------------------\n")
print(table(local_date))

cat("\n-- complete_day by local date ---------------------------------------\n")
print(unique(data.frame(date = local_date, complete_day = walk_bouts$complete_day)))

cat("\n-- non-wearing epochs -----------------------------------------------\n")
print(table(walk_bouts$non_wearing, useNA = "ifany"))

cat("\n-- bout categories --------------------------------------------------\n")
print(table(walk_bouts$bout_category, useNA = "ifany"))

cat("\n-- bout summary -----------------------------------------------------\n")
print(as.data.frame(summary_walk_bouts))

cat("\n-- bout radii (one value per bout, not one shared value) ------------\n")
gps_epochs <- process_gps_data_into_gps_epochs(gps_data)
bouts <- process_accelerometry_counts_into_bouts(accelerometry_counts)
print(generate_bout_radius(
  bouts %>%
    dplyr::left_join(gps_epochs, by = "time") %>%
    dplyr::mutate(bout = ifelse(bout == 0, NA, bout)),
  constants$dwellbout_radii_quantile
))

cat("\n-- generate_gps_data is reproducible for a fixed seed ---------------\n")
a <- generate_gps_data(47.6062, -122.3321, "2012-04-07 00:00:30", seed = 99)
b <- generate_gps_data(47.6062, -122.3321, "2012-04-07 00:00:30", seed = 99)
cat("identical:", identical(a, b), "\n")
