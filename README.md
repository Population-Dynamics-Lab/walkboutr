
<!-- README.md is generated from README.Rmd. Please edit that file, then run:
     Rscript render_readme.R   (or: make readme)  -->

# `walkboutr`

<!-- badges: start -->

<!-- badges: end -->

`walkboutr` turns GPS and accelerometry data into walking bouts. It
returns either the original dataset with bout labels and categories
attached, or a summarized, de-identified dataset that can be shared for
collaboration.

## Running the pipeline

The pipeline is **sourced, not installed**. There is no package to build
and no `install.packages()` step: `load.R` reads everything in `R/` into
your session.

### With repo2docker and RStudio (recommended)

This is the standard PDL path. It builds an image with R, RStudio and
every dependency, then hands you a browser-based RStudio session.

``` bash
repo2docker https://github.com/Population-Dynamics-Lab/walkboutr
```

Copy the link the console prints, open it, then **View \> Open Jupyter
Lab \> RStudio**. In the RStudio console:

``` r
source("load.R")    # loads the pipeline
source("smoke.R")   # runs every step and prints the result
```

`runtime.txt` pins R 4.4.1 and a Posit Package Manager snapshot date, so
package versions are fixed. `install.R` lists what gets installed.

If you are on a Mac with Apple silicon, install OrbStack first and grant
it command line access, then `uv tool install jupyter-repo2docker`.

### With the plain Dockerfile

A smaller, command-line-only image, with no RStudio or Jupyter. Based on
`rocker/geospatial`, which ships the GDAL, GEOS and PROJ libraries that
`sf`, `lwgeom` and `geosphere` need already built.

``` bash
git clone git@github.com:Population-Dynamics-Lab/walkboutr.git
cd walkboutr

make docker-build     # or: docker build -t walkboutr -f docker/Dockerfile .
make smoke            # runs every step on generated sample data
make docker-run       # an interactive R session, repo mounted at /work
```

### On your own machine

You need R 4.3 or later and the system libraries for `sf`. From the
repository root:

``` r
source("load.R")
```

That is all `smoke.R` and every example below does. `load.R` lists the
packages the pipeline needs and tells you which are missing, with the
`install.packages()` call to fix it.

## `R/` — what runs in what order

**Only three files are steps, and they are numbered.** Everything else
is supporting code called *from* those steps. There is no order to the
rest, and there does not need to be: every file here only defines
functions, except `parameters.R`, which defines two lists. Nothing
executes when a file is sourced, so `load.R` can read them in any order.

If you are reading the code for the first time, go in this order:

| Order | File | Role |
|----|----|----|
| 1 | `pipeline.R` | **Start here.** The two entry points. Shows the three steps in sequence in about five lines. |
| 2 | `parameters.R` | Every threshold the pipeline uses, in two lists. Read before the steps so the numbers in them mean something. |
| 3 | `step1_process_accelerometry_counts_into_bouts.R` | Accelerometry counts → candidate bouts. |
| 4 | `step2_process_gps_data_into_gps_epochs.R` | GPS fixes → epoch-aligned GPS. Independent of step 1. |
| 5 | `step3_process_bouts_and_gps_epochs_into_walkbouts.R` | Both of the above → categorised walk bouts. |

### Execution order

                    accelerometry_counts        gps_data
                             |                     |
                        [ step 1 ]            [ step 2 ]
                             |                     |
                           bouts              gps_epochs
                             \                    /
                              \                  /
                               +--> [ step 3 ] <-+
                                         |
                                  walk_bouts (categorised)
                                         |
                              summarize_walk_bouts()
                                         |
                             one row per bout, de-identified

Steps 1 and 2 are independent and could run in either order. Step 3
needs both.

### The supporting files

These have no position in the sequence. Each is called from the step
that needs it.

