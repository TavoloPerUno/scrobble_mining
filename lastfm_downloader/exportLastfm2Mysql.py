#!/usr/bin/env python2
#-*- coding: utf-8 -*-

#######################################################################
# This script imports your Last.fm listening history                  #
# inside a MySQL database.                                            #
#                                                                     #
# The original script has been developed by Matthew Lewis:            #
# http://mplewis.com/files/lastfm-scraper.html                        #
# It was coded to do a one-time import in a SQLite database.          #
# Copyright (c) 2014+2015, Matthew Lewis                              #
#                                                                     #
# I have changed it in the following ways:                            #
# - MySQL with a normalised database                                  #
# - import the missing tracks by comparing Last.fm number of tracks   #
#    against the database                                             #
# - getting rid of the "nowplaying" track if found                    #
# - reading user logins, passwords from .netrc                        #
# - insert the tracks in order of play                                #
#                                                                     #
# Copyright (c) 2015, Nicolas Meier                                   #
#######################################################################

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


if len(sys.argv) != 2:
    raise netrc.NetrcParseError('Missing Last.fm username.')

# Call the script with your Last.fm username.
user = sys.argv[1]

def retrieve_from_netrc(machine):
    login = netrc.netrc().authenticators(machine)
    if not login:
        raise netrc.NetrcParseError('No authenticators for %s' % machine)
    return login

# Get the Last.fm API key

api_key = '97a866cdf5a8d69617c37d1bb150da4f'
login = 'manorathan'
shared_secret = '30da808c1a5319d493566fe167e1d1f8'

# These are the API parameters for our scraping requests.
per_page = 200
api_url = 'http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=%s&api_key=%s&format=json&page=%s&limit=%s'
track_api_url = 'http://ws.audioscrobbler.com/2.0/?method=track.getinfo&api_key=%s&format=json&artist=%s&track=%s&autocorrect=1'
track_tags_api_url = 'http://ws.audioscrobbler.com/2.0/?method=track.gettoptags&api_key=%s&format=json&artist=%s&track=%s&autocorrect=1'

def recent_tracks(user, api_key, page, limit):
    """Get the most recent tracks from `user` using `api_key`. Start at page `page` and limit results to `limit`."""
    return requests.get(api_url % (user, api_key, page, limit)).json()

def track_info(api_key, artist, track):
    """Get track info using `api_key`."""
    r = requests.get(track_api_url % (api_key,
                                      urllib.parse.quote(artist.encode('utf8')),
                                      urllib.parse.quote(track.rstrip().encode('utf8'))))

    tags = requests.get(track_tags_api_url % (api_key,
                                      urllib.parse.quote(artist.encode('utf8')),
                                      urllib.parse.quote(track.rstrip().encode('utf8'))))


    return r.json(), tags.json()

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

def process_track(track, tags = dict()):
    """Removes `image` keys from track data. Replaces empty strings for values with None."""
    if 'image' in track:
        del track['image']
    flattened_track = flatten(track)
    for key, val in flattened_track.items():
        if val == '':
            flattened_track[key] = None


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
                if tag['name'].strip() != '':
                    tag_id = check_tag_in_db(tag['name'].strip()[0:255])
                    if tag_id is None:
                        try:
                            cursor.execute("INSERT INTO tag (tag_name, tag_url) VALUES (%s, %s)", (tag['name'].strip()[0:255], tag['url'][0:255]))
                            tag_id = check_tag_in_db(tag['name'])
                        except Exception as ex:
                            print(ex)
                            tag_id = check_tag_in_db(tag['name'].strip()[0:255])

                    final_tag = tag
                    final_tag['id'] = tag_id
                    final_tags['toptags_tag'].append(final_tag)

    return flattened_track, final_tags

def retrieve_total_plays_from_db():
    """Get total plays from the database."""
    cursor = mysql.cursor()
    cursor.execute('select count(*) from play where username ="' + user + '"' )
    return cursor.fetchone()[0]
    # result = mysql.use_result()
    # total_tracks_db = result.fetch_row()[0][0]
    # return total_tracks_db

