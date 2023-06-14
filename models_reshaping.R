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


#create a subset with rows that have these unclear/unknown values in the `model` column
autos_subset <- filter(autos, model %in% models_to_filter)

#create a new column with " " instead of underscores "_"

autos_subset$name_new <- gsub("_", " ",autos_subset$name)

#use `unnest_tokens` to place every word in its own row

autos_subset_tidy <- autos_subset %>% 
  unnest_tokens(output = names_word,
                input = name_new)

#get rid of the brand names
autos_subset_tidy <- autos_subset_tidy %>% 
  filter(!names_word %in% brands)

#now that we have column without brand names we can pull model names from it 

autos_subset_tidy <- autos_subset_tidy %>% 
  group_by(index) %>% 
  slice(1)

#mercedes tend to use letter and number to indicate model E 120, 
#so unless I pull up first two words I am gonna get only a letter which isn't very informative
#create a subset for mercedes only

mercedes <- autos_subset_tidy %>% 
  filter(brand == "mercedes_benz") %>% 
  group_by(index) %>% 
  slice(1,2)

mercedes<- mercedes %>% 
  group_by(index) %>% 
  mutate(model_new = paste(names_word, collapse = " ")) %>% 
  slice(1)

#theres also a brand named "sonstige_autos" that in fact isn't a brand,
#but rather a sign that the car is made in the USA

sonstige<- autos_subset_tidy %>% 
  filter(brand == "sonstige_autos")


  
