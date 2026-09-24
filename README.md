<!-- README.md is generated from README.Rmd. Please edit that file, then run:
     Rscript render_readme.R   (or: make readme)  -->



# `walkboutr`

<!-- badges: start -->
<!-- badges: end -->

`walkboutr` turns GPS and accelerometry data into walking bouts. It returns either the
original dataset with bout labels and categories attached, or a summarized, de-identified
dataset that can be shared for collaboration.

## Running the pipeline

The pipeline is **sourced, not installed**. There is no package to build and no
`install.packages()` step: `load.R` reads everything in `R/` into your session.

### With repo2docker and RStudio (recommended)

This is the standard PDL path. It builds an image with R, RStudio and every dependency,
then hands you a browser-based RStudio session.

```bash
repo2docker https://github.com/Population-Dynamics-Lab/walkboutr
```

Copy the link the console prints, open it, then **View > Open Jupyter Lab > RStudio**.
In the RStudio console:

```r
source("load.R")    # loads the pipeline
source("smoke.R")   # runs every step and prints the result
```

`runtime.txt` pins R 4.4.1 and a Posit Package Manager snapshot date, so package versions
are fixed. `install.R` lists what gets installed.

If you are on a Mac with Apple silicon, install OrbStack first and grant it command line
access, then `uv tool install jupyter-repo2docker`.

### With the plain Dockerfile

A smaller, command-line-only image, with no RStudio or Jupyter. Based on
`rocker/geospatial`, which ships the GDAL, GEOS and PROJ libraries that `sf`, `lwgeom` and
`geosphere` need already built.

```bash
git clone git@github.com:Population-Dynamics-Lab/walkboutr.git
cd walkboutr

make docker-build     # or: docker build -t walkboutr -f docker/Dockerfile .
make smoke            # runs every step on generated sample data
make docker-run       # an interactive R session, repo mounted at /work
```

### On your own machine

You need R 4.3 or later and the system libraries for `sf`. Then:

From the repository root:

```r
source("load.R")
```

That is all `smoke.R` and every example below does. `load.R` lists the packages the
pipeline needs and tells you which are missing, with the `install.packages()` call to
fix it.

## How the pipeline works

Three steps run in order. The files in `R/` are numbered to match, so reading them top to
bottom follows the data.

| | File | In | Out |
|---|---|---|---|
| **Step 1** | `R/step1_process_accelerometry_counts_into_bouts.R` | accelerometry counts | counts + `bout`, `non_wearing`, `complete_day` |
| **Step 2** | `R/step2_process_gps_data_into_gps_epochs.R` | GPS fixes | GPS snapped to the epoch grid |
| **Step 3** | `R/step3_process_bouts_and_gps_epochs_into_walkbouts.R` | both of the above | one row per epoch with `bout_category` |

Steps 1 and 2 are independent; step 3 needs both. **Everything else in `R/` is
supporting code with no position in the sequence** — validators, the two data simulators
and the plotting function, each called from the step that needs it. Nothing runs when a
file is sourced, so load order never matters.

`R/pipeline.R` holds the two entry points that run the steps for you. Start there, then
read [`R/README.md`](R/README.md) for the full map.

Settings live in `R/parameters.R`, in two lists: `parameters`, which you can override per
call, and `constants`, which you cannot.

## Basic usage

### Simulated sample data

Simulated data that `walkboutr` can process. The GPS data have the required columns time,
latitude, longitude and speed; the accelerometry data have time and activity counts.
Neither has extra columns, NAs, negative speeds or negative counts, and all times are
date-times in UTC.


``` r
source("load.R")
# generate sample gps data:
gps_data <- generate_walking_in_seattle_gps_data()
# generate sample accelerometry data:
accelerometry_counts <- make_full_day_bout_without_metadata()
```

