/* Show statistic over which reasons for a parent being invalid shows up how often */
CREATE OR REPLACE VIEW invalidReasons AS (
    SELECT invalid_reason, sum(count) AS occurrence
    FROM profilescops
    GROUP BY invalid_reason
    ORDER BY occurrence DESC
);

/* Show the durations of every run to execute (hole execution time) */
CREATE OR REPLACE VIEW durationsPerRun AS (
    SELECT run.id, run.command, run.project_name, run.run_group, EXTRACT(MICROSECONDS FROM run."end" - run."begin") AS duration
    FROM run INNER JOIN rungroup ON run.run_group = rungroup.id
);

/* Show the hole execution time of every project */
CREATE OR REPLACE VIEW durationsPerProject AS (
    SELECT project_name, sum(duration) AS duration
    FROM durationsperrun
    GROUP BY project_name
);

/* Sum of durations of the SCoPs of any project */
CREATE OR REPLACE VIEW durationsScopsPerProject AS (
    SELECT project_name, sum(regions.duration) AS duration
    FROM regions LEFT OUTER JOIN run ON run.id = regions.run_id
    INNER JOIN rungroup ON run.run_group = rungroup.id
    GROUP BY run.project_name
);

/* Calculate the percentage of the SCoPs according to the hole execution time of a project */
CREATE OR REPLACE VIEW ratios AS (
    SELECT dp.project_name, ds.duration / dp.duration AS ratio
    FROM durationsperproject AS dp FULL OUTER JOIN durationsscopsperproject AS ds ON dp.project_name = ds.project_name
);

/* Caluculate the percentage of durations within the regions table being realistic */
SELECT g.good/o.overall AS usefulRatio
FROM (
    SELECT count(*)::double precision AS overall FROM regions
) AS o, (
    SELECT count(*) AS good FROM regions WHERE duration < 1000000000000
) AS g;

