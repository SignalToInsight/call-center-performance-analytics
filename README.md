
# CALL CENTER PERFORMANCE ANALYTICS

*SQL Portfolio Project 1 | Microsoft SQL Server | Synthetic Data*

## Project Overview

This project analyzes interval-level call-center performance to identify when service level falls below a 95% target and how workload, staffing, average handling time (AHT), and abandonment differ between stronger- and weaker-performing intervals. It demonstrates practical SQL analysis and business interpretation in a familiar operations domain.

The working dataset contains 1,800 records across 90 days, with 20 half-hour intervals per day. The dataset is synthetic and is not based on confidential employer production records.

## Business Question

Which operating conditions are associated with service-level intervals falling below 95%, and where should operations leaders investigate workload and staffing alignment?

## Objectives

- Measure the share of intervals at or above the 95% service-level target.
- Compare calls offered per staffed agent, average staffing, AHT, and abandonment between performance groups.
- Identify recurring weekdays and half-hour intervals with frequent service-level misses.
- Demonstrate a relational INNER JOIN using a clearly labeled hypothetical staffing scenario.
- Translate findings into practical next steps without confusing association with causation.

## Data Model

### Source table: `dbo.Call_Center_Performance_Project1`

The source table contains one record per date and half-hour interval. Its columns are `Date`, `Interval`, `Calls_Offered`, `Calls_Answered`, `Abandoned`, `Agents_Staffed`, `Avg_Handle_Time_Sec`, `Service_Level`, `Abandon_Rate`, `Day_of_Week`, and `Month`.

### Scenario table: `dbo.Staffing_Schedule_Project1`

The script creates a second table for JOIN practice. Its baseline staffing value is copied from `Agents_Staffed` as a proxy, not a verified scheduled headcount. A hypothetical scenario adds two agents on weekdays during the 10:00–11:30 intervals. This is a what-if scenario—not historical schedule data and not evidence that adding staff would cause a particular service-level improvement.

**Join key: work date and interval.** The script includes a duplicate-key check because multiple records for the same date and interval could multiply rows in a join.

## Findings from the Existing Analysis

The following values are from the earlier analysis of the current dataset. Run the supplied SQL against the active database to reproduce and verify them before publishing.

| Measure | At/above 95% target | Below 95% target |
|---|---:|---:|
| Intervals | 1,033 (57.4%) | 767 (42.6%) |
| Calls offered per staffed agent | 2.9339 | 4.0618 |
| Average agents staffed | 15.03 | 13.87 |
| Average AHT | 405.6 seconds | 434.6 seconds |
| Average abandon rate | 4.08% | 7.44% |

Interpretation: below-target intervals had higher average workload per staffed agent, lower average staffing, higher AHT, and higher abandonment. These are associations in the dataset; the analysis does not independently prove that any one factor caused the service-level miss.

## Recurring Risk Patterns

The prior interval analysis identified 10:30, 11:00, 11:30, and 12:00 as the half-hour intervals with the largest counts of below-target observations. Previously reported weekday counts were Wednesday 163, Thursday 152, Tuesday 149, Friday 131, Monday 76, Saturday 56, and Sunday 40.

These are counts, not rates. When comparing weekdays, consider the number of observations in each group. The earlier hourly summary showed average service level rising from approximately 78.6% at 08:00 to 97.3% at 21:00. The previously calculated workload/service-level correlation was approximately -0.96, indicating a strong inverse association in this dataset—not proof of causation.

## SQL Techniques Demonstrated

- Aggregation using `COUNT`, `SUM`, and `AVG`.
- `CASE` expressions to classify intervals and normalize percentage formats.
- `NULLIF` to protect ratios from division by zero.
- Date and interval grouping to identify recurring risk periods.
- Common table expressions (CTEs) to make query logic easier to follow.
- `INNER JOIN` using date and interval keys.
- Data-quality checks for invalid values and duplicate interval keys.

## Recommendations for Operations Leaders

- Investigate recurring late-morning intervals first, validating arrival patterns, forecast accuracy, staffing availability, and non-production time.
- Review AHT and call mix during below-target intervals before assuming staffing alone explains performance.
- Compare scheduled staffing with actual staffed capacity once a validated schedule table is available.
- Consider a controlled staffing or activity-staggering pilot during repeated high-risk periods, with before-and-after measurement.
- Track service level, abandonment, workload per available agent, and customer impact together rather than optimizing a single metric.

## Limitations

- **Synthetic data:** The dataset is designed for portfolio and learning purposes and does not represent an actual employer's production environment.
- **Descriptive analysis:** The results identify patterns and relationships in the data but do not establish that any single factor caused a service-level miss.
- **Hypothetical staffing scenario:** The baseline staffing value uses the observed staffed-agent count as a proxy rather than a verified staffing schedule.
- **Scenario interpretation:** The staffing comparison measures hypothetical workload per agent. It does not predict service-level improvement or establish the operational impact of adding staff.

## Execution

The SQL script was developed and validated in Microsoft SQL Server Management Studio (SSMS). It analyzes the source performance table and creates a hypothetical staffing scenario for comparison.

To reproduce the analysis, execute `Project1_CallCenter_Final.sql` in the database containing `dbo.Call_Center_Performance_Project1`.

**Note:** Running the script drops and recreates `dbo.Staffing_Schedule_Project1`, replacing any existing contents of that scenario table.

## Suggested Repository Structure

- `README.md` — portfolio summary and interpretation.
- `README.docx` — editable Word version.
- `Project1_CallCenter_Final.sql` — SQL analysis.
- `data/` — synthetic or openly licensed data only.
- `images/` — optional charts created from the synthetic dataset.

## Portfolio Summary

This project uses SQL Server to investigate patterns associated with call-center service-level performance below a 95% target. The analysis combines data-quality checks, performance comparisons, time-based risk analysis, and a JOIN with a hypothetical staffing scenario.

The findings show that below-target intervals were associated with higher workload per staffed agent, lower average staffing, higher average handle time, and higher abandonment. The project demonstrates how SQL can turn operational data into actionable questions for further investigation while distinguishing observed patterns from proven causes.

The complete SQL script was executed successfully in SQL Server during project validation. The dataset is synthetic, and the hypothetical staffing scenario illustrates a workload comparison rather than a prediction of service-level improvement.
