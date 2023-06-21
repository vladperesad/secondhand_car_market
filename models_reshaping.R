library(tidyverse)
library(tidytext)

#Load up the csv file
autos <- read.csv("autos.csv")

#and file that contains brand names
auto_brands <- read.csv("auto_brands.csv")


#there are a few model names that don't tell much about the car, 
#e.g. 'andere', '3er' or simply missing values 
#I can try and use `names` column to derive more legible model names

#get rid of hyphens in some names e.g lorraine-dietrich 
#insert the new values into  field brand_new

auto_brands$brand_new <- gsub("-"," ",auto_brands$Brand)

#use unnest tokens to place every word in its own row
auto_brands<- auto_brands %>% 
  unnest_tokens(output = brand_word,
                input = brand_new)

#create a list of brand names
brands <- auto_brands$brand_word

#add a few possible ways to spell some brands
brands <- c("vw",
            "moskvich",
            "luaz",
            brands)


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
##get rid of the brand names in the `name_new` column

autos_subset<- autos_subset %>% 
  unnest_tokens(output = names_word,
                input = name_new) %>% 
  filter(!names_word %in% brands)


#by the way the names are written there is usually a brand name and then the second 
#word is a model name e.g. Skoda Fabia or Subaru Impreza 
#now that we have column without brand names we can pull first word that would be a model name  

autos_subset_tidy <- autos_subset %>% 
  group_by(index) %>% 
  slice(1) %>% 
  select(index,model=names_word)

autos<-autos_subset_tidy %>% 
  full_join(autos, by = "index", suffix = c('','.1')) %>% 
  mutate(model = coalesce(model, model.1)) %>% 
  select(-model.1)

#mercedes tend to use letter and number to indicate model e.g E 120, 
#so unless I pull up first two words I am going to get only a letter which 
#indicates the class and not the model and isn't very informative
#create a subset for mercedes cars only
#after that I can concatenate the rows for each vehicle together 

mercedes <- autos_subset %>%
  filter(brand == "mercedes_benz") %>%
  group_by(index) %>% 
  slice(1,2) %>% 
  mutate(model_new = paste(names_word, collapse = " ")) %>% 
  slice(1) %>% 
  select(index, model=model_new)

autos<-mercedes %>% 
  full_join(autos, by = "index", suffix = c('','.1')) %>% 
  mutate(model = coalesce(model, model.1)) %>% 
  select(-model.1)

#theres also a brand named "sonstige_autos" that in fact isn't a brand,
#but rather a sign that the car is most likely made outside of Germany 
#or belongs to an old/not well known manufacturer
#let's create a subset that has "sonstige_autos" in the brand column 

sonstige<- autos %>% 
  filter(brand == "sonstige_autos") %>% 
  select(index,name)

#and substitute underscores with the spaces and split the words so that each one is in its own row

sonstige$name_new <- gsub("_", " ",sonstige$name)

#as it can be seen the first word in `name` column is usually a brand name 
#and the word after that is a model name, so I will put the first word in 
#column `brand` and the second one in the column `model`


#create a subset that contains index and brand columns
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

#use full_join and coalesce functions to substitute values in columns 
#`brand` and `model` in autos with the ones from sonstige 
autos<-sonstige %>% 
  full_join(autos, by = "index", suffix = c('','.1')) %>% 
  mutate(brand = coalesce(brand, brand.1), model = coalesce(model, model.1)) %>% 
  select(-brand.1,-model.1)


#let's look at the values in the brand column, it can be eaasily seen 
#that unfortunately there are quite a lot of words that were used in the name 
#column but don't make much sense e.g freisprecheinrichtung or gaaaaanz
#so i am going to utilize `brand` vector once again to make sure only rows with 
#legit brand names are present

unique(autos$brand)

autos <- autos %>% 
  filter(brand %in% brands)


#while we're at it I can also clean up the dates and bring them into more 
#appropriate format YYYY-MM-DD and get rid of the times as they're not that important

autos <- autos %>% 
  mutate(dateCrawlednew = strptime(dateCrawled,"%Y-%m-%d"),
         dateCreatednew = strptime(dateCreated,"%Y-%m-%d"),
         lastSeennew = strptime(lastSeen,"%Y-%m-%d")) %>% 
  select(!c(dateCrawled, dateCreated, lastSeen))

write.csv(autos,"autos_cleaned.csv")




  
