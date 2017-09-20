/* Sum up invalid reasons */
CREATE VIEW invalidReasons AS (
	SELECT invalid_reason, sum(count) AS occurrence
	FROM profilescops
	GROUP BY invalid_reason
	ORDER BY occurrence DESC
);

/* Durations per run */
CREATE VIEW durationsPerRun AS (
	SELECT run.id, run.command, run.project_name, run.run_group, EXTRACT(MICROSECONDS FROM run."end" - run."begin") AS duration
	FROM run INNER JOIN rungroup ON run.run_group = rungroup.id
);

/* Durations per project */
CREATE VIEW durationsPerProject AS (
	SELECT project_name, sum(duration) AS duration
	FROM durationsperrun
	GROUP BY project_name
);

/* Sum of durations of SCoPs */
CREATE VIEW durationsScopsPerProject AS (
	SELECT project_name, sum(regions.duration) AS duration
	FROM regions LEFT OUTER JOIN run ON run.id = regions.run_id
	INNER JOIN rungroup ON run.run_group = rungroup.id
	GROUP BY run.project_name
);

/* Ratio of SCoPs per project */
CREATE VIEW ratios AS (
	SELECT dp.project_name, ds.duration / dp.duration AS ratio
	FROM durationsperproject AS dp FULL OUTER JOIN durationsscopsperproject AS ds ON dp.project_name = ds.project_name
);