--Snowflake Data Sampling

USE DATABASE SNOWFLAKE_SAMPLE_DATA;

SELECT COUNT(*) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM; --6001215

SELECT COUNT(*) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.SUPPLIER; --10000

--ROW SMAPLLING

ALTER SESSION SET USE_CACHED_RESULT = FALSE;

SELECT S_NAME,S_PHONE,S_ACCTBAL
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.SUPPLIER SAMPLE(90); --9011 ROWS --9017 rows

SELECT S_NAME,S_PHONE,S_ACCTBAL
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.SUPPLIER SAMPLE(1); --95 ROWS

SELECT S_NAME,S_PHONE,S_ACCTBAL
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.SUPPLIER SAMPLE ROW(1); --100 ROW

SELECT S_NAME,S_PHONE,S_ACCTBAL
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.SUPPLIER TABLESAMPLE ROW(1); --92 ROW

SELECT S_NAME, S_PHONE, S_ACCTBAL
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.SUPPLIER SAMPLE BERNOULLI (1.01); --82 ROWS

SELECT S_NAME, S_PHONE, S_ACCTBAL
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.SUPPLIER SAMPLE BERNOULLI (1.01) REPEATABLE(321); --116 ROWS

SELECT S_NAME, S_PHONE, S_ACCTBAL
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.SUPPLIER SAMPLE BERNOULLI (500 ROWS);

--FOR LARGE VOLUME SAMPLING DATA BERNOULLI WILL TAKE MORE TIME THAN BLOCK PROCESS

SELECT L_QUANTITY,L_EXTENDEDPRICE,L_DISCOUNT
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM SAMPLE BLOCK(1); --59792 ROWS 452MS

SELECT L_QUANTITY,L_EXTENDEDPRICE,L_DISCOUNT
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM SAMPLE BERNOULLI(0.01); --619 ROWS 131MS

/*## Core Summary of Snowflake Data Sampling
Data sampling allows you to query a representative subset of rows from a large table rather than processing the entire dataset. This is highly useful for quick data exploration, testing queries, or training machine learning models while saving time and computing costs.
------------------------------
## 1. Sampling Methods: Row (Bernoulli) vs. Block
Snowflake provides two primary methods for sampling data. Choosing the right one depends on your table size and performance needs:

| Feature | Row Sampling (ROW / BERNOULLI) | Block Sampling (BLOCK / SYSTEM) |
|---|---|---|
| How it works | Evaluates each row individually based on a probability percentage. | Selects a percentage of entire micro-partitions (blocks) of data. |
| Row Count | Highly accurate percentage matching. | Rougher approximation of the target percentage. |
| Speed | Slower on massive tables because it looks at individual rows. | Significantly faster because it skips reading unselected data blocks entirely. |
| Randomness | Highly random and uniform distribution across the dataset. | Less random if the data is heavily clustered or sorted by specific keys. |

------------------------------
## 2. Key Syntax Variants & Behaviours
From your script, here are the critical rules and observations for using the SAMPLE clause:

* Percentage-Based Sampling: The default number passed to SAMPLE(x) represents a percentage (0 to 100), not a fixed row count. For example, SAMPLE(1) targets roughly 1% of the data (e.g., ~100 out of 10,000 rows).
* Fixed Row-Count Sampling: If you want an exact number of rows, you must explicitly pass the ROWS keyword (e.g., SAMPLE BERNOULLI (500 ROWS)). Note: Fixed row-count sampling only supports the BERNOULLI method.
* Interchangeable Keywords: SAMPLE and TABLESAMPLE act identically, as do ROW / BERNOULLI and BLOCK / SYSTEM.
* The REPEATABLE(seed) Clause: Sampling is naturally non-deterministic (results will fluctuate slightly between runs, as seen in your 9011 vs. 9017 rows). Adding REPEATABLE(321) fixes the random number generator seed, forcing Snowflake to return the exact same deterministic subset of rows every time the query is run (provided the underlying table data hasn't changed).

------------------------------
## 3. Overturning the Performance Myth on Small Datasets
In your LINEITEM benchmark, you observed:

* BLOCK(1) took 452ms for ~60,000 rows.
* BERNOULLI(0.01) took 131ms for ~600 rows.

Why did Bernoulli seem faster here?
At TPCH_SF1.LINEITEM (6 million rows), the dataset is still relatively small for Snowflake. The overhead of reading and extracting entire metadata micro-partitions for BLOCK sampling can sometimes make it look slower on smaller tables. However, when you scale up to terabyte or petabyte-scale tables (billions of rows), BERNOULLI forces a full table scan to inspect every row, whereas BLOCK skips millions of micro-partitions instantly, drastically reducing execution time.

*/