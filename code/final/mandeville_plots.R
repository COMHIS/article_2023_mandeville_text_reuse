library(tidyverse)
library(ggalluvial)

mandeville_non_mandeville = read_csv('data/final/mandeville_non_mandeville.csv')

estc_authors = estc_actor_links %>% 
  filter(actor_role_author == TRUE) %>% 
  select(estc_id, actor_id, actor_name_primary) %>% 
  collect()

estc_actors_c = estc_actors %>% select(actor_id, name_unified, year_birth, year_death) %>% collect()

estc_year = estc_core %>% select(estc_id, publication_year) 

estc_core_c = estc_core %>% select(estc_id, publication_year, short_title, work_id) %>% collect()


df = read_csv('/Users/yannryan/r_projects/mandeville/madeville_non_mandeville_full (1).csv')%>%
  left_join(estc_year, by = c('t1_estc_id' = 'estc_id'))%>%
  left_join(estc_year, by = c('t2_estc_id' = 'estc_id'))

gh1 <- estc_core_c %>% 
  left_join(estc_authors) %>% 
  left_join(estc_actors_c) %>% 
  select(estc_id,short_title,name_unified, actor_id,year_birth,year_death)


ce1 <- estc_core_c %>% 
  group_by(work_id) %>% 
  slice_min(publication_year, with_ties = TRUE)

p1 = df %>% 
  left_join(gh1, by = c('t1_estc_id' = 'estc_id'))%>% 
  left_join(gh1, by = c('t2_estc_id' = 'estc_id'))%>% 
  rename(bm_short = short_title.x, short = short_title.y) %>% 
  rename(other_author = name_unified.y) %>% 
  group_by(t1_work_id, t2_work_id) %>% 
  slice_max(t1_reuses, with_ties = FALSE) %>% 
  ungroup() %>% 
  left_join(ce1, by = c('t1_work_id' = 'work_id')) %>% 
  left_join(ce1, by = c('t2_work_id' = 'work_id')) %>% 
  rename(t1_year = publication_year.x.x, 
         t2_year = publication_year.y.y) %>% 
  filter(t2_year < t1_year) %>% 
  mutate(bm_title = str_trunc(short_title.x, 28))%>% 
  filter(t1_reuses > 0.1) %>% 
  filter(!str_detect(t1_work_id, '172740-an enquir')) %>% 
  filter(t1_work_id != '2736-modest defence of publick stews') %>% 
  group_by(bm_title, other_author) %>%
  summarize(reuse_length = sum(reuse_t1_t2))%>% 
 filter(reuse_length > 3500) %>% 
  filter(!is.na(other_author)) %>% 
  mutate(reuse_pages = reuse_length/1000) %>% 
  ungroup() %>% 
  count(other_author, wt = reuse_pages)%>% filter(other_author != 'Taylor, W.') %>% 
  mutate(other_author = ifelse(other_author == 'Shaftesbury, Anthony Ashley Cooper, Earl of, 1671-1713.', 
                                     'Earl of Shaftesbury, 1671-1713', other_author)) %>% slice_max(n, n = 10) %>% 
  ggplot() + 
  geom_col(aes(reorder(other_author, n), n)) + 
  coord_flip() + 
  labs(x = 'Reuse (in pages)', y = NULL) + 
  theme_bw()

top_4 = c('12915-fable of bees part ii', 
          '12916-free thoughts on religion church and national happiness by bm', 
          '2179-fable of bees or private vices public benefits',
          '8879-treatise of hypochondriack and hysterick passions')

new_names = c('Fable part II', 'Free Thoughts', 'Fable of the Bees', 'Treatise of Hypochondriack')

