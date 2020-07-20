import pandas as pd
import sqlalchemy
from sqlalchemy.types import Integer, Text, String, DateTime, Float, Numeric
from sqlalchemy import event
import yaml
import numpy as np
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.metrics.pairwise import euclidean_distances, manhattan_distances, cosine_similarity
import matplotlib.pyplot as plt
import seaborn as sns

# load credentials
conf = yaml.safe_load(open('./conf/application.yml'))
uid = conf['dbWrite']['uid']
pwd = conf['dbWrite']['pwd']

# connect to SQL Server
conn_str = "mssql+pyodbc://{uid}:{pwd}@team63sqlserver.cjfujwbtm3vk.us-east-1.rds.amazonaws.com,\
1433/baseball?driver=SQL+Server+Native+Client+11.0".format(uid=uid, pwd=pwd)
engine = sqlalchemy.create_engine(conn_str, echo=False)

# query and view the table from SQL
df = pd.read_sql('select * from baseball.dbo.vw_batting_stats_by_year', engine)
df.head()

# query salaries table
salaries_df = pd.read_sql('select * from baseball.dbo.salaries', engine);

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


# write results to table
# below code makes speeds up write process to sql server
@event.listens_for(engine, 'before_cursor_execute')
def receive_before_cursor_execute(conn, cursor, statement, params, context, executemany):
    print("FUNC call")
    if executemany:
        cursor.fast_executemany = True

resultsDF = resultsDF.drop(columns='index')
resultsDF.to_sql('batting_pca', 
                engine, 
                schema = 'dbo',
                if_exists='replace', 
                index=False,
                dtype = {'key_fangraphs': Integer,
                        'season': Integer,
                        'name': String(50),
                        'primary_position_txt': String(10),
                        'pc1': Float,
                        'pc2': Float,
                        'cluster': Integer})


# write similarity scores to table
similarityDF.to_sql('batting_similarity',
                    engine,
                    schema = 'dbo',
                    if_exists = 'replace',
                    index = False,
                    dtype = {'season': Integer,
                            'source_key_fangraphs': Integer,
                            'target_key_fangraphs': Integer,
                            'similarity_measure': String(50),
                            'similarity_value': Float,
                            'rank': Integer})

# visualize results

# vizDF = resultsDF.loc[(resultsDF['season'] == 2019) & (resultsDF['primary_position_txt'] == '1B')]

# ax = sns.lmplot(x="pc1", y="pc2", data=vizDF, height = 10, aspect = 2, fit_reg=False)

# def label_point(x, y, val, ax):
#     a = pd.concat({'x': x, 'y': y, 'val': val}, axis=1)
#     for i, point in a.iterrows():
#         ax.text(point['x']+.02, point['y'], str(point['val']))

# label_point(vizDF.pc1, vizDF.pc2, vizDF.name, plt.gca()) 





