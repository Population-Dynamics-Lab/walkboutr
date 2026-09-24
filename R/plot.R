# ------------------------------------------------------------------------------
# SUPPORTING - not a pipeline step. Called by you, directly.
#
# The three figures in the article, each one function call:
#
#   generate_activity_bout_plot()   an activity bout against the 500 CPE line
#   generate_dwell_vs_walk_plot()   a dwell bout and a walk bout, with their
#                                   bounding circles against the 66 ft threshold
#   generate_bout_plot()            one bout in full: trace, bout period, mean
#                                   CPE, and the GPS radius inset
#
# Each runs whichever pipeline steps it needs internally, so callers pass raw
# accelerometry counts and GPS data and get a ggplot back.
# ------------------------------------------------------------------------------

#' Colours shared by the bout plots
#'
#' One palette so the three figures read as a set. Referenced by name rather than
#' repeated as literals.
#'
#' @keywords internal
bout_plot_colors <- list(
  threshold   = "#2E75A8", # the dwell bout threshold circle
  bout_area   = "#234023", # the bout's own bounding circle, and its trace
  bout_period = "grey80", # the shaded span of the bout
  mean_cpe    = "#B5835A", # the mean counts-per-epoch reference line
  active      = "#D98E73", # the active-counts threshold line
  gps_trace   = "#3C6E9F" # a GPS track
)

#' Turn a bout category into a title
#'
#' `walk_bout` becomes `Walk Bout`.
#'
#' @param category A bout category string.
#'
#' @returns A title-cased string.
#'
#' @keywords internal
format_bout_category <- function(category) {
  if (is.na(category)) {
    return("Uncategorised Bout")
  }
  words <- strsplit(gsub("_", " ", category), " ")[[1]]
  paste(toupper(substring(words, 1, 1)), substring(words, 2), sep = "", collapse = " ")
}

#' Project latitude and longitude onto local feet
#'
#' An equirectangular approximation centred on a reference point. Accurate enough
#' over the few hundred feet a bout spans, and it lets GPS points and a radius in
#' feet share one coordinate system.
#'
#' @param latitude,longitude Coordinates to project, in decimal degrees.
#' @param center_lat,center_long The reference point the result is measured from.
#'
#' @returns A data frame with columns `x` and `y`, in feet from the reference point.
#'
#' @keywords internal
project_to_feet <- function(latitude, longitude, center_lat, center_long) {
  meters_per_degree_lat <- 111320
  meters_per_degree_long <- 111320 * cos(center_lat * pi / 180)
  data.frame(
    x = measurements::conv_unit((longitude - center_long) * meters_per_degree_long, "m", "ft"),
    y = measurements::conv_unit((latitude - center_lat) * meters_per_degree_lat, "m", "ft")
  )
}

#' Run the pipeline and return each bout's radius, category and median speed
#'
#' Shared by the plotting functions, which all need the same three things.
#'
#' @param accelerometry_counts A data frame of accelerometry counts.
#' @param gps_data A data frame of GPS data.
#' @param collated_arguments A list of collated arguments.
#'
#' @returns A list with `walk_bouts` (every epoch, with `bout`) and `bout_summary`
#'   (one row per bout, with `bout_radius`, `bout_category` and `median_speed`).
#'
#' @keywords internal
summarise_bouts_for_plotting <- function(accelerometry_counts, gps_data, collated_arguments) {
  bouts <- process_accelerometry_counts_into_bouts(accelerometry_counts, collated_arguments = collated_arguments)
  gps_epochs <- process_gps_data_into_gps_epochs(gps_data, collated_arguments = collated_arguments)

  walk_bouts <- bouts %>%
    dplyr::left_join(gps_epochs, by = "time") %>%
    dplyr::arrange(time) %>%
    dplyr::mutate(bout = ifelse(bout == 0, NA, bout))

  if (all(is.na(walk_bouts$bout))) {
    return(list(walk_bouts = walk_bouts, bout_summary = NULL))
  }

  bout_radii <- generate_bout_radius(walk_bouts, collated_arguments$dwellbout_radii_quantile)
  gps_completeness <- evaluate_gps_completeness(
    walk_bouts,
    collated_arguments$min_gps_obs_within_bout,
    collated_arguments$min_gps_coverage_ratio
  )
  categories <- generate_bout_category(
    walk_bouts, bout_radii, gps_completeness,
    collated_arguments$max_dwellbout_radii_ft,
    collated_arguments$max_walking_cpe,
    collated_arguments$min_walking_speed_km_h,
    collated_arguments$max_walking_speed_km_h
  ) %>%
    dplyr::distinct(bout, bout_category)

  bout_summary <- bout_radii %>%
    dplyr::left_join(gps_completeness, by = "bout") %>%
    dplyr::left_join(categories, by = "bout") %>%
    dplyr::filter(!is.na(bout))

  list(walk_bouts = walk_bouts, bout_summary = bout_summary)
}


