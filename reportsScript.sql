/* Show statistic over which reasons for a parent being invalid shows up how often */
CREATE OR REPLACE VIEW invalidReasons AS (
    SELECT profileScops.invalid_reason, sum(count) AS occurrence
    FROM profilescops, run
    WHERE run.id = profileScops.run_id AND run.experiment_group = 'e6d41837-3085-4ae1-8fa1-39a3ce3c3292'
    GROUP BY profileScops.invalid_reason
    ORDER BY occurrence DESC
);

SELECT * FROM invalidReasons;
SELECT count(*) FROM invalidReasons;



/* Group the reasons for parents not being a valid SCoP by type of rejection */
CREATE OR REPLACE VIEW invalidreasonsGrouped AS (
    SELECT invalid_reason, sum(occurrence) AS sum
    FROM (SELECT CASE
                WHEN invalid_reason LIKE 'Non affine loop bound ''***COULDNOTCOMPUTE***''%' THEN 'Non affine loop bound ''***COULDNOTCOMPUTE***'''
                WHEN invalid_reason LIKE 'Non affine loop bound%' THEN 'Non affine loop bound'
                WHEN invalid_reason LIKE 'Condition in BB%neither constant nor an icmp instruction' THEN 'Condition in BB neither constant nor an icmp instruction'
                WHEN invalid_reason LIKE 'Call instruction:%' THEN 'Call instruction'
                WHEN invalid_reason LIKE 'Non affine access function%' THEN 'Non affine access function'
                WHEN invalid_reason LIKE 'Non affine branch in BB%' THEN 'Non affine branch in BB'
                WHEN invalid_reason LIKE 'Possible aliasing%' THEN 'Possible aliasing'
                WHEN invalid_reason LIKE 'Base address not invariant in current region%' THEN 'Base address not invariant in current region'
                WHEN invalid_reason LIKE 'Alloca instruction%' THEN 'Alloca instruction'
                WHEN invalid_reason LIKE 'Non-simple memory access%' THEN 'Non-simple memory access'
                WHEN invalid_reason LIKE 'Find bad intToptr prt%' THEN 'Find bad intToPointer pointer'
                WHEN invalid_reason LIKE 'Condition based on ''undef'' value in BB%' THEN 'Condition based on undefined value in BB'
                WHEN invalid_reason LIKE 'Unreachable in exit block%' THEN 'Unreachable in exit block'
                ELSE invalid_reason
            END, occurrence
        FROM invalidReasons
    ) AS grouped
    GROUP BY invalid_reason
    ORDER BY sum DESC
);

SELECT * FROM invalidreasonsgrouped;

/* The execution times of hole runs */
CREATE OR REPLACE VIEW ExecTimes AS (
    SELECT run.id, run.project_name, 1000*metrics.value as execTime
    FROM metrics INNER JOIN run ON run.id = metrics.run_id
    WHERE metrics."name" LIKE 'time.real_s'
);
SELECT * FROM ExecTimes;
/*NOTES
 * 340 projects in run
 * 399 time.real_s entries in metrics
 * 281 projects
 * 399 entries
 */

/* Table of valid regions */
CREATE OR REPLACE VIEW ValidRegions AS (
    SELECT regions.run_id, regions.duration, regions.id, regions."name", regions.events
    FROM regions INNER JOIN ExecTimes ON regions.run_id = ExecTimes.id
    WHERE regions.duration <= ExecTimes.execTime
);
SELECT * FROM ValidRegions;
/*NOTES
 * 29625 entries
 * 17172 valid entries?!
 */

/* Ratio of valid regions */
SELECT (SELECT count(*)::double precision AS valid FROM ValidRegions) / (SELECT count(*) AS overall FROM regions) AS usefulRatio;

/* Ratio of ratios */
CREATE OR REPLACE VIEW RatiosOfRegions AS (
    SELECT ValidRegions.run_id, ValidRegions.id, ValidRegions.duration, ValidRegions."name", ValidRegions.events, ExecTimes.project_name, ExecTimes.execTime, ValidRegions.duration / ExecTimes.execTime AS ratio
    FROM ValidRegions INNER JOIN ExecTimes ON ValidRegions.run_id = ExecTimes.id
);
SELECT * FROM RatiosOfRegions;
/*NOTES
 * 17172 entries
 */

CREATE OR REPLACE VIEW RatiosOfScops AS (
    SELECT project_name, sum(ratio)
    FROM RatiosOfRegions
    WHERE "name" LIKE '%::SCoP'
    GROUP BY project_name
);
SELECT * FROM RatiosOfScops;
/*NOTES
 * 174 entries
 */
