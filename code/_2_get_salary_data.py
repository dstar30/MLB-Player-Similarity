import pandas as pd
import requests
from bs4 import BeautifulSoup
from datetime import datetime
import os

salaries = pd.DataFrame()

# loop through years
current_year = datetime.now().year
for i in range(current_year-9, current_year+1):
    print(i)

    # make request to USA Today page
    url = 'https://www.usatoday.com/sports/mlb/salaries/{}/player/all/'.format(i)
    page = requests.get(url)

    # error handling
    if page.status_code != 200:
        print('no page found for {}'.format(i))
        next

    # parse html with bs4
    soup = BeautifulSoup(page.content, 'html.parser')

    # find table
    table = soup.find('table')
    table_body = table.find('tbody')
    rows = table_body.find_all('tr')

    data = []
    for row in rows:
        cols = row.find_all('td')
        cols = [ele.text.strip() for ele in cols]
        data.append([ele for ele in cols if ele]) # Get rid of empty values

    # convert to dataframe and add year column
    results = pd.DataFrame.from_records(data)
    results['season'] = i

    # append to salaries table
    salaries = salaries.append(results)


# rename columns
columns={0: 'NA', 
            1: 'name', 
            2:'team', 
            3:'primary_position_txt', 
            4: 'salary', 
            5: 'contract',
            6: 'total_value',
            7: 'avg_annual_value'}

salaries = salaries.rename(columns=columns)
salaries.head()


# write to csv
if os.getcwd()[-4:] == 'code':
    next
else:
    os.chdir(os.getcwd() + '\\' + 'code')
try:
    os.makedirs("data")
except FileExistsError:
    # directory already exists
    pass

salaries.to_csv('data/salaries.csv')