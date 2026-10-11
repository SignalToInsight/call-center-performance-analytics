/*
PROJECT 1 — CALL CENTER PERFORMANCE ANALYTICS
Platform: Microsoft SQL Server

BUSINESS QUESTION
Which operating conditions are associated with intervals below a 95% service-level target,
and which recurring periods deserve further operational investigation?

REQUIREMENTS
- Run in the database containing dbo.Call_Center_Performance_Project1.
- Expected source columns: [Date], [Interval], Calls_Offered, Calls_Answered, Abandoned,
  Agents_Staffed, Avg_Handle_Time_Sec, Service_Level, Abandon_Rate.
- The project dataset is synthetic. Do not use employer-confidential data in a portfolio.
- Percentage normalization supports Service_Level / Abandon_Rate stored as either 0.95 or 95.
- The staffing table created in Section 7 is an illustrative what-if scenario, NOT actual
  historical schedule data. It uses Agents_Staffed as a baseline proxy and adds two hypothetical
  agents on weekdays during the 10:00, 10:30, and 11:00, 11:30 intervals.

Run the full script in one session. Review the data-quality results before relying on analysis.
*/
SET NOCOUNT ON;
GO

/* 1. Confirm the source table exists. */
IF OBJECT_ID(N'dbo.Call_Center_Performance_Project1', N'U') IS NOT NULL
    PRINT 'Source table found. Ready to continue.';
ELSE
    PRINT 'ERROR: Source table not found. Check the selected database.';
GO

/* 2. Dataset coverage and row count. */
SELECT
    COUNT_BIG(*) AS Row_Count,
    MIN(TRY_CONVERT(date, [Date])) AS First_Date,
    MAX(TRY_CONVERT(date, [Date])) AS Last_Date,
    COUNT(DISTINCT TRY_CONVERT(date, [Date])) AS Distinct_Dates
FROM dbo.Call_Center_Performance_Project1;
GO

/* 3A. Basic data-quality checks. */
SELECT
    SUM(CASE WHEN TRY_CONVERT(date, [Date]) IS NULL THEN 1 ELSE 0 END) AS Invalid_Dates,
    SUM(CASE WHEN [Interval] IS NULL THEN 1 ELSE 0 END) AS Null_Intervals,
    SUM(CASE WHEN TRY_CONVERT(float, Calls_Offered) IS NULL THEN 1 ELSE 0 END) AS Invalid_Calls_Offered,
    SUM(CASE WHEN TRY_CONVERT(float, Agents_Staffed) IS NULL THEN 1 ELSE 0 END) AS Invalid_Agents_Staffed,
    SUM(CASE WHEN TRY_CONVERT(float, Avg_Handle_Time_Sec) IS NULL THEN 1 ELSE 0 END) AS Invalid_Avg_Handle_Time_Sec,
    SUM(CASE WHEN TRY_CONVERT(float, Calls_Offered) < 0 THEN 1 ELSE 0 END) AS Negative_Calls_Offered,
    SUM(CASE WHEN TRY_CONVERT(float, Agents_Staffed) < 0 THEN 1 ELSE 0 END) AS Negative_Agents_Staffed
FROM dbo.Call_Center_Performance_Project1;

/* 3B. Duplicate date/interval keys should be reviewed before a JOIN. */
SELECT
    TRY_CONVERT(date, [Date]) AS Work_Date,
    [Interval],
    COUNT(*) AS Rows_For_Date_Interval
FROM dbo.Call_Center_Performance_Project1
GROUP BY TRY_CONVERT(date, [Date]), [Interval]
HAVING COUNT(*) > 1
ORDER BY Work_Date, [Interval];
GO

