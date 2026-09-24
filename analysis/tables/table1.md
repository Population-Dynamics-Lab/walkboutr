|Column          |Class     |Definition                                                                                                                                                                  |
|:---------------|:---------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|bout            |Numeric   |A label for each walk bout. Each bout is sequentially numbered for easier identification. NA where the epoch is not part of a bout.                                         |
|bout_category   |Character |The category of the bout, as defined below.                                                                                                                                 |
|activity_counts |Numeric   |Accelerometer counts in counts per epoch (CPE).                                                                                                                             |
|time            |Date-time |The epoch start time, as a date-time in the UTC time zone.                                                                                                                  |
|non_wearing     |Logical   |Boolean flag for whether the device was not being worn at the time (non_wearing = TRUE).                                                                                    |
|complete_day    |Logical   |Boolean flag for whether the calendar day of data was complete, assessed by whether the device was worn for more than min_wearing_hours_per_day hours, which defaults to 8. |
|latitude        |Numeric   |Latitude coordinate for the epoch, from the GPS data.                                                                                                                       |
|longitude       |Numeric   |Longitude coordinate for the epoch, from the GPS data.                                                                                                                      |
|speed           |Numeric   |Speed at this epoch in kilometres per hour, from the GPS data.                                                                                                              |

**Table 1. Complete, epoch-level dataset.** The first column contains the dataset column names, the second column contains the object class of each dataset feature, and the final column provides a definition of each feature.
