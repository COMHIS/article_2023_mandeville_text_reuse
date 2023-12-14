# Description

Finished code used for article analysis and figures. 

Code is based on SQL queries of the COMHIS text reuse MariaDB database. 

get_connection.R connects to the MariaDB database (username and password required)

mandeville_non_mandeville.R (and .sql) calculates the coverage proportion (i.e. the total amount of overlap) of all Mandeville to non-Mandeville texts.

mandeville_to_mandeville calculates the coverage proportion of Mandeville texts to other Mandeville texts. 

The results of these are saved as intermediate .csv files, in Data -> Final. 

mandeville_plots.R uses the raw coverages information to generate figures for publication. 

## Computing Reuse and Coverage at Document Level

### Definitions

Given a pair of documents $D_1$ and  $D_2$, document level reuses is defined as 
$$
reuse(D_1,D_2) =  \#\text{ of characters in } D_1 \text{ reused in } D_2,
$$
and coverage is defined as
$$ 
coverage(D_1,D_2) = \frac{reuse(D_1,D_2)}{|D_1|},
$$
where $|D_1|$ is the total number of characters in the first document. Currently, it is gathered from the `ecco_core.ecco_nr_characters` attribute.

### Mandevill Non-Mandeville SQL query
The SQL query in [mandeville_non_mandeville.sql](mandeville_non_mandeville.sql) return the rows where `coverage_t1_t2>30%` for document pairs where `t1_id` is written by Mandeville and `t2_id` is not written by Mandeville. 

Due to correlated subqueries not being allowed with the `OR` clause in MariaDB, the `filtered` CTE uses the `textreuses2d` table. Therefore, this query takes around 2min to run.

### Column Descriptions

The details of the columns returned by the SQL queries are :
1. “t1_id”: The ID of the first document t1 from `textreuse` table
2. “t1_reuses”: The number of contiguous reuse regions in first document after merging overlapping offsets
3. “reuse_t1_t2”: The number of characters of t1 reused in t2
4. “t1_length”: The length of document t1 from the `ecco_core.ecco_nr_characters` field
5. “coverage_t1_t2”: The percentage of document t1 being reused by document t2
6. “t1_work_id”: Short work ID of document 1 from `idmap` table
7. “t1_estc_id”: Document t1 ESTC id from `ecco_core` table
8. “t2_id”: The ID of the second document t1 from `textreuse` table
9. “t2_reuses”: The number of contiguous reuse regions in second document after merging overlapping offsets
10. “reuse_t2_t1": The number of characters of t2 reused in t1
11. “t2_length”: The length of document t2 from the `ecco_core.ecco_nr_characters` field
12. “coverage_t2_t1":The percentage of document t2 being reused by document t1
13. “t2_work_id”: Short work ID of document 1 from `idmap` table
14. “t2_estc_id”: t2 ESTC id from `ecco_core` table