def check_track_in_db(track_name, artist_name, album_name):
    cursor = mysql.cursor()
    cursor.execute("select check_track_in_db(%s, %s, %s)", (track_name, artist_name, album_name))
    return cursor.fetchone()[0]

def check_tag_in_db(tag_name):
    cursor = mysql.cursor()
    cursor.execute("select check_tag_in_db(%s)", (tag_name))
    return cursor.fetchone()[0]

# We need to get the first page so we can find out how many total pages there are in our listening history.
resp = recent_tracks(user, api_key, 1, 200)
total_pages = int(resp['recenttracks']['@attr']['totalPages'])
total_plays_in_lastfm = int(resp['recenttracks']['@attr']['total'])

# Get the MySQL connection data.

mysql = pymysql.connect(host="35.224.242.55", port=3306, user='root',passwd='root',db='lastfm', charset='utf8')
mysql_cursor = mysql.cursor()

total_plays_in_db = retrieve_total_plays_from_db()

# Compute the number of pages to get to be up-to-date.
total_pages = int(math.ceil((float(total_plays_in_lastfm) - float(total_plays_in_db)) / per_page));

if total_pages == 0:
    print('Nothing to update!')
    sys.exit(1)

all_pages = []
for page_num in range(total_pages, 0, -1):
    print('Page', page_num, 'of', total_pages)
    page = recent_tracks(user, api_key, page_num, 200)
    all_pages.append(page)

# Iterate through all pages
num_pages = len(all_pages)
for page_num, page in enumerate(all_pages):
    print('Page', page_num + 1, 'of', num_pages)

    tracks = page['recenttracks']['track']

    ## Remove the "nowplaying" track if found.
    if tracks[0].get('@attr'):
        if tracks[0]['@attr']['nowplaying'] == 'true':
            tracks.pop(0)

    ## Get only the missing tracks.
    if page_num == 0:
        tracks = tracks[0: (total_plays_in_lastfm - total_plays_in_db) % per_page]

    # On each page, iterate through all tracks
    num_tracks = len(tracks)
    for track_num, track in enumerate(reversed(tracks)):
        print('Track', track_num + 1, 'of', num_tracks)

        # Process each track and insert it into the `tracks` table
        transformed_track, transformed_tags = process_track(track)

        artist_name = transformed_track['artist_text']
        album_name = transformed_track['album_text']
        track_name = transformed_track['name']

        if not check_track_in_db(track_name, artist_name, album_name):
            info, tags = track_info(api_key, artist_name, track_name)

            info, transformed_tags = process_track(info, tags)

        # Cut artist name if too long.
        if len(artist_name) > 512:
            artist_name = artist_name[:512]

        # Cut track name if too long.
        if len(track_name) > 512:
            track_name = track_name[:512]

        # Call procedure to insert current play and track, artist, album if needed.
        try:

            track_id = 0;
            mysql_cursor.callproc("insert_play",
                        (user,
                         track_name,
                         transformed_track['mbid'],
                         transformed_track['url'],
                         transformed_track['date_uts'],
                         artist_name,
                         transformed_track['artist_mbid'],
                         album_name,
                         transformed_track['album_mbid'],
                         track_id))

            mysql_cursor.execute('SELECT @_insert_play_9;')
            track_id = mysql_cursor.fetchone()[0]

            if len(transformed_tags['toptags_tag']) > 0:

                values = [(track_id, tag['id'], tag['count']) for tag in transformed_tags['toptags_tag']]
                mysql_cursor.executemany("insert into track_tag (track_db_id, tag_id, count) values (%s, %s, %s)",
                             values )

        except Exception as ex:
            print(track_name, ', ', artist_name)
            print(ex)
            sys.exit(1)

# Display number of plays in database.
print('Done!', retrieve_total_plays_from_db(), 'rows in table `play.')
