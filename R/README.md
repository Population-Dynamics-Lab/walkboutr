# `R/` — what runs in what order

**Only three files are steps, and they are numbered.** Everything else is supporting
code called *from* those steps. There is no order to the rest, and there does not need
to be: every file here only defines functions, except `parameters.R`, which defines two
lists. Nothing executes when a file is sourced, so `load.R` can read them in any order.

If you are reading the code for the first time, go in this order:

| Order | File | Role |
|---|---|---|
| 1 | `pipeline.R` | **Start here.** The two entry points. Shows the three steps in sequence in about five lines. |
| 2 | `parameters.R` | Every threshold the pipeline uses, in two lists. Read before the steps so the numbers in them mean something. |
| 3 | `step1_process_accelerometry_counts_into_bouts.R` | Accelerometry counts → candidate bouts. |
| 4 | `step2_process_gps_data_into_gps_epochs.R` | GPS fixes → epoch-aligned GPS. Independent of step 1. |
| 5 | `step3_process_bouts_and_gps_epochs_into_walkbouts.R` | Both of the above → categorised walk bouts. |

## Execution order

```
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
```

Steps 1 and 2 are independent and could run in either order. Step 3 needs both.

## The supporting files

These have no position in the sequence. Each is called from the step that needs it.

| File | Called by | What it does |
|---|---|---|
| `parameters.R` | all steps | `parameters` (overridable per call), `constants` (not overridable), and `collate_arguments()`, which merges caller overrides in. |
| `validate_accelerometry_data.R` | step 1 | Rejects malformed accelerometry input before anything else runs. |
| `validate_gps_data.R` | step 2 | The same for GPS input. |
| `plot.R` | you, directly | The three article figures, one function each. See below. |
| `simulate_gps_data.R` | examples, `smoke.R` | Generates GPS data for a walk in Seattle. |
| `simulate_accelerometry_data.R` | examples, `smoke.R` | The `make_*` builders, each constructing a specific scenario (smallest bout, full day, non-wearing period). |
| `simulate_example_bouts.R` | the figures | Data shaped like real data, for plotting. The `make_*` builders above produce square waves and `generate_gps_data()` wanders for miles, neither of which makes a readable figure. |

## Plotting

Each article figure is one call, so nothing downstream has to write plotting code:

| Function | Draws |
|---|---|
| `generate_activity_bout_plot()` | An activity bout against the 500 CPE line, with the bout period shaded. The shading comes from step 1, so it shows what the algorithm found. |
| `generate_dwell_vs_walk_plot()` | Two bouts side by side on a shared scale, each with its GPS track, its bounding circle, and the 66 ft dwell threshold. |
| `generate_bout_plot()` | One bout in full: trace, bout period, mean CPE, active threshold, and the GPS radius inset. |

They take raw accelerometry counts and GPS data and run whatever pipeline steps they
need internally. `bout_plot_colors` holds the shared palette.

For data to plot, `make_activity_bout_example()` and `make_dwell_and_walk_example()`
in `simulate_example_bouts.R` produce a varied activity trace and a matched
dwell/walk pair whose radii fall either side of the 66 ft threshold.

## Bout categories

Assigned in `step3`. Every bout starts as `walk_bout` and each rule overwrites the
previous one, so the **last** rule to match wins. In precedence order, highest first:

1. `non_walk_incomplete_gps` — too few GPS records, or too little coverage
2. `dwell_bout` — the bounding circle is smaller than the 66 ft threshold
3. `non_walk_too_vigorous` — mean counts above the walking ceiling
4. `non_walk_slow` — median speed below the walking floor
5. `non_walk_fast` — median speed above the walking ceiling
6. `walk_bout` — matched none of the above

## A note on the roxygen comments

The `#'` blocks are real documentation and worth reading. Their tags (`@export`,
`@examples`) are inert: this repository is no longer built as an R package, so nothing
processes them.
