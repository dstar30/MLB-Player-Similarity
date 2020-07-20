
library(tidyverse)

#grabbing baseball player ids from the Chadwick Bureau Register
baseball_ids <- read.csv('https://raw.githubusercontent.com/chadwickbureau/register/master/data/people.csv', header = T, stringsAsFactors = F)

#filtering on only players who played in MLB in 2019
baseball_ids_2019 <- baseball_ids %>%
  filter(mlb_played_last == 2019) %>%
  select(key_person,
         key_uuid,
         key_mlbam,
         key_retro,
         key_bbref,
         key_fangraphs,
         name_first,
         name_last,
         name_given, 
         name_nick, 
         birth_year,
         birth_month, 
         birth_day,
         pro_played_first,
         mlb_played_first,
         mlb_played_last)




