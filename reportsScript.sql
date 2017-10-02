/* Show statistic over which reasons for a parent being invalid shows up how often */
CREATE OR REPLACE VIEW invalidReasons AS (
    SELECT invalid_reason, sum(count) AS occurrence
    FROM profilescops
    GROUP BY invalid_reason
    ORDER BY occurrence DESC
);

SELECT * FROM invalidReasons;



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



/* Show the durations of every run to execute (hole execution time; RunWithTime) */
CREATE OR REPLACE VIEW durationsPerRun AS (
    SELECT run.id, run.command, run.project_name, run.run_group, metrics."name", 1000/*?*/ * metrics.value AS duration
    FROM run INNER JOIN metrics ON run.id = metrics.run_id
    WHERE metrics."name" LIKE 'time.real_s' /*TOOD Avoid where clause*/
);

SELECT * FROM durationsperrun;



/* Show the hole execution time of every project */
CREATE OR REPLACE VIEW durationsPerProject AS (
    SELECT id, sum(duration) AS duration
    FROM durationsperrun
    GROUP BY id
);

SELECT * FROM durationsperproject;



/* Show all entries of regions which have valid durations */
CREATE OR REPLACE VIEW validRegionEntries AS ( 
    SELECT regions.run_id, regions.duration, regions.id, regions."name", regions.events /* LEFT SEMI JOIN */
    FROM regions INNER JOIN metrics ON regions.run_id = metrics.run_id
    WHERE metrics.value >= regions.duration
);

SELECT * FROM validregionentries;



/* Sum of durations of all SCoPs per project */
CREATE OR REPLACE VIEW durationsScopsPerProject AS (
    SELECT run.id, sum(validregionentries.duration) AS duration
    FROM validregionentries LEFT OUTER JOIN run ON run.id = validregionentries.run_id
    INNER JOIN rungroup ON run.run_group = rungroup.id
    GROUP BY run.id
);

SELECT * FROM durationsscopsperproject;



/* Calculate the percentage of the SCoPs according to the hole execution time of a project */
CREATE OR REPLACE VIEW ratios AS (
    SELECT dp.id, ds.duration / dp.duration AS ratio
    FROM durationsperproject AS dp INNER JOIN durationsscopsperproject AS ds ON dp.id = ds.id
);

SELECT * FROM ratios;



/* Caluculate the percentage of durations within the regions table being realistic */
SELECT g.good/o.overall AS usefulRatio
FROM (
    SELECT count(*)::double precision AS overall FROM regions
) AS o, (
    SELECT count(*) AS good FROM validregionentries
) AS g;



/* Mean, standard deviation, variance (Evtl. median?)*/
SELECT project_name, avg(ratio)
FROM ratios
GROUP BY project_name;
