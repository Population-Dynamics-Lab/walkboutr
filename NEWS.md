# walkboutr 0.6.0

## Output-changing fixes

Bout classification differs from 0.5.0. Results produced with 0.5.0 are not comparable
to results produced with this version.

* `evaluate_gps_completeness()` now requires **both** GPS criteria to hold. It previously
  combined them with an OR, so a bout passed on either the record count or the coverage
  ratio alone. Both thresholds are also now inclusive (`>=` rather than `>`), matching
  their documented meaning as minimums: a bout with exactly `min_gps_obs_within_bout`
  observations passes. A bout with no usable GPS is now incomplete rather than complete.
  Because `non_walk_incomplete_gps` is the highest-precedence category, this classifies
  more bouts as incomplete and yields fewer walk bouts.

* `generate_bout_radius()` iterated over the columns of a data frame rather than its bout
  labels, so the loop ran once and every bout received the same radius. Each bout now gets
  its own bounding-circle radius.

* `identify_complete_days()` used `nrow(.)` inside a grouped summary, which returns the
  row count of the whole dataset rather than of each group. Every calendar day therefore
  shared one epoch count, corrupting `complete_day`. It now uses the per-group count, so a
  partial day is correctly reported as incomplete.

* `identify_non_wearing_periods()` overwrote the `non_wearing` flag on each iteration
  instead of accumulating, so only the final non-wearing period survived. All non-wearing
  periods are now retained.

* `generate_gps_data()` drew its first speed before calling `set.seed()`, so output was not
  reproducible despite the `seed` argument. The seed is now set before any draw, and two
  calls with the same seed return identical data.

* `generate_walking_in_seattle_gps_data()` used a positive Seattle longitude (`122.3321`),
  placing the generated walk in western China. It is now `-122.3321`. Its three arguments
  were also overwritten inside the body before use; they are now real defaults, so passing
  a start location has an effect.

## Other fixes

* `generate_bout_plot()` plotted every bout in the dataset rather than the requested
  `bout_number`, and discarded any parameters the caller passed.

* `collate_arguments()` silently discarded unnamed arguments, so
  `process_accelerometry_counts_into_bouts(acc, collated_arguments$epoch_length)` appeared
  to set the epoch length and did nothing. Unnamed arguments now raise an error, and the
  error messages for conflicting and unknown arguments name the offending argument.

* `validate_gps_data()` rejected an integer `latitude` column while accepting an integer
  `longitude` column. Both now accept integer or numeric.

* The internal `inactive` and `n_epochs_date` columns no longer leak into the returned
  walk bout data frame.

# walkboutr 0.5.0

# walkboutr 0.4.0

# walkboutr 0.3.0

# walkboutr 0.2.0

# walkboutr 0.1.0

# walkboutr 0.0.0.9000

* Added a `NEWS.md` file to track changes to the package.
