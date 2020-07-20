setwd("~/OneDrive - Georgia Institute of Technology/Georgia Tech/CSE6242/cse6242-team63")
install.packages('odbc')

# load libraries
library(dplyr)
library(Lahman)
library(tidyverse)
library(stringr)
library(tidyr)
library(reshape2)
library(odbc)

# set up connection
conn <- dbConnect(odbc(),
                 Driver = "ODBC Driver 17 for SQL Server",
                 Server = "team63sqlserver.cjfujwbtm3vk.us-east-1.rds.amazonaws.com",
                 Database = "baseball",
                 UID = "admin",
                 PWD = rstudioapi::askForPassword("Password"),
                 Port = 1433)

# filter Lahman's Salaries data for 2010 - 2016
test_salaries <- Salaries %>%
            filter(yearID == 2010) %>%
            filter(str_detect(playerID,"02"))

# load salaries data
salaries_2019 <- read.csv("salaries_2019.csv", header = F, stringsAsFactors = F)
salaries_2018 <- read.csv("salaries_2018.csv", header = F, stringsAsFactors = F)
salaries_2017 <- read.csv("salaries_2017.csv", header = F, stringsAsFactors = F)
salaries_2016 <- read.csv("salaries_2016.csv", header = F, stringsAsFactors = F)
salaries_2015 <- read.csv("salaries_2015.csv", header = F, stringsAsFactors = F)
salaries_2014 <- read.csv("salaries_2014.csv", header = F, stringsAsFactors = F)
salaries_2013 <- read.csv("salaries_2013.csv", header = F, stringsAsFactors = F)
salaries_2012 <- read.csv("salaries_2012.csv", header = F, stringsAsFactors = F)
salaries_2011 <- read.csv("salaries_2011.csv", header = F, stringsAsFactors = F)
salaries_2010 <- read.csv("salaries_2010.csv", header = F, stringsAsFactors = F)

# add yearID column
salaries_2010$yearID <- 2010
salaries_2011$yearID <- 2011
salaries_2012$yearID <- 2012
salaries_2013$yearID <- 2013
salaries_2014$yearID <- 2014
salaries_2015$yearID <- 2015
salaries_2016$yearID <- 2016
salaries_2017$yearID <- 2017
salaries_2018$yearID <- 2018
salaries_2019$yearID <- 2019

# append all dataframes
salaries <- rbind(salaries_2010, salaries_2011, salaries_2012, salaries_2013, salaries_2014, salaries_2015, salaries_2016, salaries_2017, salaries_2018, salaries_2019)

# rename columns
colnames(salaries) <- c("playerName", "teamID", "salary", "yearID")

# split player name into first name and last name
names_col <- colsplit(salaries$playerName, " ", c("name_first", "name_last"))
# split further to remove middle name
last_name <- colsplit(names_col$name_last, "[A-Z]\\.", c("v1", "v2"))
last_name$name_last <- paste(last_name$v1, last_name$v2)

# combine
salaries <- cbind(salaries, names_col$name_first)
salaries <- cbind(salaries, last_name$name_last)
colnames(salaries) <- c("playerName", "teamID", "salary", "yearID", "name_first", "name_last")

write.csv(salaries, "salaries.csv", row.names = F)