/* 4. Overall performance against the 95% target. */
WITH Normalized AS
(
    SELECT
        TRY_CONVERT(date, [Date]) AS Work_Date,
        [Interval],
        TRY_CONVERT(float, Calls_Offered) AS Calls_Offered,
        TRY_CONVERT(float, Calls_Answered) AS Calls_Answered,
        TRY_CONVERT(float, Abandoned) AS Abandoned,
        TRY_CONVERT(float, Agents_Staffed) AS Agents_Staffed,
        TRY_CONVERT(float, Avg_Handle_Time_Sec) AS Avg_Handle_Time_Sec_Seconds,
        CASE WHEN TRY_CONVERT(float, Service_Level) > 1
             THEN TRY_CONVERT(float, Service_Level) / 100.0
             ELSE TRY_CONVERT(float, Service_Level) END AS Service_Level_Rate,
        CASE WHEN TRY_CONVERT(float, Abandon_Rate) > 1
             THEN TRY_CONVERT(float, Abandon_Rate) / 100.0
             ELSE TRY_CONVERT(float, Abandon_Rate) END AS Abandon_Rate_Rate
    FROM dbo.Call_Center_Performance_Project1
)
SELECT
    COUNT(*) AS Interval_Count,
    SUM(CASE WHEN Service_Level_Rate >= 0.95 THEN 1 ELSE 0 END) AS Intervals_At_Or_Above_95,
    SUM(CASE WHEN Service_Level_Rate < 0.95 THEN 1 ELSE 0 END) AS Intervals_Below_95,
    CAST(100.0 * AVG(CASE WHEN Service_Level_Rate >= 0.95 THEN 1.0 ELSE 0.0 END) AS decimal(6,2))
        AS Percent_Intervals_At_Or_Above_95,
    CAST(AVG(Service_Level_Rate) * 100.0 AS decimal(6,2)) AS Average_Interval_Service_Level_Pct,
    CAST(AVG(Abandon_Rate_Rate) * 100.0 AS decimal(6,2)) AS Average_Interval_Abandon_Rate_Pct,
    CAST(AVG(Avg_Handle_Time_Sec_Seconds) AS decimal(10,2)) AS Average_Avg_Handle_Time_Sec_Seconds
FROM Normalized;
GO

/* 5. Compare intervals below target with intervals meeting target. */
WITH Normalized AS
(
    SELECT
        CASE WHEN TRY_CONVERT(float, Service_Level) > 1
             THEN TRY_CONVERT(float, Service_Level) / 100.0
             ELSE TRY_CONVERT(float, Service_Level) END AS Service_Level_Rate,
        TRY_CONVERT(float, Calls_Offered) AS Calls_Offered,
        TRY_CONVERT(float, Agents_Staffed) AS Agents_Staffed,
        TRY_CONVERT(float, Avg_Handle_Time_Sec) AS Avg_Handle_Time_Sec_Seconds,
        CASE WHEN TRY_CONVERT(float, Abandon_Rate) > 1
             THEN TRY_CONVERT(float, Abandon_Rate) / 100.0
             ELSE TRY_CONVERT(float, Abandon_Rate) END AS Abandon_Rate_Rate
    FROM dbo.Call_Center_Performance_Project1
)
SELECT
    CASE WHEN Service_Level_Rate >= 0.95 THEN 'At or above 95%' ELSE 'Below 95%' END AS Service_Level_Group,
    COUNT(*) AS Interval_Count,
    CAST(AVG(Calls_Offered / NULLIF(Agents_Staffed, 0)) AS decimal(10,4)) AS Avg_Calls_Offered_Per_Staffed_Agent,
    CAST(AVG(Agents_Staffed) AS decimal(10,2)) AS Avg_Agents_Staffed,
    CAST(AVG(Avg_Handle_Time_Sec_Seconds) AS decimal(10,2)) AS Avg_Avg_Handle_Time_Sec_Seconds,
    CAST(AVG(Abandon_Rate_Rate) * 100.0 AS decimal(10,2)) AS Avg_Abandon_Rate_Pct
FROM Normalized
GROUP BY CASE WHEN Service_Level_Rate >= 0.95 THEN 'At or above 95%' ELSE 'Below 95%' END
ORDER BY Service_Level_Group;
GO

