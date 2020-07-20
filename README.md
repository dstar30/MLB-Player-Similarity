# CSE6242 Project - MLB Player Similarity

## DESCRIPTION
The objective of this project is to create an MLB player similarity algorithm and generate an interactive visualzation of the results.  This repository contains the code necessary to acquire data, conduct dimensonality reduction on player statistics using Principal Components Analysis, cluster players using k-means, and create similarity rankings using three different measures: Euclidean Distance, Manhattan Distance, and Cosine Similarity.  Running the code will result in a new /data folder containing the datasets required to build a visulation: batting_pca_cluster.csv and batting_stats.csv.  

------------------
ABOUT THE VIZ
------------------
We used Tableau to create the visualization and also have a link published on Tableau Public:

https://public.tableau.com/profile/john.welt7947#!/vizhome/MLBPlayerComparisonv2/FindingSimilarMLBBatters?publish=yes

You are welcome to make your own modifications to the Tableau workbook (MLB-PlayerComparison.twbx), create a new Tableau design, or create a viualization with another tool.

------------------
ABOUT THE DATA
------------------
The data used comes from a variety of sources.  We retrieved player id mappings from the Chadwick Baseball Bureau (http://chadwick-bureau.com/), an organization committed to tidy and accessible data in support of baseball writing an analysis. Additional player data was acquired using the MLB Player Info API. Player salary data was scraped from USA Today (https://www.usatoday.com/sports/mlb/salaries/) who has a subsite that posts player salaries by season. The batting statistics were retrieved from Fangraphs using an R package.  Below are names and descriptions of the datasets: 

1. players --> staging data used for model providing player information and id mapping from different sources (e.g. MLB to Fangraphs)
2. batting_by_year --> staging data used for model providing comprehensive player batting stats from Fangraphs
3. salaries --> staging data showing player salary data. It has been a challenge to pull the salary data from a source where we can merge the salary data with the players data. You are welcome to examine the salaries data, incorporate and expand on the existing project.
4. batting_pca_cluster  --> visualization data showing the principal components and cluster assignments for each player by season
5. batting_stats --> visualization data showing the player stats and similarity rankings across different similarity measures by season

**********************************************************
INSTALLATION
**********************************************************
Installation is simple.  Simply save or clone the "code" folder to a local directory and follow the execution steps.  You can clone the data from this repo: https://github.gatech.edu/jwelt3/team63-MLB-Player-Similarity. Please ensure you have the following dependencies installed:

Python 3.6+
------------------
Modules: pandas, numpy, BeautifulSoup, requests, datetime, os, numpy, sklearn

R 3.4+
------------------
Libraries: tidyverse, httr, jsonlite, baseballr

Tableau
------------------
Tableau Desktop Professional 2019.2+ (costs $)
--OR--
Tableau Public Desktop App 2019.3+ (free and available to download at: https://public.tableau.com/en-us/s/download)


**********************************************************
EXECUTION
**********************************************************
To begin, the code folder does not contain any data, but you can re-create the datasets needed by running the following code.  Running this code will create a new sub-folder called "data" that contains a csv representing each dataset.

1. Run "code\_1_get_player_data.R" to create players.csv
2. Run "code\_2_get_salary_data.py" to create salaries.csv
3. Run "code\_3_get_batting_stats.R" to create batting_by_year.csv

Once those three datasets have been created, you can run the below script which performs PCA, k-means clustering, and similarity measures on the data and outputs the final two datsets which can be connected to the tableau workbook.

4. Run "code\_4_batting_model.py" to create batting_stats.csv and batting_pca_cluster.csv

At this point, all of the datasets have been created and you can begin building or modifying visualizations.  If using Tableau, you can use the MLB-PlayerComparison.twbx workbook as a starting point.  You can also download the workbook directly from Tableau Public.  You are also free to use your preferred tools and make modifications to any of the code.

**********************************************************
DEMO VIDEO
**********************************************************
https://youtu.be/jr6YzKwa-ww
