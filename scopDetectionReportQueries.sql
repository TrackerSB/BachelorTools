SELECT * FROM profilescops;
SELECT * FROM regions;
SELECT * FROM run;

DELETE FROM profilescops;
DELETE FROM regions;
DELETE FROM run;


/* Projects executed of group */
SELECT group_name, count(group_name)
FROM project
GROUP BY group_name
ORDER BY count DESC;


/* Number of projects where at least one regions was measured */
SELECT group_name, count(group_name)
FROM project INNER JOIN (
	SELECT project_name
	FROM run INNER JOIN regions ON run.id = regions.run_id
	GROUP BY project_name
) AS measured ON project."name" = measured.project_name
GROUP BY group_name;


/* Entries per project */
SELECT group_name, "name", count(*)
FROM project FULL OUTER JOIN run ON project."name" = run.project_name
GROUP BY group_name, "name"
ORDER BY count DESC;


/* Runs per project */
SELECT group_name, "name", count(*)
FROM project FULL OUTER JOIN (
	SELECT * FROM rungroup INNER JOIN run ON run.run_group = rungroup.id
) AS r ON project."name" = r.project_name
GROUP BY group_name, "name"
ORDER BY count DESC;


/* Are commands executed more than once? */
SELECT command, count(command) AS calls
FROM run
GROUP BY command
HAVING count(command) > 1
ORDER BY calls DESC, command ASC;


/* average over execution times of specific SCoPs */
SELECT "name", avg(duration)
FROM regions
GROUP BY "name"
ORDER BY "name";


/* sum of average execution times of all SCoPs */
SELECT "name", sum(avg) AS scopDuration
FROM (
	SELECT "name", avg(duration)
	FROM regions
	WHERE "name" LIKE '%::SCoP _'
	GROUP BY "name"
) AS averages
GROUP BY "name";


/* show SCoPs whose parents have no entry in regions
 * (If there's no bug these are the SCoPs which already have maximum size due
 * their parents are toplevel regions and cannot be instrumented)
 */
SELECT scopName AS toplevelregions
FROM (
	SELECT scopName, EXISTS(SELECT 1 FROM regions WHERE "name" LIKE parentName) AS hasParent
	FROM (
		SELECT (splitarray[1] || '::Parent ' || CAST(splitarray[2] AS INT) + 1) AS parentName, "name" AS scopName 
		FROM (
			SELECT string_to_array("name", '::SCoP') AS splitarray, "name"
			FROM regions
			WHERE "name" LIKE '%::SCoP _'
			GROUP BY "name"
		) AS splits
	) AS names INNER JOIN regions ON names.scopName = regions."name"
) AS maxScops
WHERE NOT hasParent;


/* sum of execution times of all parents (Untested) */
SELECT sum(scopDurations) AS parentDuration
FROM (
	SELECT "name", avg(duration) AS scopDurations /* avg of parents */
	FROM regions
	WHERE "name" LIKE '%::Parent _'
	GROUP BY "name"
	UNION ALL
	SELECT "name", avg(duration) /* avg of maximum scops */
	FROM regions
	WHERE "name" IN (
		SELECT scopName
		FROM (
			SELECT scopName, EXISTS(SELECT 1 FROM regions WHERE "name" LIKE parentName)
			FROM (
				SELECT (splitarray[1] || '::Parent' || splitarray[2]) AS parentName, "name" AS scopName 
				FROM (
					SELECT string_to_array("name", '::SCoP') AS splitarray, "name"
					FROM regions
					WHERE "name" LIKE '%::SCoP _'
					GROUP BY "name"
				) AS splits
			) AS names INNER JOIN regions ON names.scopName = regions."name"
		) AS maxScops
	)
	GROUP BY "name"
) AS averages;


/* sum up invalid reasons */
SELECT invalid_reason, sum(count) AS count
FROM profilescops
GROUP BY invalid_reason
ORDER BY count DESC, invalid_reason ASC;


/* show execution times of completed projects */
SELECT run.project_name, EXTRACT(EPOCH FROM "end"-"begin") * 1000 AS "duration [ms]"
FROM run
WHERE run.status = 'completed'
ORDER BY run.project_name, "duration [ms]";


/* show runs which are in any rungroup => so clang calls are not showing up*/
SELECT * FROM rungroup INNER JOIN run ON run.run_group = rungroup.id;


/* show execution times of completed projects which are in any rungroup */
SELECT run.project_name, run.command, EXTRACT(EPOCH FROM run."end"-run."begin") * 1000 AS "duration [ms]"
FROM rungroup INNER JOIN run ON run.run_group = rungroup.id
WHERE run.status = 'completed'
ORDER BY run.project_name, "duration [ms]";


/* ratio of SCoP according to hole execution time (Untested) */
SELECT project_name, scopDuration/"duration [ms]" AS ratio
FROM (
	SELECT run_id, sum(avg) AS scopDuration
	FROM (
		SELECT run_id, avg(duration)
		FROM regions INNER JOIN run ON regions.run_id = run.id
		WHERE "name" LIKE '%::SCoP _'
		GROUP BY run_id
	) AS averages
	GROUP BY run_id
) AS scopDurations INNER JOIN (
	SELECT run.id, project_name, EXTRACT(EPOCH FROM run."end"-run."begin") * 1000 AS "duration [ms]"
	FROM rungroup INNER JOIN run ON run.run_group = rungroup.id
	WHERE run.status = 'completed'
) AS holeDurations ON scopDurations.run_id = holeDurations.id;


/* show the smallest execution time of any completed project which is in a rungroup => Table showing whether the executed binary is faster with or without opts */
SELECT run.project_name, smallest."duration [ms]", run.command
FROM (
	SELECT run.project_name, min(EXTRACT(EPOCH FROM run."end"-run."begin") * 1000) AS "duration [ms]"
	FROM rungroup INNER JOIN run ON run.run_group = rungroup.id
	WHERE run.status = 'completed'
	GROUP BY run.project_name
) AS smallest INNER JOIN run ON smallest."duration [ms]" = EXTRACT(EPOCH FROM run."end"-run."begin") * 1000;


/* shows whether the executed binary is faster with or without opts */
SELECT run.project_name,
	CASE WHEN run.command LIKE '%no-opts.bin%' THEN 'without opts'
		ELSE 'with opts'
	END
FROM (
	SELECT run.project_name, min(EXTRACT(EPOCH FROM run."end"-run."begin") * 1000) AS "duration [ms]"
	FROM rungroup INNER JOIN run ON run.run_group = rungroup.id
	WHERE run.status = 'completed'
	GROUP BY run.project_name
) AS smallest INNER JOIN run ON smallest."duration [ms]" = EXTRACT(EPOCH FROM run."end"-run."begin") * 1000;


/* ffmpeg investigations */
SELECT count(*) FROM run WHERE project_name = 'ffmpeg';

SELECT command, count(command) AS count
FROM run
WHERE project_name = 'ffmpeg'
GROUP BY command
ORDER BY count DESC;

SELECT command, count(command) AS count
FROM rungroup INNER JOIN run ON run.run_group = rungroup.id
WHERE project_name = 'ffmpeg'
GROUP BY command
ORDER BY count DESC;

SELECT count(*) AS countRuns
FROM rungroup INNER JOIN run ON run.run_group = rungroup.id
WHERE project_name = 'ffmpeg';

SELECT count(*) AS countAll
FROM run
WHERE project_name = 'ffmpeg';


/* Tests */
SELECT *
FROM profilescops INNER JOIN run ON run.id = profilescops.run_id
WHERE run.project_name = '7z';