library(tidyverse)
library(keyring)
library(DBI)
library(RMariaDB)

while (!exists("con")) {
  tryCatch(con <- dbConnect(
    drv = MariaDB(),
    host = "vm3065.kaj.pouta.csc.fi",
    dbname = "hpc-hd",
    user = if (Sys.getenv("DB_USER")!="") Sys.getenv("DB_USER") else key_get("filter_overview","DB_USER"),
    password = if (Sys.getenv("DB_PASS")!="") Sys.getenv("DB_PASS") else key_get("filter_overview","DB_PASS"),
    bigint = "integer",
    load_data_local_infile = TRUE,
    autocommit = TRUE,
    reconnect = TRUE
  ), error = function(e) {
    print(e)
    key_set("filter_overview","DB_USER", prompt="DB username: ")
    key_set("filter_overview","DB_PASS", prompt="DB password: ")
  })
}

estc_core = tbl(con,dbplyr::in_schema("hpc-hd","estc_core_a") )

estc_actor_links = tbl(con,'estc_actor_links_a',dbplyr::in_schema("hpc-hd","estc_actor_links_a"))

estc_actors = tbl(con,'estc_actors',dbplyr::in_schema("hpc-hd","estc_actors"))


