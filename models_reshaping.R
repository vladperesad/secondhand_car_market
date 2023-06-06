library(tidyverse)
library(tidytext)

#Load up the csv file

autos <- read.csv("autos.csv")

#pull up all the unique values in brand column

unique(autos$brand)


#create a list of brand names
brands <- unique(autos$brand)

#add a few possible ways to spell some brands
brands <- c("vw","mercedes","benz","mercedesbenz", brands)

#take a look at the vector created
brands

#create a list of models that are not particularly clear or unknown
unique(autos$model)

models_to_filter <- c("",
                     "3er",
                     "2_reihe",
                     "andere",
                     "3_reihe",
                     "a_klasse",
                     "e_klasse",
                     "b_klasse",
                     "c_klasse",
                     "m_klasse",
                     "s_klasse",
                     "5er",
                     "1er",
                     "xc_reihe",
                     "7er",
                     "z_reihe",
                     "i_reihe",
                     "6_reihe",
                     "5_reihe",
                     "rx_reihe",
                     "6er",
                     "x_reihe",
                     "1_reihe",
                     "4_reihe",
                     "mx_reihe",
                     "m_reihe",
                     "cr_reihe",
                     "c_reihe",
                     "v_klasse",
                     "x_type",
                     "cx_reihe",
                     "g_klasse",
                     "serie_3",
                     "serie_1")

autos_subset <- filter(autos, model %in% models_to_filter)

#create a new column with " " instead of spaces

autos_subset$name_new <- gsub("_", " ",autos_subset$name)

#use `unnest_tokens` to place every word in its own row

autos_subset_tidy <- autos_subset %>% 
  unnest_tokens(output = names_word,
                input = name_new)

autos_subset_tidy <- autos_subset_tidy %>% 
  filter(!names_word %in% brands)

#now that we have column without brand names we can pull model names from it 

