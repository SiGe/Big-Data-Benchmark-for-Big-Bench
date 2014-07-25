--Find the categories with flat or declining sales for in store purchases
--during a given year for a given store.

-- Resources

DROP TABLE IF EXISTS ${hiveconf:MATRIX_BASENAME}1;
DROP TABLE IF EXISTS ${hiveconf:MATRIX_BASENAME}2;
DROP TABLE IF EXISTS ${hiveconf:MATRIX_BASENAME}3;
DROP TABLE IF EXISTS ${hiveconf:MATRIX_BASENAME}4;
DROP TABLE IF EXISTS ${hiveconf:MATRIX_BASENAME}5;
DROP TABLE IF EXISTS ${hiveconf:MATRIX_BASENAME}6;
DROP TABLE IF EXISTS ${hiveconf:MATRIX_BASENAME}7;
DROP TABLE IF EXISTS ${hiveconf:MATRIX_BASENAME}8;
DROP TABLE IF EXISTS ${hiveconf:MATRIX_BASENAME}9;
DROP TABLE IF EXISTS ${hiveconf:MATRIX_BASENAME}10;

----store time series------------------------------------------------------------------

CREATE TABLE ${hiveconf:MATRIX_BASENAME}1 (d BIGINT,sales DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' 
STORED AS TEXTFILE LOCATION '${hiveconf:MATRIX_BASEDIR}1'
;


CREATE TABLE ${hiveconf:MATRIX_BASENAME}2 (d BIGINT,sales DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' 
STORED AS TEXTFILE LOCATION '${hiveconf:MATRIX_BASEDIR}2'
;


CREATE TABLE ${hiveconf:MATRIX_BASENAME}3 (d BIGINT,sales DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' 
STORED AS TEXTFILE LOCATION '${hiveconf:MATRIX_BASEDIR}3'
;


CREATE TABLE ${hiveconf:MATRIX_BASENAME}4 (d BIGINT,sales DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' 
STORED AS TEXTFILE LOCATION '${hiveconf:MATRIX_BASEDIR}4'
;


CREATE TABLE ${hiveconf:MATRIX_BASENAME}5 (d BIGINT,sales DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' 
STORED AS TEXTFILE LOCATION '${hiveconf:MATRIX_BASEDIR}5'
;


CREATE TABLE ${hiveconf:MATRIX_BASENAME}6 (d BIGINT,sales DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' 
STORED AS TEXTFILE LOCATION '${hiveconf:MATRIX_BASEDIR}6'
;


CREATE TABLE ${hiveconf:MATRIX_BASENAME}7 (d BIGINT,sales DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' 
STORED AS TEXTFILE LOCATION '${hiveconf:MATRIX_BASEDIR}7'
;

CREATE TABLE ${hiveconf:MATRIX_BASENAME}8 (d BIGINT,sales DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' 
STORED AS TEXTFILE LOCATION '${hiveconf:MATRIX_BASEDIR}8'
;


CREATE TABLE ${hiveconf:MATRIX_BASENAME}9 (d BIGINT,sales DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' 
STORED AS TEXTFILE LOCATION '${hiveconf:MATRIX_BASEDIR}9'
;


CREATE TABLE ${hiveconf:MATRIX_BASENAME}10 (d BIGINT,sales DOUBLE)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' 
STORED AS TEXTFILE LOCATION '${hiveconf:MATRIX_BASEDIR}10'
;


FROM (
	SELECT  
		i.i_category_id 	AS cat, -- ranges from 1 to 10
		s.ss_sold_date_sk 	AS d,
		sum(s.ss_net_paid) 	AS sales
	FROM    store_sales s
	-- select date range 
	LEFT SEMI JOIN (	
			SELECT d_date_sk 
			FROM  date_dim d
			WHERE d.d_date >= '${hiveconf:q15_startDate}'
			AND   d.d_date <= '${hiveconf:q15_endDate}'
		) dd ON ( s.ss_sold_date_sk=dd.d_date_sk ) 
	INNER JOIN item i ON s.ss_item_sk = i.i_item_sk 
	WHERE i.i_category_id IS NOT NULL
	  AND s.ss_store_sk = ${hiveconf:q15_store_sk} -- for a given store ranges from 1 to 12
	GROUP BY i.i_category_id, s.ss_sold_date_sk
) tsc
INSERT OVERWRITE TABLE ${hiveconf:MATRIX_BASENAME}1  SELECT d, sales WHERE cat = 1
INSERT OVERWRITE TABLE ${hiveconf:MATRIX_BASENAME}2  SELECT d, sales WHERE cat = 2
INSERT OVERWRITE TABLE ${hiveconf:MATRIX_BASENAME}3  SELECT d, sales WHERE cat = 3
INSERT OVERWRITE TABLE ${hiveconf:MATRIX_BASENAME}4  SELECT d, sales WHERE cat = 4
INSERT OVERWRITE TABLE ${hiveconf:MATRIX_BASENAME}5  SELECT d, sales WHERE cat = 5
INSERT OVERWRITE TABLE ${hiveconf:MATRIX_BASENAME}6  SELECT d, sales WHERE cat = 6
INSERT OVERWRITE TABLE ${hiveconf:MATRIX_BASENAME}7  SELECT d, sales WHERE cat = 7
INSERT OVERWRITE TABLE ${hiveconf:MATRIX_BASENAME}8  SELECT d, sales WHERE cat = 8
INSERT OVERWRITE TABLE ${hiveconf:MATRIX_BASENAME}9  SELECT d, sales WHERE cat = 9
INSERT OVERWRITE TABLE ${hiveconf:MATRIX_BASENAME}10 SELECT d, sales WHERE cat = 10
;



--cleaning up -------------------------------------------------
