import sys
import requests
import collections
import math
import netrc
import pymysql
import re
import urllib
import urllib.parse
import pylast
import pandas as pd

api_key = '97a866cdf5a8d69617c37d1bb150da4f'
login = 'manorathan'
shared_secret = '30da808c1a5319d493566fe167e1d1f8'

# These are the API parameters for our scraping requests.
api_url = 'http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=%s&api_key=%s&format=json&page=%s&limit=%s'
track_api_url = 'http://ws.audioscrobbler.com/2.0/?method=track.getinfo&api_key=%s&format=json&artist=%s&track=%s&autocorrect=1'
track_tags_api_url = 'http://ws.audioscrobbler.com/2.0/?method=track.gettoptags&api_key=%s&format=json&artist=%s&track=%s&autocorrect=1'

def flatten(d, parent_key=''):
    """From http://stackoverflow.com/a/6027615/254187. Modified to strip # symbols from dict keys."""
    items = []
    for k, v in d.items():
        new_key = parent_key + '_' + k if parent_key else k
        if isinstance(v, collections.MutableMapping):
            items.extend(flatten(v, new_key).items())
        else:
            new_key = new_key.replace('#', '')  # Strip pound symbols from column names
            items.append((new_key, v))
    return dict(items)

def check_tag_in_db(tag_name):
    cursor = mysql.cursor()
    cursor.execute("select check_tag_in_db(%s)", (tag_name))
    return cursor.fetchone()[0]

def tags_info(api_key, artist, track):
    """Get track info using `api_key`."""

    tags = requests.get(track_tags_api_url % (api_key,
                                      urllib.parse.quote(artist.encode('utf8')),
                                      urllib.parse.quote(track.rstrip().encode('utf8'))))


    return tags.json()


def process_tags(tags):
    """Removes `image` keys from track data. Replaces empty strings for values with None."""
    if 'image' in tags:
        del tags['image']
    flattened_tags = flatten(tags)
    for key, val in flattened_tags.items():
        if val == '':
            flattened_tags[key] = None

    final_tags = {'toptags_tag': []}

    if bool(flattened_tags):
        if 'toptags_tag' in flattened_tags:
            cursor = mysql.cursor()
            for tag in flattened_tags['toptags_tag']:
                if tag['name'].strip() != '' and 'Axwell' not in  tag['name'].strip():
                    tag_id = check_tag_in_db(tag['name'].strip()[0:255])
                    if tag_id is None:

                        cursor.execute("INSERT INTO tag (tag_name, tag_url) VALUES (%s, %s)", (tag['name'].strip()[0:255], tag['url'][0:255]))
                        tag_id = check_tag_in_db(tag['name'].strip()[0:255])

                    final_tag = tag
                    final_tag['id'] = tag_id
                    final_tags['toptags_tag'].append(final_tag)
    if len(final_tags['toptags_tag']) < 1:
        final_tags['toptags_tag'].append({'name' : 'N.A',
                                          'url' : 'N.A.',
                                          'count': 0,
                                          'id':19225})
    return final_tags

mysql = pymysql.connect(host="35.224.242.55", port=3306, user='root',passwd='root',db='lastfm', charset='utf8')
mysql_cursor = mysql.cursor()

df_track = pd.read_sql("SELECT * FROM track where track_db_id not in (select track_db_id from track_tag)", mysql)

for idx, row in df_track.iterrows():
    print("Processing %s of %s" % (str(idx), str(df_track.shape[0])))
    df_artist = pd.read_sql("SELECT * FROM artist where artist_db_id = " + str(row['artist_db_id']), mysql)

    tags = tags_info(api_key, df_artist.loc[0,'artist_name'], row['track_name'])

    tags = process_tags(tags)
    if len(tags['toptags_tag']) > 0:
        values = [(row['track_db_id'], tag['id'], tag['count']) for tag in tags['toptags_tag']]
        mysql_cursor.executemany("insert into track_tag (track_db_id, tag_id, count) values (%s, %s, %s)",
                                 values)

        mysql.commit()