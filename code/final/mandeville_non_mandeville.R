source('get_connection.R')

sql_query = "

WITH ids AS
(
    -- Filter text reuse ids based on author names
    SELECT DISTINCT t_id  
	FROM 
		idmap id 
		LEFT JOIN
			estc_actor_links eal
		ON 	
			id.estc_id  = eal.estc_id 
	WHERE eal.actor_name_primary LIKE 'Mandeville, Bernard%'
),
filtered AS 
(   
    -- semi-join query
    -- get all reuse pairs where both documents are from ids
	SELECT 
		* 
	FROM
		textreuses td
	WHERE
		t1_id IN (SELECT * from ids) AND 
		t2_id in (SELECT * from ids)
	
),
groups AS 
(   
    -- lag the end columns to find islands 
    -- also keep a row number
    -- both done over t1_id,t2_id
	SELECT 
		ROW_NUMBER() OVER(PARTITION BY t1_id,t2_id ORDER BY t1_start,t1_end) AS t1_RN,
		ROW_NUMBER() OVER(PARTITION BY t1_id,t2_id ORDER BY t2_start,t2_end) AS t2_RN,
		t1_id,
		t2_id,
		t1_start,
		t1_end,
		t2_start,
		t2_end,
		MAX(t1_end) -- largest end date given grouping 
			OVER 
			(
				PARTITION BY t1_id,t2_id -- group by t1 and t2
				ORDER BY t1_start,t1_end  -- order by times
				ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING -- FROM all rows before TILL 1 row before 
                -- the '1 PRECEDING' acts like a lag ensuring it only compares rows before current row
			) as t1_previous_end,
		MAX(t2_end) -- largest end date given grouping
			OVER 
			(
				PARTITION BY t1_id,t2_id -- group by t1 and t2
				ORDER BY t2_start,t2_end  -- order by times
				ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING -- FROM all rows before till 1 row before 
			) as t2_previous_end
	FROM 
		filtered
), 
islands AS
(   
    -- find island starting locations for both t1 and t2
    -- sum over island starting to get island numbers for t1 and t2
	SELECT 
		*,
        -- uncomment for debugging islands
		-- CASE WHEN t1_previous_end >= t1_start THEN 0 ELSE 1 END AS t1_island_start,
        -- CASE WHEN t2_previous_end >= t2_start THEN 0 ELSE 1 END AS t2_island_start,
        -- the `previous_end_+1 >= t1_start` is to catch offset ranges like
        --   (1,6) and (7,12) and merge them into (1,12) as a single offset
		SUM(CASE WHEN t1_previous_end+1 >= t1_start THEN 0 ELSE 1 END) OVER (PARTITION BY t1_id,t2_id ORDER BY t1_RN) as t1_island_id,
		-- t2 overalps 
		SUM(CASE WHEN t2_previous_end+1 >= t2_start THEN 0 ELSE 1 END) OVER (PARTITION BY t1_id,t2_id ORDER BY t2_RN) as t2_island_id
	FROM groups
), 
t1_merged_overlaps as 
(
    -- group the islands together for t1
	SELECT
		t1_id,
		t2_id,
		MIN(t1_start) as t1_start_pos,
		MAX(t1_end) as t1_end_pos,
		MAX(t1_end) - MIN(t1_start) as t1_overlap_length
	FROM islands
	GROUP BY 
		t1_id,
		t2_id,
		t1_island_id
),
t1_final as 
(
    -- find the total reuse length and number of merged ranges
    --   for t1
    SELECT 
        t1_id,
        t2_id,
        SUM(t1_overlap_length) as t1_correct_overlap,
        COUNT(*) as t1_num_merged_hits
    FROM t1_merged_overlaps
    GROUP BY 
        t1_id,
        t2_id
),
t2_merged_overlaps AS 
(
    -- group the islands together for t1
	SELECT
		t1_id,
		t2_id,
		MIN(t2_start) as t2_start_pos,
		MAX(t2_end) as t2_end_pos,
		MAX(t2_end) - MIN(t2_start) as t2_overlap_length
	FROM islands
	GROUP BY 
		t1_id,
		t2_id,
		t2_island_id
),
t2_final AS 
(
    -- find the total reuse length and number of merged ranges
    --   for t2
    SELECT 
        t1_id,
        t2_id,
        SUM(t2_overlap_length) as t2_correct_overlap,
        COUNT(*) as t2_num_merged_hits
    FROM t2_merged_overlaps
    GROUP BY 
        t1_id,
        t2_id
),
reuses AS
(   
    -- join the information for t1 and t2 together
	SELECT 
		t1.t1_id,
		t1.t1_num_merged_hits as t1_reuses,
		t1.t1_correct_overlap as reuse_t1_t2,
		t1.t2_id,
		t2.t2_num_merged_hits as t2_reuses,
		t2.t2_correct_overlap as reuse_t2_t1		
	FROM t1_final t1
	LEFT JOIN t2_final t2 
	ON 
		t1.t1_id = t2.t1_id AND
		t1.t2_id = t2.t2_id 
)
-- final query to join with metadata and compute coverage
SELECT 
	r.t1_id, r.t1_reuses, r.reuse_t1_t2, ec.ecco_nr_characters as t1_length, (r.reuse_t1_t2/ec.ecco_nr_characters)*100 as coverage_t1_t2,
	i.work_id_short as t1_work_id, i.estc_id as t1_estc_id,
	r.t2_id, r.t2_reuses, r.reuse_t2_t1, ec2.ecco_nr_characters as t2_length, (r.reuse_t2_t1/ec2.ecco_nr_characters)*100 as coverage_t2_t1,
	i2.work_id_short as t2_work_id,i2.estc_id as t2_estc_id
FROM 
	reuses r
	LEFT JOIN idmap i ON i.t_id = r.t1_id
	LEFT JOIN ecco_core ec ON i.ecco_id = ec.ecco_id
	LEFT JOIN idmap i2 ON i2.t_id = r.t2_id 
	LEFT JOIN ecco_core ec2 ON i2.ecco_id = ec2.ecco_id
ORDER BY 
	/*r.t1_id,
	r.t2_id,*/
	coverage_t1_t2 DESC
	
	"
    
mandeville_non_mandeville = dbGetQuery(con, sql_query)
    
mandeville_non_mandeville %>% write_csv('data/final/mandeville_non_mandeville.csv')
    


    