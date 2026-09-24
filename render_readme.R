# Regenerate README.md from README.Rmd.
#
#   Rscript render_readme.R      (or: make readme)
#
# README.Rmd is the only README you edit. README.md is generated from it and is
# what GitHub shows; do not edit it by hand.
#
# Needs pandoc (brew install pandoc).

rmarkdown::render("README.Rmd", output_file = "README.md", quiet = TRUE)
cat("README.md written\n")
