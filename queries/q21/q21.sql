set QUERY_NUM=q21;
set resultTableName=${hiveconf:QUERY_NUM}result;
set resultFile=${env:BIG_BENCH_HDFS_ABSOLUTE_QUERY_RESULT_DIR}/${hiveconf:resultTableName};

-- TODO Empty result - needs more testing


--CREATE RESULT TABLE. Store query result externaly in output_dir/qXXresult/
DROP TABLE IF EXISTS ${hiveconf:resultTableName};
CREATE TABLE ${hiveconf:resultTableName}
ROW FORMAT
DELIMITED FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE
LOCATION '${hiveconf:resultFile}' 
AS
-- Beginn: the real query part
SELECT * 
  FROM (SELECT i.i_item_id AS item_id, i.i_item_desc AS item_desc, 
               s.s_store_id AS store_id, s.s_store_name AS store_name, 
               SUM(ss.ss_quantity) AS store_sales_quantity, 
               SUM(sr.sr_return_quantity) AS store_returns_quantity, 
               SUM(ws.ws_quantity) AS web_sales_quantity
          FROM store_sales ss
          JOIN item i ON i.i_item_sk = ss.ss_item_sk
          JOIN store s ON s.s_store_sk = ss.ss_store_sk
          JOIN date_dim d1 ON d1.d_date_sk = ss.ss_sold_date_sk  
           AND d1.d_moy = 4 AND d1.d_year = 1998
          JOIN store_returns sr ON ss.ss_customer_sk = sr.sr_customer_sk 
           AND ss.ss_item_sk = sr.sr_item_sk
          JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk 
           AND d2.d_moy > 4-1 AND d2.d_moy < 4+3+1 AND d2.d_year = 1998
          JOIN web_sales ws ON sr.sr_item_sk = ws.ws_item_sk
          JOIN date_dim d3 ON ws.ws_sold_date_sk = d3.d_date_sk 
           AND d3.d_year in (1998 ,1998+1 ,1998+2)
         GROUP BY i.i_item_id, i.i_item_desc, s.s_store_id, s.s_store_name) select_temp
 ORDER BY item_id, item_desc, store_id, store_name;