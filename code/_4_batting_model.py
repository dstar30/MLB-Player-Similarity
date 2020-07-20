import pandas as pd
import numpy as np
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.metrics.pairwise import euclidean_distances, manhattan_distances, cosine_similarity
import os
# import matplotlib.pyplot as plt
# import seaborn as sns

# set up directories
if os.getcwd()[-4:] == 'code':
    next
else:
    os.chdir(os.getcwd() + '\\' + 'code')
try:
    os.makedirs("data")
except FileExistsError:
    # directory already exists
    pass

# query and view the table from SQL
df = pd.read_csv('data/batting_by_year.csv')
# df.head()

# eliminate unnecessary data
attributes = ['key_fangraphs', 'season', 'name', 'primary_position_txt', 'pa']
keepers = ['key_fangraphs', 'season' , 'name', 'primary_position_txt', 'pa', 'bb_pct', 
        'k_pct', 'bb_k', 'gb_fb', 'ld_pct', 'gb_pct', 'fb_pct',
        'pull_pct', 'cent_pct',
       'oppo_pct', 'soft_pct', 'med_pct', 'hard_pct', 'o_swing_pct',
       'z_swing_pct', 'swing_pct', 'o_contact_pct', 'z_contact_pct',
       'contact_pct', 'zone_pct', 'f_strike_pct', 'swstr_pct']

batsDF = df[keepers]
batsDF = batsDF.iloc[np.where(batsDF['pa'] > 99)]

# remeove pitchers with batting data
batsDF = batsDF.loc[batsDF['primary_position_txt'] != 'P']
batsDF.describe()
batsDF.isnull().sum(axis = 0) # No Nulls!

# loop through seasons
seasons = batsDF['season'].unique()

# seasons = [2019] # for testing

resultsDF = pd.DataFrame()
similarityDF = pd.DataFrame()

for i in seasons:
    # filter to season
    mDF = batsDF.loc[batsDF['season'] == i]
    attrDF = mDF[attributes].reset_index()
    mDF = mDF.drop(columns=attributes)

    # scale data
    X = StandardScaler().fit_transform(mDF)

    # peform PCA
    pca = PCA(n_components=2)
    principal_components = pca.fit_transform(X) 
    pcaDF = pd.DataFrame(principal_components, columns = ['pc1', 'pc2'])

    # # Test Different Cluster Sizes and Visualize
    # wcss = []
    # for j in range(1, 11):
    #     kmeans = KMeans(n_clusters=j, init='k-means++', max_iter=300, n_init=10, random_state=0).fit(X)
    #     wcss.append(kmeans.inertia_)
    # plt.plot(range(1, 11), wcss)
    # plt.title('Elbow Method')
    # plt.xlabel('Number of clusters')
    # plt.ylabel('WCSS')
    # plt.show()

    # K-means
    X = pcaDF.to_numpy()
    kmeans = KMeans(n_clusters=4, random_state=0).fit(X)
    kmeansDF = pd.DataFrame(kmeans.labels_, columns = ['cluster'])

    results = attrDF.join(pcaDF).join(kmeansDF)
    resultsDF = resultsDF.append(results)

    # similarity measures
    euc_dist = euclidean_distances(results[['pc1', 'pc2']].values)
    man_dist = manhattan_distances(results[['pc1', 'pc2']].values)
    cos_sim = cosine_similarity(results[['pc1', 'pc2']].values)

    # similarity table
    similar = {'season':[], 'source_key_fangraphs':[], 'target_key_fangraphs': [], 
        'similarity_measure':[], 'similarity_value':[], 'rank':[]}

    for j in range(euc_dist.shape[0]):
        a = euc_dist[j, :]
        ind = np.argpartition(a, 11)[:11]
        top10 = ind[np.argsort(a[ind])]
        [similar['season'].append(i) for k in top10]
        [similar['source_key_fangraphs'].append(results.iloc[j]['key_fangraphs']) for k in top10]
        [similar['target_key_fangraphs'].append(results.iloc[k]['key_fangraphs']) for k in top10]
        [similar['similarity_measure'].append('Euclidean Distance') for k in top10]
        [similar['similarity_value'].append(euc_dist[j, k]) for k in top10]
        [similar['rank'].append(k[0]) for k in enumerate(top10)]

    for j in range(man_dist.shape[0]):
        a = man_dist[j, :]
        ind = np.argpartition(a, 11)[:11]
        top10 = ind[np.argsort(a[ind])]
        [similar['season'].append(i) for k in top10]
        [similar['source_key_fangraphs'].append(results.iloc[j]['key_fangraphs']) for k in top10]
        [similar['target_key_fangraphs'].append(results.iloc[k]['key_fangraphs']) for k in top10]
        [similar['similarity_measure'].append('Manhattan Distance') for k in top10]
        [similar['similarity_value'].append(man_dist[j, k]) for k in top10]
        [similar['rank'].append(k[0]) for k in enumerate(top10)]

    for j in range(cos_sim.shape[0]):
        a = cos_sim[j, :]
        ind = np.argpartition(a, -11)[-11:]
        top10 = np.flip(ind[np.argsort(a[ind])])
        [similar['season'].append(i) for k in top10]
        [similar['source_key_fangraphs'].append(results.iloc[j]['key_fangraphs']) for k in top10]
        [similar['target_key_fangraphs'].append(results.iloc[k]['key_fangraphs']) for k in top10]
        [similar['similarity_measure'].append('Cosine Similarity') for k in top10]
        [similar['similarity_value'].append(cos_sim[j, k]) for k in top10]
        [similar['rank'].append(k[0]) for k in enumerate(top10)]

    similarityDF = similarityDF.append(pd.DataFrame(similar))

# enrich results and write to csv

# creating battin_pca_cluster dataset
players = pd.read_csv('data/players.csv')
player_small = players[['key_fangraphs', 'key_mlbam', 'name_first', 'name_last']]
player_small = player_small.rename(columns={'key_mlbam':'mlb_id'})
batting_pca_cluster = resultsDF.merge(player_small, on='key_fangraphs').drop(columns='index')
batting_pca_cluster.to_csv('data/batting_pca_cluster.csv')

# creating batting_stats dataset
# similarityDF.head()
player_small['name'] = player_small['name_first'] + ' ' + player_small['name_last']

batting_stats = similarityDF.merge(player_small[['key_fangraphs', 'name']]
                    , left_on='source_key_fangraphs'
                    , right_on='key_fangraphs')
batting_stats = batting_stats.rename(columns={'name':'source_name'})
batting_stats.drop(columns='key_fangraphs', inplace=True)
batting_stats = batting_stats.merge(player_small[['key_fangraphs', 'name', 'mlb_id']]
                    , left_on='target_key_fangraphs'
                    , right_on='key_fangraphs')
batting_stats = batting_stats.rename(columns={'name':'target_name'})
batting_stats.drop(columns='key_fangraphs', inplace=True)

# statsDF = df.drop(columns='season')
batting_stats = batting_stats.merge(df
                    , left_on=['target_key_fangraphs', 'season']
                    , right_on=['key_fangraphs', 'season'])

batting_stats.to_csv('data/batting_stats.csv')