GPS data: 
<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> time </th>
   <th style="text-align:right;"> latitude </th>
   <th style="text-align:right;"> longitude </th>
   <th style="text-align:right;"> speed </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2012-04-07 00:00:30 </td>
   <td style="text-align:right;"> 47.60620 </td>
   <td style="text-align:right;"> -122.3321 </td>
   <td style="text-align:right;"> 1.0116654 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2012-04-07 00:01:00 </td>
   <td style="text-align:right;"> 47.60996 </td>
   <td style="text-align:right;"> -122.3283 </td>
   <td style="text-align:right;"> 0.6412646 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2012-04-07 00:01:30 </td>
   <td style="text-align:right;"> 47.61313 </td>
   <td style="text-align:right;"> -122.3252 </td>
   <td style="text-align:right;"> 1.6616599 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2012-04-07 00:02:00 </td>
   <td style="text-align:right;"> 47.61935 </td>
   <td style="text-align:right;"> -122.3189 </td>
   <td style="text-align:right;"> 2.0068013 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2012-04-07 00:02:30 </td>
   <td style="text-align:right;"> 47.62716 </td>
   <td style="text-align:right;"> -122.3111 </td>
   <td style="text-align:right;"> 1.1009735 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2012-04-07 00:03:00 </td>
   <td style="text-align:right;"> 47.63253 </td>
   <td style="text-align:right;"> -122.3058 </td>
   <td style="text-align:right;"> 2.7479587 </td>
  </tr>
</tbody>
</table>



Accelerometry data:
<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:right;"> activity_counts </th>
   <th style="text-align:left;"> time </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> 2012-04-07 00:00:30 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> 2012-04-07 00:01:00 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> 2012-04-07 00:01:30 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> 2012-04-07 00:02:00 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 500 </td>
   <td style="text-align:left;"> 2012-04-07 00:02:30 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 500 </td>
   <td style="text-align:left;"> 2012-04-07 00:03:00 </td>
  </tr>
</tbody>
</table>



<p>

There are two top level functions, giving either (1) a dataset with bouts and bout
categories alongside all of your original data, or (2) a summary dataset that is
de-identified and shareable.

### Walk bout dataset including original data


``` r
walk_bouts <- identify_walk_bouts_in_gps_and_accelerometry_data(gps_data, accelerometry_counts)
```

<table class="table table table" style="margin-left: auto; margin-right: auto; font-size: 12px; margin-left: auto; margin-right: auto; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:right;"> bout </th>
   <th style="text-align:left;"> bout_category </th>
   <th style="text-align:right;"> activity_counts </th>
   <th style="text-align:left;"> time </th>
   <th style="text-align:left;"> non_wearing </th>
   <th style="text-align:left;"> complete_day </th>
   <th style="text-align:right;"> latitude </th>
   <th style="text-align:right;"> longitude </th>
   <th style="text-align:right;"> speed </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> walk_bout </td>
   <td style="text-align:right;"> 500 </td>
   <td style="text-align:left;"> 2012-04-07 00:02:30 </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:right;"> 47.62716 </td>
   <td style="text-align:right;"> -122.3111 </td>
   <td style="text-align:right;"> 1.100974 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> walk_bout </td>
   <td style="text-align:right;"> 500 </td>
   <td style="text-align:left;"> 2012-04-07 00:03:00 </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:right;"> 47.63253 </td>
   <td style="text-align:right;"> -122.3058 </td>
   <td style="text-align:right;"> 2.747959 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> walk_bout </td>
   <td style="text-align:right;"> 500 </td>
   <td style="text-align:left;"> 2012-04-07 00:03:30 </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:right;"> 47.64607 </td>
   <td style="text-align:right;"> -122.2922 </td>
   <td style="text-align:right;"> 4.109610 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> walk_bout </td>
   <td style="text-align:right;"> 500 </td>
   <td style="text-align:left;"> 2012-04-07 00:04:00 </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:right;"> 47.66240 </td>
   <td style="text-align:right;"> -122.2759 </td>
   <td style="text-align:right;"> 2.017190 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> walk_bout </td>
   <td style="text-align:right;"> 500 </td>
   <td style="text-align:left;"> 2012-04-07 00:04:30 </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:right;"> 47.66996 </td>
   <td style="text-align:right;"> -122.2683 </td>
   <td style="text-align:right;"> 2.790143 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> walk_bout </td>
   <td style="text-align:right;"> 500 </td>
   <td style="text-align:left;"> 2012-04-07 00:05:00 </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:right;"> 47.68312 </td>
   <td style="text-align:right;"> -122.2552 </td>
   <td style="text-align:right;"> 2.724973 </td>
  </tr>
</tbody>
</table>



### Summarized walk bout dataset 

