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
| `plot.R` | you, directly | `generate_bout_plot()` draws one bout against the activity threshold, with its GPS radius inset. Not part of the pipeline. |
| `simulate_gps_data.R` | examples, `smoke.R` | Generates GPS data for a walk in Seattle. |
| `simulate_accelerometry_data.R` | examples, `smoke.R` | The `make_*` builders, each constructing a specific scenario (smallest bout, full day, non-wearing period). |

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
