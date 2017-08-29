SELECT * FROM profilescops;
SELECT * FROM regions;


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


/* sum up invalid reasons */
SELECT invalid_reason, sum(count) AS count
FROM profilescops
GROUP BY invalid_reason
ORDER BY count DESC;


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
