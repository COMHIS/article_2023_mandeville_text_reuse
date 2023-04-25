library(tidyverse)
library(data.table)
library(tidytable)
library(igraph)
library(tidygraph)
library(ggraph)

all_mandeville_author_reuse = fread('/Users/yannryan/Downloads/mandeville_bipartitle_coverage-1679918703399.csv')

edges = all_mandeville_author_reuse %>% 
  left_join(estc_core_c %>% distinct(estc_id, .keep_all = TRUE) %>% 
              select(author_book_estc_id = estc_id, work_id), by = 'author_book_estc_id') %>% 
  left_join(estc_core_c  %>% distinct(estc_id, .keep_all = TRUE) %>% 
              select(inception_book_estc_id = estc_id, work_id), by = 'inception_book_estc_id') %>% 
  #filter(work_id.x != work_id.y) %>% 
  #filter.(author_book_estc_id %in% first_eds & inception_book_estc_id %in% first_eds) %>% 
  filter.(coverage >.2) %>% 
  distinct.(author, inception_book_ecco_id, .keep_all = TRUE) %>% 
  select.(author, inception_book_ecco_id, weight = coverage)



g = graph_from_data_frame(edges)

V(g)$type <- bipartite_mapping(g)$type

bi_g = bipartite_projection(g, which = 'false')

g_tbl = bi_g %>% as_tbl_graph(directed = FALSE) %>% 
  left_join(estc_actors_c, by = c('name' = 'actor_id')) %>%
  mutate(comm = group_louvain(weights = weight)) %>% 
  #filter(comm == 1) %>% 
  mutate(degree = centrality_degree(weights =weight, mode = 'all')) %>% 
  filter(degree >1) %>% 
  #mutate(comm2 = group_louvain(weights = weight)) %>% 
  mutate(between = centrality_betweenness(weights =NULL))

m_reuses_by_author = mandeville_non_mandeville %>% 
  left_join(estc_authors, by = c('t2_estc_id' = 'estc_id'))

m_reuses_by_author = m_reuses_by_author %>% count(actor_id, t1_work_id, wt = coverage_t1_t2)

top_work = mandeville_non_mandeville %>% count(t1_work_id, wt = t1_length) %>%
  filter(!str_detect(t1_work_id, 'enquiry')) %>%
  filter(!str_detect(t1_work_id, 'abeilles'))%>%
  filter(!str_detect(t1_work_id, '2736-modest defence of publick stews')) %>%
  arrange(desc(n)) %>% head(6) %>% 
  mutate(label = c('Fable of the Bees', 'Treatise of Hypocondriack', 'Free Thoughts', 'Fable Part II', 'Virgin Unmaskd', 'Some Fables'))


p4 = g_tbl %>% 
  as_tibble()  %>% 
  mutate(name_unified = paste0(name_unified, " (", degree, ")")) %>% 
  arrange(desc(degree)) %>% 
  left_join(m_reuses_by_author, by = c('name' = 'actor_id')) %>% 
  inner_join(top_work, by = c('t1_work_id')) %>% 
  mutate(comm = ifelse(comm == 1, "Community 1 (literary)", "Community 2 (religious)")) %>% 
  count(comm,label) %>% ggplot() + 
  geom_col(aes(x = label, y = n)) +
  facet_wrap(~comm, ncol = 1)  + theme_bw()+ 
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust =1)) + labs(x = NULL, y = "Mandeville Reuse")

ggsave('output/figures/final/figure_9_mandeville.pdf', p4, width = 8, height = 8)
