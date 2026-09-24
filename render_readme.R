# Regenerate README.md from README.Rmd.
#
#   Rscript render_readme.R      (or: make readme)
#
# rmarkdown::render() would be the conventional route, but it needs pandoc.
# knitr::knit() needs nothing extra and produces the same body -- it just leaves
# the YAML front matter in place, where rmarkdown would consume it, so it is
# stripped here. Without that, README.md opens with a stray block that GitHub
# renders as a horizontal rule and four lines of noise.

knitr::knit("README.Rmd", output = "README.md", quiet = TRUE)

lines <- readLines("README.md", warn = FALSE)
if (length(lines) > 0 && lines[1] == "---") {
  closing <- which(lines == "---")
  if (length(closing) >= 2) {
    lines <- lines[-seq_len(closing[2])]
  }
}
# Drop any blank lines the front matter left behind at the top.
while (length(lines) > 0 && !nzchar(trimws(lines[1]))) {
  lines <- lines[-1]
}
writeLines(lines, "README.md")
cat("README.md written\n")
