library(tidyverse)
library(tidytext)

#Load up the csv file

autos <- read.csv("autos.csv")

#theres a brand named "sonstige_autos" that in fact isn't a brand,
#but rather a sign that the car is made in the USA
#let's create a subset that has "sonstige_autos" in the brand column 

sonstige<- autos %>% 
  filter(brand == "sonstige_autos") %>% 
  select(index,name)

#and substitute underscores with the spaces and split the words so that each one is in its own row

sonstige$name_new <- gsub("_", " ",sonstige$name)

#as it can be seen the first word in `name` column is usually a brand name 
#and the word after that is a model name, so I will put the first word in 
#column `brand` and the second one in the column `model`


#create a subset that would contain index and brand columns
sonstige_brand <- sonstige %>% 
  unnest_tokens(output = names_word,
                input = name_new) %>% 
  group_by(index) %>% 
  mutate(brand = names_word) %>% 
  slice(1) %>% 
  select(index,brand)

#another subset that has index and model columns
sonstige_model<-sonstige %>% 
  unnest_tokens(output = names_word,
                input = name_new) %>% 
  group_by(index) %>% 
  mutate(model = names_word) %>% 
  slice(2) %>% 
  select(index,model)

#use `merge` to put values from the subsets into "sonstige"

sonstige <- sonstige %>% 
  merge(sonstige_model, by = "index") %>% 
  merge(sonstige_brand, by = "index") %>% 
  select(index,brand,model)



#create a list of brand names
brands <- unique(autos$brand)

#add a few possible ways to spell some brands
brands <- c("vw","mercedes","benz","mercedesbenz","mercedes-benz", brands)

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

#create a new column for `name` with " " instead of underscores "_" called `name_new`

autos_subset$name_new <- gsub("_", " ",autos_subset$name)

#use `unnest_tokens` to place every word in its own row

autos_subset_tidy <- autos_subset %>% 
  unnest_tokens(output = names_word,
                input = name_new)

#get rid of the brand names in the `name_new` column
autos_subset_tidy <- autos_subset_tidy %>% 
  filter(!names_word %in% brands)

#mercedes tend to use letter and number to indicate model e.g E 120, 
#so unless I pull up first two words I am gonna get only a letter which 
#indicates the class and not the model and isn't very informative
#create a subset for mercedes cars only
#after that I can concatenate the rows for each vehicle together 

mercedes <- autos_subset_tidy %>% 
  filter(brand == "mercedes_benz") %>% 
  group_by(index) %>% 
  slice(1,2) %>% 
  mutate(model_new = paste(names_word, collapse = " ")) %>% 
  slice(1)

#theres also a brand named "sonstige_autos" that in fact isn't a brand,
#but rather a sign that the car is made in the USA

sonstige<- autos_subset_tidy %>% 
  filter(brand == "sonstige_autos")

#as it can be seen the first word in `name` column is usally a brand name 
#and the word after that is a model name, so I will put the first word in 
#column `brand` and the second one in the column `model`





#by the way the names are written there is usually a brand name and then the second 
#word is a model name e.g. Skoda Fabia or Subaru Impreza 
#now that we have column without brand names we can pull first word that would be a model name  

autos_subset_tidy <- autos_subset_tidy %>% 
  group_by(index) %>% 
  slice(1)

glimpse(unique(autos_subset_tidy$names_word)) 


  
