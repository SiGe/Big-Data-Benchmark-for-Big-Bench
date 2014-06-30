-- Global hive options (see: Big-Bench/setEnvVars)
--set hive.exec.parallel=${env:BIG_BENCH_hive_exec_parallel};
--set hive.exec.parallel.thread.number=${env:BIG_BENCH_hive_exec_parallel_thread_number};
--set hive.exec.compress.intermediate=${env:BIG_BENCH_hive_exec_compress_intermediate};
--set mapred.map.output.compression.codec=${env:BIG_BENCH_mapred_map_output_compression_codec};
--set hive.exec.compress.output=${env:BIG_BENCH_hive_exec_compress_output};
--set mapred.output.compression.codec=${env:BIG_BENCH_mapred_output_compression_codec};
--set hive.default.fileformat=${env:BIG_BENCH_hive_default_fileformat};
--set hive.optimize.mapjoin.mapreduce=${env:BIG_BENCH_hive_optimize_mapjoin_mapreduce};
--set hive.optimize.bucketmapjoin=${env:BIG_BENCH_hive_optimize_bucketmapjoin};
--set hive.optimize.bucketmapjoin.sortedmerge=${env:BIG_BENCH_hive_optimize_bucketmapjoin_sortedmerge};
--set hive.auto.convert.join=${env:BIG_BENCH_hive_auto_convert_join};
--set hive.auto.convert.sortmerge.join=${env:BIG_BENCH_hive_auto_convert_sortmerge_join};
--set hive.auto.convert.sortmerge.join.noconditionaltask=${env:BIG_BENCH_hive_auto_convert_sortmerge_join_noconditionaltask};
--set hive.optimize.ppd=${env:BIG_BENCH_hive_optimize_ppd};
--set hive.optimize.index.filter=${env:BIG_BENCH_hive_optimize_index_filter};

--display settings
set hive.exec.parallel;
set hive.exec.parallel.thread.number;
set hive.exec.compress.intermediate;
set mapred.map.output.compression.codec;
set hive.exec.compress.output;
set mapred.output.compression.codec;
set hive.default.fileformat;
set hive.optimize.mapjoin.mapreduce;
set hive.mapjoin.smalltable.filesize;
set hive.optimize.bucketmapjoin;
set hive.optimize.bucketmapjoin.sortedmerge;
set hive.auto.convert.join;
set hive.auto.convert.sortmerge.join;
set hive.auto.convert.sortmerge.join.noconditionaltask;
set hive.optimize.ppd;
set hive.optimize.index.filter;

-- Database
use ${env:BIG_BENCH_HIVE_DATABASE};

-- Resources
ADD FILE ${hiveconf:QUERY_DIR}/q4_mapper1.py;
ADD FILE ${hiveconf:QUERY_DIR}/q4_mapper2.py;
ADD FILE ${hiveconf:QUERY_DIR}/q4_reducer1.py;
ADD FILE ${hiveconf:QUERY_DIR}/q4_reducer2.py;

-- Result file configuration

-- Part 1: join webclickstreams with user, webpage and date -----------			  
DROP VIEW IF EXISTS ${hiveconf:TEMP_TABLE1};
CREATE VIEW ${hiveconf:TEMP_TABLE1} AS 
SELECT * 
FROM (
	FROM (
		--FROM (
		SELECT 	c.wcs_user_sk AS uid , 
			c.wcs_item_sk AS item , 
			w.wp_type AS wptype , 
			t.t_time+unix_timestamp(d.d_date,'yyyy-MM-dd') AS tstamp
                FROM web_clickstreams c 
                JOIN web_page w ON c.wcs_web_page_sk = w.wp_web_page_sk 
                		AND c.wcs_user_sk IS NOT NULL
                JOIN date_dim d ON c.wcs_click_date_sk = d.d_date_sk
                JOIN time_dim t ON c.wcs_click_time_sk = t.t_time_sk
		--) select_temp
		--MAP select_temp.uid, select_temp.item, select_temp.wptype, select_temp.tstamp
		-- USING 'python q4_mapper1.py' AS uid, item, wptype, tstamp  ||| use cat instead beacause this is a no-op mapper
		--USING 'cat' AS uid, item, wptype, tstamp
		CLUSTER BY uid
	) q04_tmp_map_output 
        REDUCE 	  q04_tmp_map_output.uid
		, q04_tmp_map_output.item
		, q04_tmp_map_output.wptype
		, q04_tmp_map_output.tstamp
        USING 'python q4_reducer1.py' AS (uid 	BIGINT
					, item 	BIGINT
					, wptype STRING
					, tstamp BIGINT
					, sessionid STRING)
) q04_tmp_sessionize
ORDER BY uid, tstamp
CLUSTER BY sessionid
;
--LIMIT 2500;

-- Part 2: Abandoned shopping carts ----------------------------------
DROP VIEW IF EXISTS ${hiveconf:TEMP_TABLE2};
CREATE VIEW ${hiveconf:TEMP_TABLE2} AS 
SELECT * 
FROM (
	--FROM (
	--	FROM ${hiveconf:TEMP_TABLE1}
        -- 	MAP 	${hiveconf:TEMP_TABLE1}.uid, 
	--		${hiveconf:TEMP_TABLE1}.item, 
	--		${hiveconf:TEMP_TABLE1}.wptype, 
	--		${hiveconf:TEMP_TABLE1}.tstamp, 
	--		${hiveconf:TEMP_TABLE1}.sessionid
	--	-- USING 'python q4_mapper2.py'   AS uid, item, wptype, tstamp, sessionid  ||| use cat instead beacause this is a no-op mapper
       	--	USING 'cat'   AS uid, item, wptype, tstamp, sessionid
     	--	CLUSTER BY sessionid
	--) q04_tmp_map_output
	FROM ${hiveconf:TEMP_TABLE1} q04_tmp_map_output
	REDUCE 	q04_tmp_map_output.uid, 
		q04_tmp_map_output.item, 
		q04_tmp_map_output.wptype, 
		q04_tmp_map_output.tstamp, 
		q04_tmp_map_output.sessionid
 	USING 'python q4_reducer2.py' AS (sid STRING, start_s BIGINT, end_s BIGINT)
) q04_tmp_npath
CLUSTER BY sid
;

--Result  --------------------------------------------------------------------		
--keep result human readable
set hive.exec.compress.output=false;
set hive.exec.compress.output;	
--CREATE RESULT TABLE. Store query result externally in output_dir/qXXresult/
DROP TABLE IF EXISTS ${hiveconf:RESULT_TABLE};
CREATE TABLE ${hiveconf:RESULT_TABLE}
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'
STORED AS ${env:BIG_BENCH_hive_default_fileformat_result_table} LOCATION '${hiveconf:RESULT_DIR}' 
AS
-- the real query part
SELECT c.sid, COUNT (*) AS s_pages
FROM ${hiveconf:TEMP_TABLE2} c JOIN ${hiveconf:TEMP_TABLE1} s ON s.sessionid = c.sid
GROUP BY c.sid
;


--cleanup --------------------------------------------
DROP VIEW IF EXISTS ${hiveconf:TEMP_TABLE1};
DROP VIEW IF EXISTS ${hiveconf:TEMP_TABLE2};