A set of labelled bouts, categorized (`bout_category`), with each bout's median speed
(`median_speed`), start time (`bout_start`), duration in minutes (`duration`), and a flag
for whether the bout came from a complete day of data (`complete_day`).


``` r
summary <- summarize_walk_bouts(walk_bouts)
```

<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:right;"> bout </th>
   <th style="text-align:right;"> median_speed </th>
   <th style="text-align:left;"> complete_day </th>
   <th style="text-align:left;"> bout_start </th>
   <th style="text-align:right;"> duration </th>
   <th style="text-align:left;"> bout_category </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 2.769051 </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> 2012-04-07 00:02:30 </td>
   <td style="text-align:right;"> 5.0 </td>
   <td style="text-align:left;"> walk_bout </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 2.646649 </td>
   <td style="text-align:left;"> TRUE </td>
   <td style="text-align:left;"> 2012-04-07 00:09:30 </td>
   <td style="text-align:right;"> 4304.5 </td>
   <td style="text-align:left;"> non_walk_incomplete_gps </td>
  </tr>
</tbody>
</table>



This example has 2 bout(s), each with a label. Bout 1 started at
2012-04-07 00:02:30, lasted
5 minutes, and was categorized as
walk_bout. The calendar day it falls on
does not have enough wearing time to count as
complete.

Bouts are categorized in precedence order, highest first: `non_walk_incomplete_gps`,
`dwell_bout`, `non_walk_too_vigorous`, `non_walk_slow`, `non_walk_fast`. A bout matching
none of those is a `walk_bout`. For more detail see the **Generate Walk Bouts** vignette.

## Repository layout

```
R/              the pipeline, numbered by step
R/README.md     what each file in R/ does, and the order to read them
load.R          checks dependencies and sources R/ into your session
smoke.R         runs every step on sample data and prints the result
runtime.txt     R version and CRAN snapshot date, read by repo2docker
install.R       packages repo2docker installs at build time
docker/         an alternative command-line-only image
Makefile        docker-build, docker-run, smoke, lint, readme
render_readme.R regenerates README.md from README.Rmd
docs/           longer walkthroughs, formerly the package vignettes
paper.md        the article describing the method
```

There are three README files and they do different jobs:

| File | |
|---|---|
| `README.Rmd` | **The one to edit.** Source for the file you are reading, with live R chunks — the tables and bout counts above are computed, not typed. |
| `README.md` | Generated from it by `make readme`. Never edit by hand; your changes are overwritten on the next render. This is what GitHub shows on the landing page. |
| `R/README.md` | A separate, hand-written guide to the `R/` directory. GitHub renders it when you browse into that folder. Nothing generates it. |

## Reproducing the article's figures

Each of the three figures in `paper.md` is one function call, so a script that
regenerates them needs no plotting code of its own:


``` r
example_data <- make_dwell_and_walk_example()

generate_activity_bout_plot(make_activity_bout_example(), bout_number = 1)
generate_dwell_vs_walk_plot(example_data$accelerometry_counts, example_data$gps_data)
generate_bout_plot(example_data$accelerometry_counts, example_data$gps_data, bout_number = 2)
```

Each takes raw accelerometry counts and GPS data and runs whatever pipeline steps it
needs. `make_dwell_and_walk_example()` produces a matched pair of bouts whose bounding
circles fall either side of the 66 ft dwell threshold, which is what the second figure
needs in order to show anything.

## Further reading

- [`R/README.md`](R/README.md) — what each file does and the order to read them in
- [`docs/process_bouts.Rmd`](docs/process_bouts.Rmd) — bout categories explained in full
- [`docs/changing_default_parameters.Rmd`](docs/changing_default_parameters.Rmd) — the
  parameters you can override
- [`docs/generate_data.Rmd`](docs/generate_data.Rmd) — the simulated data generators
- `paper.md` — the article describing the method

## Note on the R package

`walkboutr` was published to CRAN as an R package version 0.5.0. This repository is no
longer an R package: `DESCRIPTION`, `NAMESPACE`, `man/`, `tests/` and the pkgdown
configuration have been removed, and the vignettes now live in `docs/` as ordinary
documents. The roxygen `#'` comments in `R/` are kept as documentation, but their tags
are inert since nothing processes them.

See `NEWS.md` for version 0.6.0, which fixes bugs that change bout classification
relative to the published 0.5.0.
