# code/final

Finished code used for article analysis and figures. 

Code is based on SQL queries of the COMHIS text reuse MariaDB database. 

get_connection.R connects to the MariaDB database (username and password required)

mandeville_non_mandeville.R (and .sql) calculates the coverage proportion (i.e. the total amount of overlap) of all Mandeville to non-Mandeville texts.

mandeville_to_mandeville calculates the coverage proportion of Mandeville texts to other Mandeville texts. 

The results of these are saved as intermediate .csv files, in Data -> Final. 

mandeville_plots.R uses the raw coverages information to generate figures for publication. 