/* 6A. Rank recurring half-hour intervals by number of target misses. */
WITH Normalized AS
(
    SELECT
        [Interval],
        CASE WHEN TRY_CONVERT(float, Service_Level) > 1
             THEN TRY_CONVERT(float, Service_Level) / 100.0
             ELSE TRY_CONVERT(float, Service_Level) END AS Service_Level_Rate
    FROM dbo.Call_Center_Performance_Project1
)
SELECT
    [Interval],
    COUNT(*) AS Intervals_Observed,
    SUM(CASE WHEN Service_Level_Rate < 0.95 THEN 1 ELSE 0 END) AS Intervals_Below_95,
    CAST(100.0 * AVG(CASE WHEN Service_Level_Rate < 0.95 THEN 1.0 ELSE 0.0 END) AS decimal(6,2))
        AS Percent_Of_Observations_Below_95
FROM Normalized
GROUP BY [Interval]
ORDER BY Intervals_Below_95 DESC, [Interval];
GO

/* 6B. Weekday pattern. DATEFIRST 1 means Monday = 1 for this session. */
SET DATEFIRST 1;
WITH Normalized AS
(
    SELECT
        TRY_CONVERT(date, [Date]) AS Work_Date,
        CASE WHEN TRY_CONVERT(float, Service_Level) > 1
             THEN TRY_CONVERT(float, Service_Level) / 100.0
             ELSE TRY_CONVERT(float, Service_Level) END AS Service_Level_Rate
    FROM dbo.Call_Center_Performance_Project1
)
SELECT
    DATEPART(weekday, Work_Date) AS Weekday_Number_Monday_1,
    DATENAME(weekday, Work_Date) AS Weekday_Name,
    COUNT(*) AS Intervals_Observed,
    SUM(CASE WHEN Service_Level_Rate < 0.95 THEN 1 ELSE 0 END) AS Intervals_Below_95,
    CAST(100.0 * AVG(CASE WHEN Service_Level_Rate < 0.95 THEN 1.0 ELSE 0.0 END) AS decimal(6,2))
        AS Percent_Below_95
FROM Normalized
GROUP BY DATEPART(weekday, Work_Date), DATENAME(weekday, Work_Date)
ORDER BY Weekday_Number_Monday_1;
GO

/* 7. Build an illustrative staffing scenario table for JOIN practice.
   Baseline_Staffed_Proxy is copied from Agents_Staffed, not a verified scheduled count.
   Scenario_Additional_Agents adds two hypothetical agents on weekdays from 10:00 up to 12:00.
   This section drops/recreates only the project-owned scenario table.
*/
IF OBJECT_ID(N'dbo.Staffing_Schedule_Project1', N'U') IS NOT NULL
    DROP TABLE dbo.Staffing_Schedule_Project1;
GO
SET DATEFIRST 1;
WITH SourceIntervals AS
(
    SELECT
        TRY_CONVERT(date, [Date]) AS Work_Date,
        [Interval],
        TRY_CONVERT(int, Agents_Staffed) AS Baseline_Staffed_Proxy,
        DATEPART(weekday, TRY_CONVERT(date, [Date])) AS Weekday_Number,
        TRY_CONVERT(time(0), [Interval]) AS Interval_Start
    FROM dbo.Call_Center_Performance_Project1
)
SELECT
    Work_Date,
    [Interval],
    Baseline_Staffed_Proxy,
    CASE
        WHEN Weekday_Number BETWEEN 1 AND 5
         AND Interval_Start >= CAST('10:00' AS time(0))
         AND Interval_Start <  CAST('12:00' AS time(0))
        THEN 2 ELSE 0
    END AS Scenario_Additional_Agents
INTO dbo.Staffing_Schedule_Project1
FROM SourceIntervals;
GO