p2 = df %>% 
  left_join(gh1, by = c('t1_estc_id' = 'estc_id'))%>% 
  left_join(gh1, by = c('t2_estc_id' = 'estc_id'))%>% 
  rename(bm_short = short_title.x, short = short_title.y) %>% 
  rename(other_author = name_unified.y) %>% 
  ungroup() %>% 
  #left_join(ce1, by = c('t1_work_id' = 'work_id')) %>% 
  #left_join(ce1, by = c('t2_work_id' = 'work_id')) %>% 
  rename(t1_year = publication_year.x, 
         t2_year = publication_year.y) %>% 
  filter(t2_year > t1_year) %>% 
  filter(t1_reuses > 0.1) %>% 
  filter(!str_detect(t1_work_id, '172740-an enquir')) %>% 
  filter(t1_work_id %in% top_4) %>% 
  group_by(t1_work_id, t2_year) %>%
  summarize(reuse_length = sum(reuse_t2_t1)) %>% 
  #filter(reuse_length > 3500) %>% 
  mutate(reuse_pages = reuse_length/1000) %>%
  ungroup() %>% filter(t2_year %in% 1700:1800) %>% left_join(name_change, by = c('t1_work_id' ='original')) %>% 
  ggplot() + geom_col(aes(t2_year,reuse_pages, fill = new)) + 
  theme_bw()  + 
  theme(legend.position = 'bottom') + 
  labs(x = NULL, y = "Reuse (in pages)", fill = NULL) 

genres = read_csv('data/work/genres_with_predicted.csv')

df =mandeville_non_mandeville %>% 
  left_join(estc_core_c, by = c('t1_estc_id' = 'estc_id'))%>% 
  left_join(estc_core_c, by = c('t2_estc_id' = 'estc_id')) %>% 
  left_join(estc_authors, by =c('t2_estc_id' = 'estc_id'))%>% 
  filter(!str_detect(actor_name_primary, "(?i)horace")) %>% 
  filter(t2_estc_id %in% ce1$estc_id) %>% 
  filter(t1_work_id %in% name_change$original) %>% left_join(name_change, by = c('t1_work_id' = 'original')) %>% rename(label = new) %>% 
  filter(publication_year.x < publication_year.y) %>% 
  filter(publication_year.y %in% 1700:1800) %>% 
  left_join(genres, by = c('t2_work_id' = 'work_id')) %>% 
  count(label, main_category,wt = t1_length) %>% 
  filter(!str_detect(main_category, "sale"))%>% 
  filter(!is.na(main_category)) %>% 
  arrange(desc(n))


p3 = ggplot(data = df,
       aes(axis1 = label, axis2 = main_category,y = n)) +
  geom_alluvium(aes(fill = main_category), color = 'black') +
  geom_stratum() +
  geom_text(stat = "stratum",
            aes(label = after_stat(stratum))) +
  scale_x_discrete(limits = c("Survey", "Response"),
                   expand = c(0.15, 0.05)) +
  theme_void() + theme(legend.position = 'none', panel.background = element_blank(), panel.grid = element_blank())




p5 = mandeville_to_mandeville %>%  
  filter(t1_work_id!= t2_work_id) %>% 
  group_by(t1_work_id, t2_work_id) %>% 
  slice_max(t1_reuses, with_ties = FALSE) %>% 
  ungroup() %>% 
  select(t1_estc_id, t2_estc_id, coverage_t1_t2) %>% count(t1_estc_id) %>% arrange(desc(n)) %>% 
  left_join(estc_core_c %>% 
              select(estc_id, short_title), by = c('t1_estc_id'= 'estc_id')) %>% 
  filter(! t1_estc_id %in% c('T77578', 'T185660', 'T77576', 'T77713', 'T78343')) %>% 
  ggplot() + geom_col(aes(x = reorder(str_trunc(short_title,40), n),y = n)) + coord_flip() + 
  theme_bw() + labs(x = NULL, y = 'Text reuse in other Mandeville works')



ggsave('output/figures/final/figure_6_mandeville.pdf',p1, width = 8, height = 5)
ggsave('output/figures/final/figure_7_mandeville.pdf', p2, width = 8, height = 5)
ggsave('output/figures/final/figure_8_mandeville.pdf', p3, width = 8, height = 5)
ggsave('output/figures/final/figure_5_mandeville.pdf', p5, width = 8, height = 5)