#' Plot an activity bout against the active-counts threshold
#'
#' Draws the accelerometry trace around one bout, with the bout period shaded and
#' the active-counts threshold marked. The shaded span is computed by
#' `process_accelerometry_counts_into_bouts()`, so the figure shows what the
#' algorithm actually found rather than a hand-picked window.
#'
#' @param accelerometry_counts A data frame of accelerometry counts.
#' @param bout_number Which bout to draw. Defaults to the first.
#' @param leading_minutes Minutes of context to show before the bout starts.
#' @param trailing_minutes Minutes of context to show after the bout ends.
#' @param ... Additional named arguments passed through to the pipeline.
#' @param collated_arguments A list of collated arguments. Optional.
#'
#' @returns A ggplot object.
#'
#' @export
generate_activity_bout_plot <- function(accelerometry_counts, bout_number = 1,
                                        leading_minutes = 4, trailing_minutes = 4,
                                        ..., collated_arguments = NULL) {
  collated_arguments <- collate_arguments(..., collated_arguments = collated_arguments)

  bouts <- process_accelerometry_counts_into_bouts(
    accelerometry_counts,
    collated_arguments = collated_arguments
  ) %>%
    dplyr::mutate(bout = ifelse(bout == 0, NA, bout))

  bout_epochs <- bouts %>% dplyr::filter(bout == bout_number)
  if (nrow(bout_epochs) == 0) {
    stop("No bout numbered ", bout_number, " in these accelerometry counts.", call. = FALSE)
  }

  time_zone <- collated_arguments$local_time_zone
  bout_start <- lubridate::with_tz(min(bout_epochs$time), tz = time_zone)
  bout_end <- lubridate::with_tz(max(bout_epochs$time), tz = time_zone)
  window_start <- bout_start - lubridate::minutes(leading_minutes)
  window_end <- bout_end + lubridate::minutes(trailing_minutes)

  window <- bouts %>%
    dplyr::mutate(time = lubridate::with_tz(time, tz = time_zone)) %>%
    dplyr::filter(time >= window_start, time <= window_end)

  ggplot2::ggplot(window, ggplot2::aes(x = time, y = activity_counts)) +
    ggplot2::annotate("rect",
      xmin = bout_start, xmax = bout_end, ymin = 0, ymax = Inf,
      fill = bout_plot_colors$bout_period, alpha = 0.6
    ) +
    ggplot2::geom_line() +
    ggplot2::geom_point() +
    ggplot2::geom_hline(
      yintercept = collated_arguments$active_counts_per_epoch_min,
      linetype = "dashed", linewidth = 1.5, color = bout_plot_colors$threshold
    ) +
    ggplot2::labs(
      title = "Accelerometer Counts by Time",
      x = paste0("Time (", format(bout_start, "%Z"), ")"),
      y = "Accelerometer Counts (CPE)"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))
}


