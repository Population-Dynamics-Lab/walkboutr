# Generate the data dictionary tables in paper.md from the pipeline's real output.
#
#   Rscript analysis/make_tables.R      (or: make tables)
#
# Column names, order and classes are read off the actual output, so they cannot
# drift from what the code produces. Only the prose definitions are authored, in
# analysis/data_dictionary.csv.
#
# The script stops if the dictionary and the output disagree in either direction:
# a column with no definition, or a definition for a column that does not exist.
# That check is the point of the exercise. paper.md's Table 1 claimed the
# epoch-level dataset contained bout_start, median_speed and duration, which are
# summarize_walk_bouts() columns, and omitted time and speed, which it does have.

source(if (file.exists("load.R")) "load.R" else "../load.R")

dictionary <- utils::read.csv(
  file.path(WALKBOUTR_ROOT, "analysis", "data_dictionary.csv"),
  stringsAsFactors = FALSE
)

example_data <- make_dwell_and_walk_example()
epoch_level <- identify_walk_bouts_in_gps_and_accelerometry_data(
  example_data$gps_data, example_data$accelerometry_counts
)
bout_level <- summarize_walk_bouts(epoch_level)

#' Build one dictionary table from a data frame and the authored definitions.
build_table <- function(data, dataset_name) {
  defined <- dictionary[dictionary$dataset == dataset_name, ]

  undocumented <- setdiff(names(data), defined$column)
  stale <- setdiff(defined$column, names(data))
  if (length(undocumented) > 0 || length(stale) > 0) {
    stop(
      "analysis/data_dictionary.csv is out of step with the ", dataset_name,
      "-level output.\n",
      if (length(undocumented)) paste0("  No definition for: ", toString(undocumented), "\n"),
      if (length(stale)) paste0("  Defined but not returned: ", toString(stale), "\n"),
      call. = FALSE
    )
  }

  data.frame(
    Column = names(data),
    Class = vapply(data, function(column) {
      switch(class(column)[1],
        numeric = "Numeric", integer = "Integer", character = "Character",
        logical = "Logical", POSIXct = "Date-time", class(column)[1]
      )
    }, character(1)),
    Definition = defined$definition[match(names(data), defined$column)],
    row.names = NULL,
    stringsAsFactors = FALSE
  )
}

output_dir <- file.path(WALKBOUTR_ROOT, "analysis", "tables")
dir.create(output_dir, showWarnings = FALSE)

tables <- list(
  table1 = list(
    data = build_table(epoch_level, "epoch"),
    caption = paste(
      "**Table 1. Complete, epoch-level dataset.** The first column contains the dataset",
      "column names, the second column contains the object class of each dataset feature,",
      "and the final column provides a definition of each feature."
    )
  ),
  table2 = list(
    data = build_table(bout_level, "bout"),
    caption = paste(
      "**Table 2. Summary, bout-level dataset.** The first column contains the dataset",
      "column names, the second column contains the object class of each dataset feature,",
      "and the final column provides a definition of each feature."
    )
  )
)

for (name in names(tables)) {
  path <- file.path(output_dir, paste0(name, ".md"))
  writeLines(
    c(knitr::kable(tables[[name]]$data, format = "pipe"), "", tables[[name]]$caption),
    path
  )
  cat("wrote", path, "-", nrow(tables[[name]]$data), "rows\n")
}
