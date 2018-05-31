#import libraries
import pymongo
from pymongo import MongoClient
import pandas as pd
import pandas as pd
import numpy as np
import pymysql

mysql = pymysql.connect(host="35.224.242.55", port=3306, user='root',passwd='root',db='millionsong', charset='utf8')
mysql_cursor = mysql.cursor()

#connect to local database server
client = MongoClient()

#switch to test DB
db = client.lastfm

df_artist = pd.DataFrame(columns=['id', 'name', 'catalog', 'catalog_id'] )
df_track = pd.DataFrame(columns=['song_id', 'artist_id', 'title', 'track_id', 'catalog', 'catalog_id', 'album_name', 'release_id'] )

lst_df_track = []
lst_df_artist = []


def response_to_pandas(cursor):
    for idx, document in enumerate(cursor):
        #         for track in document['response']['songs'][0]['tracks']:
        #             print(track)
        if 'response' in document and 'songs' in document['response'] and len(document['response']['songs']) > 0:
            lst_df_track.append(pd.DataFrame([{'song_id': document['response']['songs'][0]['id'],
                                               'artist_id': document['response']['songs'][0]['artist_id'],
                                               'title': document['response']['songs'][0]['title'],
                                               'track_id': track['id'],
                                               'catalog': track['catalog'],
                                               'catalog_id': track['foreign_id'].split(track['catalog'] + ':track:', 1)[
                                                   1],
                                               'album_name': track['album_name'] if 'album_name' in track else None,
                                               'release_id': track['foreign_release_id'].split(track['catalog'] + (
                                               ':release:' if track['catalog'] != 'spotify' else ':album:'), 1)[
                                                   1] if 'foreign_release_id' in track else None,

                                               } for track in document['response']['songs'][0]['tracks']]))

        if 'response' in document and 'songs' in document['response'] and len(
                document['response']['songs']) > 0 and 'artist_foreign_ids' in document['response']['songs'][0] and len(
                document['response']['songs'][0]['artist_foreign_ids']) > 0:
            lst_df_artist.append(pd.DataFrame([{'id': document['response']['songs'][0]['artist_id'],
                                                'name': document['response']['songs'][0]['artist_name'],
                                                'catalog': artist['catalog'],
                                                'catalog_id':
                                                    artist['foreign_id'].split(artist['catalog'] + ':artist:', 1)[1]
                                                } for artist in
                                               document['response']['songs'][0]['artist_foreign_ids']]))

cursor = db.echnonest_response.find()
response_to_pandas(cursor)

df_artist = pd.concat(lst_df_artist)
df_track = pd.concat(lst_df_track)

df_track = df_track.replace(np.nan, "NULL", regex=True)

values = [(row['song_id'], row['artist_id'], row['title'], row['track_id'], row['catalog'], row['catalog_id'], row['album_name'], row['release_id']) for idx, row in df_track.iterrows()]

mysql_cursor.executemany("insert into other_media_tracks (song_msd_id, artist_msd_id, title, track_msd_id, catalog, catalog_id, album_name, release_id) values (%s, %s, %s, %s, %s, %s, %s, %s)", values )

mysql.commit()

values = [(row['id'], row['name'], row['catalog'], row['catalog_id']) for idx, row in df_artist.iterrows()]
mysql_cursor.executemany("insert into other_media_artists ('msd_id', 'name', 'catalog', 'catalog_id') values (%s, %s, %s, %s)", values )

mysql.commit()