#' Plot a dwell bout and a walk bout against the dwell threshold
#'
#' Two bouts side by side on a shared scale, each showing its GPS track, the
#' circle containing its GPS points, and the dwell bout threshold circle. A bout
#' whose circle is larger than the threshold is a candidate walk bout; one whose
#' circle is smaller stayed in one place.
#'
#' Both bouts come from the pipeline, so the circles are the radii
#' `generate_bout_radius()` computed, not illustrations.
#'
#' @param accelerometry_counts A data frame of accelerometry counts.
#' @param gps_data A data frame of GPS data.
#' @param small_bout,large_bout Bout numbers to draw on the left and right. By
#'   default the smallest and largest bounding circles in the data.
#' @param ... Additional named arguments passed through to the pipeline.
#' @param collated_arguments A list of collated arguments. Optional.
#'
#' @returns A ggplot object.
#'
#' @export
generate_dwell_vs_walk_plot <- function(accelerometry_counts, gps_data,
                                        small_bout = NULL, large_bout = NULL,
                                        ..., collated_arguments = NULL) {
  collated_arguments <- collate_arguments(..., collated_arguments = collated_arguments)
  pieces <- summarise_bouts_for_plotting(accelerometry_counts, gps_data, collated_arguments)

  bout_summary <- pieces$bout_summary
  if (is.null(bout_summary) || nrow(bout_summary) < 2) {
    stop("Need at least two bouts with GPS data to compare; found ",
      if (is.null(bout_summary)) 0 else nrow(bout_summary), ".",
      call. = FALSE
    )
  }

  usable <- bout_summary %>% dplyr::filter(!is.na(bout_radius))
  ordered <- usable[order(usable$bout_radius), ]
  if (is.null(small_bout)) small_bout <- ordered$bout[1]
  if (is.null(large_bout)) large_bout <- ordered$bout[nrow(ordered)]

  threshold_ft <- collated_arguments$max_dwellbout_radii_ft
  panels <- list(
    list(bout = small_bout, side = "left"),
    list(bout = large_bout, side = "right")
  )

  radii <- vapply(panels, function(p) {
    usable$bout_radius[usable$bout == p$bout][1]
  }, numeric(1))
  # Lay the two panels out on one shared scale, so the threshold circle is the
  # same size in both and the comparison between them means something.
  panel_extent <- pmax(radii, threshold_ft)
  separation <- 1.25 * (panel_extent[1] + panel_extent[2])

  trace_rows <- list()
  circle_rows <- list()
  label_rows <- list()

  for (i in seq_along(panels)) {
    bout_id <- panels[[i]]$bout
    offset <- if (i == 1) 0 else separation

    points <- pieces$walk_bouts %>%
      dplyr::filter(bout == bout_id, !is.na(latitude), !is.na(longitude)) %>%
      dplyr::arrange(time)

    center_lat <- stats::median(points$latitude)
    center_long <- stats::median(points$longitude)
    local <- project_to_feet(points$latitude, points$longitude, center_lat, center_long)
    local$x <- local$x + offset
    local$what <- "GPS trace"
    trace_rows[[i]] <- cbind(local, panel = i)

    circle_rows[[i]] <- data.frame(
      x0 = offset, y0 = 0,
      r = c(threshold_ft, radii[i]),
      what = c(
        paste0(threshold_ft, "' radius"),
        "Circle containing 95% of GPS points"
      )
    )

    category <- usable$bout_category[usable$bout == bout_id][1]
    label_rows[[i]] <- data.frame(
      x = offset,
      y = NA_real_, # filled in below, once both panels' extents are known
      label = format_bout_category(category)
    )
  }

  traces <- do.call(rbind, trace_rows)
  circles <- do.call(rbind, circle_rows)
  labels <- do.call(rbind, label_rows)
  labels$y <- max(panel_extent) * 1.15

  level_order <- c(
    "GPS trace",
    paste0(threshold_ft, "' radius"),
    "Circle containing 95% of GPS points"
  )
  traces$what <- factor(traces$what, levels = level_order)
  circles$what <- factor(circles$what, levels = level_order)

  palette <- stats::setNames(
    c(bout_plot_colors$gps_trace, bout_plot_colors$mean_cpe, bout_plot_colors$bout_area),
    level_order
  )
  line_types <- stats::setNames(c("solid", "dotted", "dashed"), level_order)

  ggplot2::ggplot() +
    ggforce::geom_circle(
      data = circles,
      ggplot2::aes(x0 = x0, y0 = y0, r = r, color = what, linetype = what),
      fill = NA, linewidth = 1
    ) +
    ggplot2::geom_path(
      data = traces,
      ggplot2::aes(x = x, y = y, group = panel, color = what, linetype = what),
      linewidth = 0.4
    ) +
    ggplot2::geom_text(
      data = labels, ggplot2::aes(x = x, y = y, label = label),
      size = 5, vjust = 0
    ) +
    ggplot2::scale_color_manual(values = palette, drop = FALSE) +
    ggplot2::scale_linetype_manual(values = line_types, drop = FALSE) +
    ggplot2::coord_fixed() +
    ggplot2::labs(color = NULL, linetype = NULL) +
    ggplot2::theme_void() +
    ggplot2::theme(
      legend.position = "bottom",
      legend.text = ggplot2::element_text(size = 11)
    )
}