/* 8. JOIN the performance records to the scenario table on date + interval. */
WITH Performance AS
(
    SELECT
        TRY_CONVERT(date, p.[Date]) AS Work_Date,
        p.[Interval],
        TRY_CONVERT(float, p.Calls_Offered) AS Calls_Offered,
        TRY_CONVERT(float, p.Agents_Staffed) AS Actual_Agents_Staffed,
        TRY_CONVERT(float, p.Avg_Handle_Time_Sec) AS Avg_Handle_Time_Sec_Seconds,
        CASE WHEN TRY_CONVERT(float, p.Service_Level) > 1
             THEN TRY_CONVERT(float, p.Service_Level) / 100.0
             ELSE TRY_CONVERT(float, p.Service_Level) END AS Service_Level_Rate
    FROM dbo.Call_Center_Performance_Project1 AS p
)
SELECT
    p.Work_Date,
    p.[Interval],
    p.Calls_Offered,
    p.Actual_Agents_Staffed,
    s.Baseline_Staffed_Proxy,
    s.Scenario_Additional_Agents,
    s.Baseline_Staffed_Proxy + s.Scenario_Additional_Agents AS Scenario_Staffing_Level,
    CAST(p.Calls_Offered / NULLIF(p.Actual_Agents_Staffed, 0) AS decimal(10,3)) AS Calls_Per_Actual_Staffed_Agent,
    CAST(p.Calls_Offered / NULLIF(s.Baseline_Staffed_Proxy + s.Scenario_Additional_Agents, 0) AS decimal(10,3))
        AS Calls_Per_Scenario_Staffed_Agent,
    CAST(p.Service_Level_Rate * 100.0 AS decimal(6,2)) AS Observed_Service_Level_Pct,
    CASE WHEN p.Service_Level_Rate < 0.95 THEN 1 ELSE 0 END AS Below_95_Flag
FROM Performance AS p
INNER JOIN dbo.Staffing_Schedule_Project1 AS s
    ON p.Work_Date = s.Work_Date
   AND p.[Interval] = s.[Interval]
ORDER BY p.Work_Date, p.[Interval];
GO

/* 9. Summarize the hypothetical workload-per-agent change among below-target intervals.
   This does NOT estimate a causal service-level improvement from extra staff.
*/
WITH Performance AS
(
    SELECT
        TRY_CONVERT(date, p.[Date]) AS Work_Date,
        p.[Interval],
        TRY_CONVERT(float, p.Calls_Offered) AS Calls_Offered,
        TRY_CONVERT(float, p.Agents_Staffed) AS Actual_Agents_Staffed,
        CASE WHEN TRY_CONVERT(float, p.Service_Level) > 1
             THEN TRY_CONVERT(float, p.Service_Level) / 100.0
             ELSE TRY_CONVERT(float, p.Service_Level) END AS Service_Level_Rate
    FROM dbo.Call_Center_Performance_Project1 AS p
)
SELECT
    COUNT(*) AS Below_Target_Intervals,
    CAST(AVG(Calls_Offered / NULLIF(p.Actual_Agents_Staffed, 0)) AS decimal(10,3))
        AS Avg_Calls_Per_Actual_Staffed_Agent,
    CAST(AVG(p.Calls_Offered / NULLIF(s.Baseline_Staffed_Proxy + s.Scenario_Additional_Agents, 0)) AS decimal(10,3))
        AS Avg_Calls_Per_Scenario_Staffed_Agent
FROM Performance AS p
INNER JOIN dbo.Staffing_Schedule_Project1 AS s
    ON p.Work_Date = s.Work_Date
   AND p.[Interval] = s.[Interval]
WHERE p.Service_Level_Rate < 0.95;
GO

/* Interpretation checklist:
   - Treat these as descriptive associations, not proof of causation.
   - Investigate recurring high-risk periods alongside forecast accuracy, staffing availability,
     non-production time, call mix, and Avg_Handle_Time_Sec.
   - Replace the illustrative scenario with a separately validated synthetic schedule table if
     you want to analyze planned versus actual staffing.
*/
