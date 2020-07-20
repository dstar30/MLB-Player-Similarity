#Script to get player IDs and player info from the MLB API

#loading packages
library(tidyverse)
library(httr)
library(jsonlite)


#------------------------- Code for getting player IDs from Chadwick Bureau -----------------------------------

#grabbing baseball player ids from the Chadwick Bureau Register
baseball_ids <- read.csv('https://raw.githubusercontent.com/chadwickbureau/register/master/data/people.csv', header = T, stringsAsFactors = F)

#filtering on only players who played in MLB in 2019
baseball_ids_2009 <- baseball_ids %>%
  filter(mlb_played_last > 2009) %>%
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

write.csv(baseball_ids_2009, 'player_ids.csv', row.names = F)


#-------------------------- Code for getting player data from the MLB API -------------------------------------

#creating copy of id table to add player info to
players <- baseball_ids_2009

#adding empty columns to add data from MLB API
players['status'] <- NA #column 17
players['age'] <- NA #column 18
players['height_feet'] <- NA #column 19
players['height_inches'] <- NA #column 20
players['pro_debut'] <- NA #column 21
players['primary_positon'] <- NA #column 22
players['primary_position_txt'] <- NA #column 23
players['team_abb'] <- NA  #column 24
players['team_name'] <- NA  #column 25
players['weight'] <- NA  #column 26
players['birth_city'] <- NA  #column 27
players['birth_state'] <- NA  #column 28
players['birth_country'] <- NA  #column 29
players['birthdate'] <- NA  #column 30
players['throws'] <- NA  #column 31
players['bats'] <- NA  #column 32
players['jersey_number'] <- NA  #column 33



#function to get player details from MLB API
#looping through players and getting additional data
for (i in 1:nrow(players)) {
  id <- players[i, 3]
  url <- paste0('http://lookup-service-prod.mlb.com/json/named.player_info.bam?sport_code=\'mlb\'&player_id=\'', id, '\'') 
  
  player <- RETRY("GET", url, times = 5)
  player <- fromJSON(content(player, 'text'))
  
  #filling in columns
  players[i, 17] <- player$player_info$queryResults$row$status
  players[i, 18] <- player$player_info$queryResults$row$age
  players[i, 19] <- player$player_info$queryResults$row$height_feet
  players[i, 20] <- player$player_info$queryResults$row$height_inches
  players[i, 21] <- player$player_info$queryResults$row$pro_debut_date
  players[i, 22] <- player$player_info$queryResults$row$primary_position
  players[i, 23] <- player$player_info$queryResults$row$primary_position_txt
  players[i, 24] <- player$player_info$queryResults$row$team_abbrev
  players[i, 25] <- player$player_info$queryResults$row$team_name
  players[i, 26] <- player$player_info$queryResults$row$weight
  players[i, 27] <- player$player_info$queryResults$row$birth_city
  players[i, 28] <- player$player_info$queryResults$row$birth_state
  players[i, 29] <- player$player_info$queryResults$row$birth_country
  players[i, 30] <- player$player_info$queryResults$row$birth_date
  players[i, 31] <- player$player_info$queryResults$row$throws
  players[i, 32] <- player$player_info$queryResults$row$bats
  players[i, 33] <- player$player_info$queryResults$row$jersey_number
}


#adding a few columns 
players <- players %>%
  mutate(primary_position_full_txt = case_when(primary_position_txt == 'P' ~ 'Pitcher',
                                               primary_position_txt == 'RF' ~ 'Right Field',
                                               primary_position_txt == '1B' ~ 'First Base',
                                               primary_position_txt == '2B' ~ 'Second Base',
                                               primary_position_txt == 'LF' ~ 'Left Field',
                                               primary_position_txt == 'SS' ~ 'Short Stop',
                                               primary_position_txt == '3B' ~ 'Third Base',
                                               primary_position_txt == 'CF' ~ 'Center Field',
                                               primary_position_txt == 'C' ~ 'Catcher',
                                               primary_position_txt == 'OF' ~ 'Outfield',
                                               primary_position_txt == 'DH' ~ 'Designated Hitter'),
         throws_text = if_else(throws == 'R', 'Right', 'Left'),
         bats_text = if_else(bats == 'R', 'Right',
                             if_else(bats == 'S', 'Switch', 'Left')),
         height = paste0(height_feet, '\' ', height_inches, '\"'))


#american league
AL <- c('TOR', 'TEX', 'TB', 'SEA', 'OAK', 'NYY', 'MIN', 'KC', 'HOU', 'DET', 'CLE', 'CWS', 'BOS', 'BAL', 'LAA')

#adding league
players <- players %>%
  mutate(league = if_else(team_abb %in% AL, 'American League', 'National League'))

#cleaning up date columns
players$pro_debut <- as.Date(players$pro_debut)
players$birthdate <- as.Date(players$birthdate)

# write to /data folder
mainDir <- paste(getwd(), 'code', sep='/')
dir.create(file.path(mainDir, 'data'), showWarnings = FALSE)
write.csv(players, 'data/players.csv')





