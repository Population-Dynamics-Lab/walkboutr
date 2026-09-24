# Regenerate README.md and R/README.md from README.Rmd.
#
#   Rscript render_readme.R      (or: make readme)
#
# README.Rmd is the only file you edit. This renders it to README.md, then lifts
# the section between the BEGIN/END R/README markers into R/README.md, so that
# GitHub also shows that guide when someone browses into the R/ folder. Headings
# are promoted one level on the way, since the section sits under a heading here
# and is the whole document there.
#
# Needs pandoc (brew install pandoc).

rmarkdown::render("README.Rmd", output_file = "README.md", quiet = TRUE)

lines <- readLines("README.md", warn = FALSE)
# Match anywhere on the line: pandoc will fold a comment into the preceding
# paragraph if the source did not leave a blank line before it.
begin <- grep("<!-- BEGIN R/README -->", lines, fixed = TRUE)
end <- grep("<!-- END R/README -->", lines, fixed = TRUE)

if (length(begin) != 1 || length(end) != 1) {
  stop("Expected exactly one BEGIN and one END R/README marker in README.md; ",
       "found ", length(begin), " and ", length(end), ".", call. = FALSE)
}

section <- lines[seq(begin + 1, end - 1)]
# Drop the marker text itself if it ended up on a content line.
section <- sub("\\s*<!-- (BEGIN|END) R/README -->", "", section)

in_code <- FALSE
for (i in seq_along(section)) {
  if (grepl("^```", section[i])) in_code <- !in_code
  if (!in_code) section[i] <- sub("^##", "#", section[i])
}

writeLines(
  c(
    "<!-- Generated from README.Rmd by render_readme.R. Do not edit by hand. -->",
    "",
    trimws(section, which = "right")
  ),
  "R/README.md"
)

cat("README.md and R/README.md written\n")