| File | Called by | What it does |
|----|----|----|
| `parameters.R` | all steps | `parameters` (overridable per call), `constants` (not overridable), and `collate_arguments()`, which merges caller overrides in. |
| `validate_accelerometry_data.R` | step 1 | Rejects malformed accelerometry input before anything else runs. |
| `validate_gps_data.R` | step 2 | The same for GPS input. |
| `plot.R` | you, directly | The three article figures, one function each. |
| `simulate_gps_data.R` | examples, `smoke.R` | Generates GPS data for a walk in Seattle. |
| `simulate_accelerometry_data.R` | examples, `smoke.R` | The `make_*` builders, each constructing a specific scenario (smallest bout, full day, non-wearing period). |
| `simulate_example_bouts.R` | the figures | Data shaped like real data, for plotting. The `make_*` builders above produce square waves and `generate_gps_data()` wanders for miles, neither of which makes a readable figure. |

### Bout categories

Assigned in `step3`. Every bout starts as `walk_bout` and each rule
overwrites the previous one, so the **last** rule to match wins. In
precedence order, highest first:

1.  `non_walk_incomplete_gps` — too few GPS records, or too little
    coverage
2.  `dwell_bout` — the bounding circle is smaller than the 66 ft
    threshold
3.  `non_walk_too_vigorous` — mean counts above the walking ceiling
4.  `non_walk_slow` — median speed below the walking floor
5.  `non_walk_fast` — median speed above the walking ceiling
6.  `walk_bout` — matched none of the above

## Basic usage

### Simulated sample data

Simulated data that `walkboutr` can process. The GPS data have the
required columns time, latitude, longitude and speed; the accelerometry
data have time and activity counts. Neither has extra columns, NAs,
negative speeds or negative counts, and all times are date-times in UTC.

``` r
source("load.R")
# generate sample gps data:
gps_data <- generate_walking_in_seattle_gps_data()
# generate sample accelerometry data:
accelerometry_counts <- make_full_day_bout_without_metadata()
```

GPS data:

| time                | latitude | longitude |     speed |
|:--------------------|---------:|----------:|----------:|
| 2012-04-07 00:00:30 | 47.60620 | -122.3321 | 1.0116654 |
| 2012-04-07 00:01:00 | 47.60996 | -122.3283 | 0.6412646 |
| 2012-04-07 00:01:30 | 47.61313 | -122.3252 | 1.6616599 |
| 2012-04-07 00:02:00 | 47.61935 | -122.3189 | 2.0068013 |
| 2012-04-07 00:02:30 | 47.62716 | -122.3111 | 1.1009735 |
| 2012-04-07 00:03:00 | 47.63253 | -122.3058 | 2.7479587 |

Accelerometry data:

| activity_counts | time                |
|----------------:|:--------------------|
|               0 | 2012-04-07 00:00:30 |
|               0 | 2012-04-07 00:01:00 |
|               0 | 2012-04-07 00:01:30 |
|               0 | 2012-04-07 00:02:00 |
|             500 | 2012-04-07 00:02:30 |
|             500 | 2012-04-07 00:03:00 |

<p>

There are two top level functions, giving either (1) a dataset with
bouts and bout categories alongside all of your original data, or (2) a
summary dataset that is de-identified and shareable.

### Walk bout dataset including original data

``` r
walk_bouts <- identify_walk_bouts_in_gps_and_accelerometry_data(gps_data, accelerometry_counts)
```

| bout | bout_category | activity_counts | time | non_wearing | complete_day | latitude | longitude | speed |
|---:|:---|---:|:---|:---|:---|---:|---:|---:|
| 1 | walk_bout | 500 | 2012-04-07 00:02:30 | FALSE | FALSE | 47.62716 | -122.3111 | 1.100974 |
| 1 | walk_bout | 500 | 2012-04-07 00:03:00 | FALSE | FALSE | 47.63253 | -122.3058 | 2.747959 |
| 1 | walk_bout | 500 | 2012-04-07 00:03:30 | FALSE | FALSE | 47.64607 | -122.2922 | 4.109610 |
| 1 | walk_bout | 500 | 2012-04-07 00:04:00 | FALSE | FALSE | 47.66240 | -122.2759 | 2.017190 |
| 1 | walk_bout | 500 | 2012-04-07 00:04:30 | FALSE | FALSE | 47.66996 | -122.2683 | 2.790143 |
| 1 | walk_bout | 500 | 2012-04-07 00:05:00 | FALSE | FALSE | 47.68312 | -122.2552 | 2.724973 |

