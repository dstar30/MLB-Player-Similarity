#Script to get pitching and batting data from Fangraphs

#loading packages
library(tidyverse)
library(baseballr)

#loading player IDs
players <- read_csv('players.csv')


#filtering on pitchers only
# pitchers <- players %>%
#   filter(primary_position_txt == "P")
# 
# pitchers$key_fangraphs <- as.character(pitchers$key_fangraphs)


#setting years to get data
years <- seq(1986, 2019, by = 1)

#building data frame to add seasons to
batting_stats_years <-fg_bat_leaders(2019, 2019, ind = 1, qual = 1)
pitching_seasons <- fg_pitch_leaders(2019, 2019, ind = 1, qual = 0)


#looping through years and adding batting data
for (year in years) {
  dat <- fg_bat_leaders(year, year, ind = 1, qual = 0)
  batting_stats_years <- rbind(batting_stats_years, dat)
}

#looping through years and gettting pitching data
start <- proc.time()[3]
for (year in years) {
  dat <- fg_pitch_leaders(year, year, ind = 1, qual = 0)
  pitching_seasons <- rbind(pitching_seasons, dat)
}
end <- proc.time()[3]

#creating a copy of the batting stats years so I don't have to pull data again if I make a mistake filtering
batting_seasons <- batting_stats_years

#cleaning up batting seasons
colnames(batting_seasons)[1] <- "key_fangraphs"
batting_seasons <- batting_seasons[,-2]
batting_seasons <- unique(batting_seasons)

#filtering on only players in the players table
batting_seasons <- batting_seasons %>%
  filter(batting_seasons$key_fangraphs %in% players$key_fangraphs)

#filtering pitching seasons
pitching_seasons <- pitching_seasons %>%
  filter(playerid %in% players$key_fangraphs)

#cleaning up pitching seasons
colnames(pitching_seasons)[1] <- "key_fangraphs"
pitching_seasons <- pitching_seasons[,-2]
pitching_seasons <- unique(pitching_seasons)

#checking to see if there are any missing players in batting data
setdiff(batting_seasons$key_fangraphs, players$key_fangraphs)
setdiff(players$key_fangraphs, batting_seasons$key_fangraphs)

#saving yearly batting stats to a csv file
#write.csv(batting_seasons, 'batting_seasons.csv', row.names = F, na = '')


# ---------------- gettting career batting stats -----------

#pulling batting stats from 1986-2019 from fangraphs
batting_career <- fg_bat_leaders(1986, 2019, qual = 0)

#filtering on only players in the players table
batting_career <- batting_career %>%
  filter(playerid %in% players$key_fangraphs)

#Getting rid of a column and changing a few column names to be the same as the other batting stats table
colnames(batting_career)[1] <- "key_fangraphs"
batting_career <- batting_career[,-3]
colnames(batting_career)[2] <- "Season"
colnames(batting_career)[203] <- "UBR"
colnames(batting_career)[204] <- "AgeRng"



#getting career pitching data
pitching_career <- fg_pitch_leaders(1986, 2019, qual = 0)

#filtering on only players in the players table
pitching_career <- pitching_career %>%
  filter(playerid %in% players$key_fangraphs)

#dropping a column and changing a few column names
colnames(pitching_career)[1] <- "key_fangraphs"
pitching_career <- pitching_career[,-3]
colnames(pitching_career)[2] <- "Season"


# write.csv(pitching_career, 'pitching_career.csv', row.names = F)
# write.csv(pitching_seasons, 'pitching_seasons.csv', row.names = F)