#' Generate Bout Plot
#'
#' Draws one bout in full: its accelerometry trace, the bout period shaded, the
#' active-counts threshold, the bout's mean counts per epoch, and an inset
#' comparing the bout's GPS bounding circle with the dwell bout threshold.
#'
#' @param accelerometry_counts A data frame or tibble containing accelerometry counts.
#' @param gps_data A data frame or tibble containing GPS data.
#' @param bout_number The number of the bout to be plotted.
#' @param leading_minutes number of minutes before a bout starts that we want to plot
#' @param trailing_minutes number of minutes after a bout ends that we want to plot
#' @param gps_target_size proportional size of circle plot
#' @param ... Additional arguments to be passed to the function
#' @param collated_arguments A list of collated arguments
#'
#' @return A ggplot object representing the bout plot.
#'
#' @export
generate_bout_plot <- function(accelerometry_counts, gps_data, bout_number, leading_minutes = 8,
                               trailing_minutes = 12, gps_target_size = 0.25,
                               ..., collated_arguments = NULL) {
  b <- bout_number
  collated_arguments <- collate_arguments(..., collated_arguments = collated_arguments)
  pieces <- summarise_bouts_for_plotting(accelerometry_counts, gps_data, collated_arguments)
  walk_bouts <- pieces$walk_bouts

  # if there are no bouts, just return the data
  if (is.null(pieces$bout_summary)) {
    return(walk_bouts)
  }

  this_bout <- pieces$bout_summary %>% dplyr::filter(bout == b)
  if (nrow(this_bout) == 0) {
    stop("No bout numbered ", b, " in these data.", call. = FALSE)
  }

  df <- walk_bouts %>%
    dplyr::filter(bout == b) %>%
    dplyr::select(c("latitude", "longitude", "bout", "time", "activity_counts"))

  bout_radius <- this_bout$bout_radius[1]
  complete_gps <- this_bout$complete_gps[1]
  median_speed <- this_bout$median_speed[1]
  mean_cpe <- mean(df$activity_counts, na.rm = TRUE)

  # proportionally scale down the values to make plotting faster
  bout_thresh_ratio <- collated_arguments$max_dwellbout_radii_ft / bout_radius
  plot_bout_radius <- .1 * bout_radius
  plot_max_dwellbout_radii_ft <- bout_thresh_ratio * plot_bout_radius

  # One row draws one circle. This used to be thousands of rows, whose x0/y0/alpha
  # columns were never read: the aes() below fixes the centre at the origin, so every
  # row redrew the same circle on top of the last and ggplot warned on each call.
  plot_dat_b <- data.frame(x0 = 0, y0 = 0)
  p <- ggplot2::ggplot() +
    ggplot2::coord_fixed() +
    ggplot2::theme_void()
  thresh_circle <- ggforce::geom_circle(
    data = plot_dat_b, ggplot2::aes(x0 = 0, y0 = 0, r = plot_max_dwellbout_radii_ft),
    color = bout_plot_colors$threshold, fill = bout_plot_colors$threshold
  )
  bout_circle <- ggforce::geom_circle(
    data = plot_dat_b, ggplot2::aes(x0 = 0, y0 = 0, r = plot_bout_radius),
    color = bout_plot_colors$bout_area, fill = bout_plot_colors$bout_area
  )

  # Draw the smaller circle last so it stays visible inside the larger one.
  if (isTRUE(complete_gps) && !is.na(bout_radius)) {
    if (plot_max_dwellbout_radii_ft > plot_bout_radius) {
      circles <- p + thresh_circle + bout_circle
      title_color <- bout_plot_colors$threshold
    } else {
      circles <- p + bout_circle + thresh_circle
      title_color <- bout_plot_colors$bout_area
    }
    title <- paste0(
      format_bout_category(this_bout$bout_category[1]),
      " (radius = ", round(bout_radius, 2), " feet",
      if (is.finite(median_speed)) paste0(", median speed = ", round(median_speed, 2)) else "",
      ")"
    )
  } else {
    circles <- p + thresh_circle
    title <- "Incomplete GPS Coverage"
    title_color <- bout_plot_colors$threshold
  }

  ## ACCELEROMETRY PLOT
  time_zone <- collated_arguments$local_time_zone
  df <- df %>% dplyr::mutate(time = lubridate::with_tz(time, tz = time_zone))
  bout_start <- min(df$time)
  bout_end <- max(df$time)
  start <- bout_start - lubridate::minutes(leading_minutes)
  end <- bout_end + lubridate::minutes(trailing_minutes)

  df <- df %>% dplyr::filter(time >= start, time <= end)

  xmin <- start + (1 - gps_target_size) * as.numeric(difftime(end, start, units = "secs"))
  y_low <- 0
  y_high <- max(df$activity_counts, na.rm = TRUE) * 1.2
  ymax <- y_high
  ymin <- (1 - gps_target_size) * y_high

  # The legend is drawn as text in the right-hand margin rather than a ggplot
  # legend, so it can sit under the circle inset and beside the two reference
  # lines it describes.
  legend_x <- xmin
  legend_entries <- data.frame(
    y = ymin - c(0.06, 0.13, 0.20) * y_high,
    label = c("Dwell bout threshold", "Bout area", "Bout period"),
    color = c(
      bout_plot_colors$threshold,
      bout_plot_colors$bout_area,
      "grey45"
    )
  )

  ggplot2::ggplot(df, ggplot2::aes(x = time, y = activity_counts)) +
    ggplot2::annotate("rect",
      xmin = bout_start, xmax = bout_end, ymin = y_low, ymax = y_high * 0.88,
      fill = bout_plot_colors$bout_period, alpha = 0.7
    ) +
    ggplot2::geom_line(color = bout_plot_colors$bout_area) +
    ggplot2::geom_point(color = bout_plot_colors$bout_area, size = 1) +
    # Segments rather than hlines: they stop short of the legend column on the
    # right, so a reference line never runs underneath the legend text.
    ggplot2::annotate("segment",
      x = start, xend = legend_x,
      y = collated_arguments$active_counts_per_epoch_min,
      yend = collated_arguments$active_counts_per_epoch_min,
      linetype = "dashed", color = bout_plot_colors$active
    ) +
    ggplot2::annotate("segment",
      x = start, xend = legend_x, y = mean_cpe, yend = mean_cpe,
      linetype = "dotted", color = bout_plot_colors$mean_cpe, linewidth = 1
    ) +
    # The two reference lines are labelled on the left, where the lead-in period
    # leaves the panel empty. Putting them on the right next to the legend meant
    # they collided with it whenever the mean sat near the top of the range.
    ggplot2::annotate("text",
      x = start, y = collated_arguments$active_counts_per_epoch_min,
      label = paste0("Active (", collated_arguments$active_counts_per_epoch_min, " CPE)"),
      hjust = 0, vjust = -0.6, size = 4
    ) +
    ggplot2::annotate("text",
      x = start, y = mean_cpe, label = "Mean bout CPE",
      hjust = 0, vjust = -0.6, size = 4
    ) +
    ggplot2::annotate("text",
      x = legend_x, y = legend_entries$y, label = legend_entries$label,
      color = legend_entries$color, hjust = 0, vjust = 1, size = 4
    ) +
    ggplot2::scale_x_datetime(limits = c(start, end)) +
    ggplot2::ylim(y_low, y_high) +
    ggplot2::ggtitle(title) +
    ggplot2::labs(
      x = paste0("Time (", format(bout_start, "%Z"), ")"),
      y = "Accelerometer Counts (CPE)"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      legend.position = "none",
      plot.title = ggplot2::element_text(color = title_color)
    ) +
    ggplot2::annotation_custom(ggplot2::ggplotGrob(circles),
      xmin = as.numeric(xmin), xmax = as.numeric(end),
      ymin = ymin, ymax = ymax
    )
}