### Summarized walk bout dataset

A set of labelled bouts, categorized (`bout_category`), with each bout’s
median speed (`median_speed`), start time (`bout_start`), duration in
minutes (`duration`), and a flag for whether the bout came from a
complete day of data (`complete_day`).

``` r
summary <- summarize_walk_bouts(walk_bouts)
```

| bout | median_speed | complete_day | bout_start | duration | bout_category |
|---:|---:|:---|:---|---:|:---|
| 1 | 2.769051 | FALSE | 2012-04-07 00:02:30 | 5.0 | walk_bout |
| 2 | 2.646649 | TRUE | 2012-04-07 00:09:30 | 4304.5 | non_walk_incomplete_gps |

This example has 2 bout(s), each with a label. Bout 1 started at
2012-04-07 00:02:30, lasted 5 minutes, and was categorized as walk_bout.
The calendar day it falls on does not have enough wearing time to count
as complete.

Bouts are categorized in precedence order, highest first:
`non_walk_incomplete_gps`, `dwell_bout`, `non_walk_too_vigorous`,
`non_walk_slow`, `non_walk_fast`. A bout matching none of those is a
`walk_bout`. For more detail see the **Generate Walk Bouts** vignette.

## Repository layout

    R/              the pipeline, numbered by step
    load.R          checks dependencies and sources R/ into your session
    smoke.R         runs every step on sample data and prints the result
    runtime.txt     R version and CRAN snapshot date, read by repo2docker
    install.R       packages repo2docker installs at build time
    docker/         an alternative command-line-only image
    Makefile        docker-build, docker-run, smoke, lint, readme
    render_readme.R regenerates README.md from README.Rmd
    docs/           longer walkthroughs, formerly the package vignettes
    paper.md        the article describing the method

`README.Rmd` is the only README you edit. It has live R chunks, so the
tables and bout counts above are computed rather than typed.
`make readme` renders it to `README.md`, which is what GitHub shows.
Editing `README.md` is pointless; the next render overwrites it.

## Reproducing the article’s figures

Each of the three figures in `paper.md` is one function call, so a
script that regenerates them needs no plotting code of its own:

``` r
example_data <- make_dwell_and_walk_example()

generate_activity_bout_plot(make_activity_bout_example(), bout_number = 1)
generate_dwell_vs_walk_plot(example_data$accelerometry_counts, example_data$gps_data)
generate_bout_plot(example_data$accelerometry_counts, example_data$gps_data, bout_number = 2)
```

Each takes raw accelerometry counts and GPS data and runs whatever
pipeline steps it needs. `make_dwell_and_walk_example()` produces a
matched pair of bouts whose bounding circles fall either side of the 66
ft dwell threshold, which is what the second figure needs in order to
show anything.

## Further reading

- [`docs/process_bouts.Rmd`](docs/process_bouts.Rmd) — bout categories
  explained in full
- [`docs/changing_default_parameters.Rmd`](docs/changing_default_parameters.Rmd)
  — the parameters you can override
- [`docs/generate_data.Rmd`](docs/generate_data.Rmd) — the simulated
  data generators
- `paper.md` — the article describing the method

## Note on the R package

`walkboutr` was published to CRAN as an R package version 0.5.0. This
repository is no longer an R package: `DESCRIPTION`, `NAMESPACE`,
`man/`, `tests/` and the pkgdown configuration have been removed, and
the vignettes now live in `docs/` as ordinary documents. The roxygen
`#'` comments in `R/` are kept as documentation, but their tags are
inert since nothing processes them.

See `NEWS.md` for version 0.6.0, which fixes bugs that change bout
classification relative to the published 0.5.0.
