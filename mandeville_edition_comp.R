library(tidyverse)
library(IRanges)


get_ranges = function(ecco_id, id, reuse_df){
  tryCatch({
    ra = reuse_df %>% 
      filter(ecco_id.x == id & ecco_id.y == ecco_id) %>% 
      arrange(t2_start, t2_end) %>% 
      select(start = t2_start, end = t2_end)
    
    index = reuse_df %>% select(t2_ind = t2_start, min_t1 = t1_start)
    
    ir1 = IRanges(start = ra$start, end = ra$end)
    
    islands = ir1 %>% 
      IRanges::reduce() %>% 
      as.data.frame() %>% 
      as_tibble() %>% 
      left_join(index, by = c('start' = 't2_ind')) %>% 
      mutate(max_t1 = min_t1 + width) %>% 
      mutate(type = 'island')%>% select(start, end, width, type, min_t1, max_t1)
    
    
    
    #left_join(r1, join_by(end >= t2_end,start <= t2_start))
    gaps = gaps(ir1) %>% 
      as.data.frame() %>% 
      as_tibble() %>% 
      mutate(type = 'gap') %>% 
      mutate(min_t1 = NA, max_t1= NA)
    
    rbind(islands, gaps) %>%
      mutate(doc_id = ecco_id)
    
    
    
    
  }, error = function(e) {
    
  })
  
}

idmap <- tbl(con,dbplyr::in_schema("hpc-hd","idmap_a"))
full_reuses <- tbl(con,dbplyr::in_schema("hpc-hd","textreuses_2d_a"))
estc_core = tbl(con,dbplyr::in_schema("hpc-hd","estc_core_a"))



all_ids = estc_core %>% 
  filter(work_id == '8879-treatise of hypochondriack and hysterick passions') %>% 
  left_join(idmap, by = 'estc_id') %>% 
  arrange(publication_year) %>% filter(!is.na(ecco_id)) %>%  
  pull(ecco_id)



ids = idmap %>% filter(ecco_id %in% all_ids)

x = '0202401500'

first_id = idmap %>% filter(ecco_id == x)

r1 = full_reuses %>% 
  inner_join(first_id, by = c('t1_id' = 't_id'))%>% 
  inner_join(ids, by = c('t2_id' = 't_id')) %>% 
  left_join(estc_core %>% select(estc_id, publication_year, short_title), by= c('estc_id.y' = 'estc_id')) %>% 
  collect()


r1 = full_reuses %>% 
  inner_join(first_id, by = c('t1_id' = 't_id'))%>% 
  inner_join(ids, by = c('t2_id' = 't_id')) %>% 
  left_join(estc_core %>% select(estc_id, publication_year, short_title), by= c('estc_id.y' = 'estc_id')) %>% 
  collect()

r2 = r1 %>% select( -publication_year, -short_title)


y = all_ids[! all_ids == x]


t = lapply(y, get_ranges, id = x, reuse_df = r2) %>% 
  data.table::rbindlist() %>% 
  mutate(gap_link_text = paste0("<a href='https://a3s.fi/octavo-reader/index.html#?doc=",doc_id,"&startOffset=",start,"&endOffset=", end, "'>", doc_id, "</a><br>"))%>% 
  mutate(gap_link = paste0("https://a3s.fi/octavo-reader/index.html#?doc=",doc_id,"&startOffset=",start,"&endOffset=", end)) %>% 
  mutate(gap_link = paste0(gap_link, "&doc=", x, "&startOffset=",start,"&endOffset=", end)) %>%
  left_join(r1 %>% 
              distinct(ecco_id.y, short_title, publication_year, work_id.y), by = c('doc_id' = 'ecco_id.y'))


p6 = t  %>% filter(type == 'gap')  %>% 
  mutate(doc_id = paste0(doc_id, " (", publication_year, ")"))%>% 
  arrange(desc(publication_year)) %>% 
  mutate(doc_id = factor(doc_id, levels = unique(doc_id))) %>% 
  arrange(work_id.y, publication_year) %>% ungroup() %>% 
  mutate(doc_id  = factor(doc_id, levels = c( "1399900400 (1711)",
                                              "1308300100 (1715)",
                                              "0538300200 (1730)",
                                              "0682400700 (1730)" )))%>% 
  #mutate(sort_level = 1:nrow(.)) %>% 
  ggplot(aes(text = paste0(short_title, " (", publication_year, ")"))) + 
  geom_segment(aes(x = start, xend = end, y = doc_id, yend = doc_id), size = 20)  + 
  theme_bw() + theme(axis.title = element_blank(), axis.text = element_blank()) +  
  theme(legend.position = 'none') +
  scale_color_viridis_d(direction = -1) + expand_limits(x = 0) + facet_wrap(~doc_id, scales = 'free_y', ncol = 1)

ggsave('output/figures/final/figure_4_mandeville.pdf', p6, width = 8, height = 5)

