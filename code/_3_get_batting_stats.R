#Script to get pitching and batting data from Fangraphs

#loading packages
# install.packages('devtools')
# install.packages('rlang')
# devtools::install_github("BillPetti/baseballr")
library(tidyverse)
library(baseballr)

#loading player IDs
players <- read_csv('data/players.csv')

#setting years to get data
years <- seq(2010, 2019, by = 1)

#building data frame to add seasons to
batting_stats_years <-fg_bat_leaders(2019, 2019, ind = 1, qual = 1)

#looping through years and adding batting data
for (year in years) {
  dat <- fg_bat_leaders(year, year, ind = 1, qual = 0)
  batting_stats_years <- rbind(batting_stats_years, dat)
}

#creating a copy of the batting stats years so I don't have to pull data again if I make a mistake filtering
batting_seasons <- batting_stats_years

#cleaning up batting seasons
colnames(batting_seasons)[1] <- "key_fangraphs"
batting_seasons <- batting_seasons[,-2]
batting_seasons <- unique(batting_seasons)

#filtering on only players in the players table
# TODO: add primary_position and primary_position_txt to select after Name
batting_seasons <- batting_seasons %>%
  filter(batting_seasons$key_fangraphs %in% players$key_fangraphs) %>%
  mutate(key_fangraphs=as.double(key_fangraphs)) %>%
  inner_join(players, by="key_fangraphs") %>%
  select(key_fangraphs, Name, primary_positon, primary_position_txt, Season, Age, G, AB, PA, H, "1B", "2B", "3B", HR, R, RBI
      , BB, IBB, SO, HBP, SF, SH, GDP, SB, CS, AVG, GB, FB, LD, IFFB, Pitches
      , Balls, Strikes, IFH, BU, BUH, BB_pct, K_pct, BB_K, OBP, SLG, OPS, ISO
      , BABIP, wOBA, wRAA, wRC, WAR, GB_FB, LD_pct, GB_pct, FB_pct, IFFB_pct, HR_FB
      , IFH_pct, BUH_pct, Pull_pct, Cent_pct, Oppo_pct, Soft_pct, Med_pct, Hard_pct
      , "O-Swing_pct", "Z-Swing_pct", Swing_pct, "O-Contact_pct", "Z-Contact_pct"
      , Contact_pct, Zone_pct, "F-Strike_pct", SwStr_pct)

# clean up column name
names(batting_seasons) <- tolower(names(batting_seasons))

batting_seasons <- batting_seasons %>%
  rename("_1b"="1b", "_2b"="2b", "_3b"="3b", "o_swing_pct"="o-swing_pct"
      , "z_swing_pct"="z-swing_pct", "o_contact_pct"="o-contact_pct"
      , "z_contact_pct"="z-contact_pct", "f_strike_pct"="f-strike_pct")

batting_final <- batting_seasons %>%
  mutate(bb_pct = bb_pct/100, k_pct=k_pct/100, ld_pct = ld_pct/100, gb_pct=gb_pct/100,
        fb_pct=fb_pct/100, iffb_pct=iffb_pct/100, hr_fb=hr_fb/100, ifh_pct=ifh_pct/100, buh_pct=buh_pct/100,
        pull_pct=pull_pct/100, cent_pct=cent_pct/100, oppo_pct=oppo_pct/100, soft_pct=soft_pct/100,
        med_pct=med_pct/100, hard_pct=hard_pct/100, o_swing_pct=o_swing_pct/100,
        z_swing_pct=z_swing_pct/100, swing_pct=swing_pct/100, o_contact_pct=o_contact_pct/100,
        z_contact_pct=z_contact_pct/100, contact_pct=contact_pct/100, zone_pct=zone_pct/100,
        f_strike_pct=f_strike_pct/100, swstr_pct=swstr_pct/100)

# test data
# head(filter(batting_final, pa>200))

# write to /data folder
mainDir <- paste(getwd(), 'code', sep='/')
dir.create(file.path(mainDir, 'data'), showWarnings = FALSE)
write.csv(batting_final, 'data/batting_by_year.csv')

