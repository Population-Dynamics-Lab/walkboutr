# Regenerate README.md from README.Rmd.
#
#   Rscript render_readme.R      (or: make readme)
#
# README.Rmd pulls in R/README.md, so the guide to the R/ directory is written
# once, renders on GitHub when browsing into R/, and appears on the landing page
# too. Editing either source and re-running this keeps them in step.
#
# Needs pandoc (brew install pandoc).

rmarkdown::render("README.Rmd", output_file = "README.md", quiet = TRUE)
cat("README.md written\n")
