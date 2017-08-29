SELECT * FROM profilescops;
SELECT * FROM regions;


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


/* Tests */
SELECT *
FROM project FULL OUTER JOIN run ON project."name" = run.project_name
WHERE group_name = 'benchbuild';

SELECT count(*) FROM run WHERE project_name = 'ffmpeg';