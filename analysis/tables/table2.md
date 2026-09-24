|Column        |Class     |Definition                                                                                                                                                                            |
|:-------------|:---------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|bout          |Numeric   |A label for each walk bout. Each bout is sequentially numbered for easier identification.                                                                                             |
|median_speed  |Numeric   |The median speed of the bout, in kilometres per hour.                                                                                                                                 |
|complete_day  |Logical   |Boolean flag for whether the calendar day the bout falls on was complete, assessed by whether the device was worn for more than min_wearing_hours_per_day hours, which defaults to 8. |
|bout_start    |Date-time |The time the bout started, as a date-time in the UTC time zone.                                                                                                                       |
|duration      |Numeric   |The length of the bout, in minutes.                                                                                                                                                   |
|bout_category |Character |The category of the bout, as defined below.                                                                                                                                           |

**Table 2. Summary, bout-level dataset.** The first column contains the dataset column names, the second column contains the object class of each dataset feature, and the final column provides a definition of each feature.
