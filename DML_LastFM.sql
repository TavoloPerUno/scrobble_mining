USE lastfm_snowflake;

INSERT INTO years (number)
SELECT YEAR(curdate()) - n from numbers limit 10;

INSERT INTO lastfm_snowflake.dim_artist (    
    artist_db_id,
    artist_name,
    artist_mbid,
    creation_date,
    update_date)
(SELECT artist_db_id,
    artist_name,
    artist_mbid,
    creation_date,
    update_date
FROM
    lastfm.artist);


INSERT INTO lastfm_snowflake.dim_album (    
	album_db_id,
    artist_db_id,
    album_name,
    album_mbid,
    creation_date,
    update_date)
(SELECT album_db_id,
    artist_db_id,
    album_name,
    album_mbid,
    creation_date,
    update_date
FROM
    lastfm.album);


INSERT INTO lastfm_snowflake.dim_track (    
	track_db_id,
    artist_db_id,
    album_db_id,
    track_name,
    track_duration,
    track_url,
    track_mbid,
    creation_date,
    update_date)
(SELECT 
	track_db_id,
    artist_db_id,
    album_db_id,
    track_name,
    track_duration,
    track_url,
    track_mbid,
    creation_date,
    update_date
FROM
    lastfm.track);
    

INSERT INTO lastfm_snowflake.dim_play (    
	play_db_id,
    track_db_id,
    username,
    play_date_uts,
    play_date,
    creation_date,
    update_date)
(SELECT 
	play_db_id,
    track_db_id,
    username,
    play_date_uts,
    play_date,
    creation_date,
    update_date
FROM
    lastfm.play);


INSERT INTO lastfm_snowflake.dim_tag(    
	tag_id,
    tag_name,
    tag_url)
(SELECT 
	tag_id,
    tag_name,
    tag_url
FROM
    lastfm.tag);

INSERT INTO lastfm_snowflake.dim_track_tag(    
	track_tag_id,
    track_db_id,
    tag_id,
    count)
(SELECT 
	track_tag_id,
    track_db_id,
    tag_id,
    count
FROM
    lastfm.track_tag);

#SET SQL_SAFE_UPDATES = 0;

INSERT INTO lastfm_snowflake.fact_user(    
	username,
    year)
(select distinct 
	username, 
    years.number
 from dim_play
 cross join years);

UPDATE lastfm_snowflake.fact_user
SET listens_since_joining =  (SELECT count(*)
											  FROM dim_play
                                              WHERE username = fact_user.username and year(play_date) <= fact_user.year);
                                              
UPDATE lastfm_snowflake.fact_user
SET listens_current_year =  (SELECT count(*)
											  FROM dim_play
                                              WHERE username = fact_user.username and year(play_date) = fact_user.year);
                                              
UPDATE lastfm_snowflake.fact_user
SET listens_last_year =  (SELECT count(*)
											  FROM dim_play
                                              WHERE username = fact_user.username and year(play_date) + 1 = fact_user.year);                                              
        
UPDATE lastfm_snowflake.fact_user
SET top_song_1_current_year =  (		Select track_db_id
															FROM dim_play
															WHERE  username = fact_user.username and year(play_date) = fact_user.year
                                                            GROUP BY track_db_id
															ORDER BY count(track_db_id) desc
															LIMIT 0,1);        
                                                                  
UPDATE lastfm_snowflake.fact_user
SET top_song_2_current_year =  (		Select track_db_id
															FROM dim_play
															WHERE  username = fact_user.username and year(play_date) = fact_user.year
                                                            GROUP BY track_db_id
															ORDER BY count(track_db_id) desc
															LIMIT 1, 1);   

UPDATE lastfm_snowflake.fact_user
SET top_song_3_current_year =  (		Select track_db_id
															FROM dim_play
															WHERE  username = fact_user.username and year(play_date) = fact_user.year
                                                            GROUP BY track_db_id
															ORDER BY count(track_db_id) desc
															LIMIT 2, 1); 

UPDATE lastfm_snowflake.fact_user
SET top_song_1_last_year =  (		 Select track_db_id
															FROM dim_play
															WHERE  username = fact_user.username and year(play_date) + 1 = fact_user.year
                                                            GROUP BY track_db_id
															ORDER BY count(track_db_id) desc
															LIMIT 0,1);        
                                                                  
UPDATE lastfm_snowflake.fact_user
SET top_song_2_last_year =  (		Select track_db_id
															FROM dim_play
															WHERE  username = fact_user.username and year(play_date) + 1 = fact_user.year
                                                            GROUP BY track_db_id
															ORDER BY count(track_db_id) desc
															LIMIT 1, 1);   

UPDATE lastfm_snowflake.fact_user
SET top_song_3_last_year =  (		Select track_db_id
															FROM dim_play
															WHERE  username = fact_user.username and year(play_date) + 1 = fact_user.year
                                                            GROUP BY track_db_id
															ORDER BY count(track_db_id) desc
															LIMIT 2, 1); 
                                            
UPDATE lastfm_snowflake.fact_user
SET top_artist_1_current_year =  (		Select artist_db_id
															FROM dim_play
                                                            LEFT JOIN dim_track
                                                            ON dim_play.track_db_id = dim_track.track_db_id
															WHERE  username = fact_user.username and year(play_date) = fact_user.year
                                                            GROUP BY artist_db_id
															ORDER BY count(artist_db_id) desc
															LIMIT 0, 1); 

UPDATE lastfm_snowflake.fact_user
SET top_artist_2_current_year =  (		Select artist_db_id
															FROM dim_play
                                                            LEFT JOIN dim_track
                                                            ON dim_play.track_db_id = dim_track.track_db_id
															WHERE  username = fact_user.username and year(play_date) = fact_user.year
                                                            GROUP BY artist_db_id
															ORDER BY count(artist_db_id) desc
															LIMIT 1, 1);      
                                                            
UPDATE lastfm_snowflake.fact_user
SET top_artist_3_current_year =  (		Select artist_db_id
															FROM dim_play
                                                            LEFT JOIN dim_track
                                                            ON dim_play.track_db_id = dim_track.track_db_id
															WHERE  username = fact_user.username and year(play_date) = fact_user.year
                                                            GROUP BY artist_db_id
															ORDER BY count(artist_db_id) desc
															LIMIT 2, 1);       

UPDATE lastfm_snowflake.fact_user
SET top_artist_1_last_year =  (		Select artist_db_id
															FROM dim_play
                                                            LEFT JOIN dim_track
                                                            ON dim_play.track_db_id = dim_track.track_db_id
															WHERE  username = fact_user.username and year(play_date) + 1 = fact_user.year
                                                            GROUP BY artist_db_id
															ORDER BY count(artist_db_id) desc
															LIMIT 0, 1); 

UPDATE lastfm_snowflake.fact_user
SET top_artist_2_last_year =  (		Select artist_db_id
															FROM dim_play
                                                            LEFT JOIN dim_track
                                                            ON dim_play.track_db_id = dim_track.track_db_id
															WHERE  username = fact_user.username and year(play_date) + 1 = fact_user.year
                                                            GROUP BY artist_db_id
															ORDER BY count(artist_db_id) desc
															LIMIT 1, 1);      
                                                            
UPDATE lastfm_snowflake.fact_user
SET top_artist_3_last_year =  (		Select artist_db_id
															FROM dim_play
                                                            LEFT JOIN dim_track
                                                            ON dim_play.track_db_id = dim_track.track_db_id
															WHERE  username = fact_user.username and year(play_date) + 1 = fact_user.year
                                                            GROUP BY artist_db_id
															ORDER BY count(artist_db_id) desc
															LIMIT 2, 1);  
                                                            
UPDATE lastfm_snowflake.fact_user
SET top_genre_1_current_year =  ( Select tag_id
															FROM dim_play
                                                            LEFT JOIN dim_track_tag
                                                            ON dim_play.track_db_id = dim_track_tag.track_db_id
															WHERE  username = fact_user.username and year(play_date) = fact_user.year
                                                            GROUP BY tag_id
															ORDER BY count(tag_id) desc
															LIMIT 0, 1); 
 
UPDATE lastfm_snowflake.fact_user
SET top_genre_2_current_year =  ( Select tag_id
															FROM dim_play
                                                            LEFT JOIN dim_track_tag
                                                            ON dim_play.track_db_id = dim_track_tag.track_db_id
															WHERE  username = fact_user.username and year(play_date) = fact_user.year
                                                            GROUP BY tag_id
															ORDER BY count(tag_id) desc
															LIMIT 1, 1); 
                                                            
UPDATE lastfm_snowflake.fact_user
SET top_genre_3_current_year =  ( Select tag_id
															FROM dim_play
                                                            LEFT JOIN dim_track_tag
                                                            ON dim_play.track_db_id = dim_track_tag.track_db_id
															WHERE  username = fact_user.username and year(play_date) = fact_user.year
                                                            GROUP BY tag_id
															ORDER BY count(tag_id) desc
															LIMIT 2, 1); 
                                                            
UPDATE lastfm_snowflake.fact_user
SET top_genre_1_last_year =  ( Select tag_id
															FROM dim_play
                                                            LEFT JOIN dim_track_tag
                                                            ON dim_play.track_db_id = dim_track_tag.track_db_id
															WHERE  username = fact_user.username and year(play_date) + 1 = fact_user.year
                                                            GROUP BY tag_id
															ORDER BY count(tag_id) desc
															LIMIT 0, 1); 
 
UPDATE lastfm_snowflake.fact_user
SET top_genre_2_last_year =  ( Select tag_id
															FROM dim_play
                                                            LEFT JOIN dim_track_tag
                                                            ON dim_play.track_db_id = dim_track_tag.track_db_id
															WHERE  username = fact_user.username and year(play_date) + 1 = fact_user.year
                                                            GROUP BY tag_id
															ORDER BY count(tag_id) desc
															LIMIT 1, 1); 
                                                            
UPDATE lastfm_snowflake.fact_user
SET top_genre_3_last_year =  ( Select tag_id
															FROM dim_play
                                                            LEFT JOIN dim_track_tag
                                                            ON dim_play.track_db_id = dim_track_tag.track_db_id
															WHERE  username = fact_user.username and year(play_date) + 1 = fact_user.year
                                                            GROUP BY tag_id
															ORDER BY count(tag_id) desc
															LIMIT 2, 1);

UPDATE lastfm_snowflake.fact_user
SET top_album_1_current_year =  ( Select album_db_id
															FROM dim_play
                                                            LEFT JOIN dim_track
                                                            ON dim_play.track_db_id = dim_track.track_db_id
															WHERE  username = fact_user.username and year(play_date) = fact_user.year
                                                            GROUP BY album_db_id
															ORDER BY count(album_db_id) desc
															LIMIT 0, 1); 
 
UPDATE lastfm_snowflake.fact_user
SET top_album_2_current_year =  ( Select album_db_id
															FROM dim_play
                                                            LEFT JOIN dim_track
                                                            ON dim_play.track_db_id = dim_track.track_db_id
															WHERE  username = fact_user.username and year(play_date) = fact_user.year
                                                            GROUP BY album_db_id
															ORDER BY count(album_db_id) desc
															LIMIT 1, 1); 
                                                            
UPDATE lastfm_snowflake.fact_user
SET top_album_3_current_year =  ( Select album_db_id
															FROM dim_play
                                                            LEFT JOIN dim_track
                                                            ON dim_play.track_db_id = dim_track.track_db_id
															WHERE  username = fact_user.username and year(play_date) = fact_user.year
                                                            GROUP BY album_db_id
															ORDER BY count(album_db_id) desc
															LIMIT 2, 1); 
                                                            
UPDATE lastfm_snowflake.fact_user
SET top_album_1_last_year =  ( Select album_db_id
															FROM dim_play
                                                            LEFT JOIN dim_track
                                                            ON dim_play.track_db_id = dim_track.track_db_id
															WHERE  username = fact_user.username and year(play_date) + 1= fact_user.year
                                                            GROUP BY album_db_id
															ORDER BY count(album_db_id) desc
															LIMIT 0, 1); 
 
UPDATE lastfm_snowflake.fact_user
SET top_album_2_last_year =  ( Select album_db_id
															FROM dim_play
                                                            LEFT JOIN dim_track
                                                            ON dim_play.track_db_id = dim_track.track_db_id
															WHERE  username = fact_user.username and year(play_date) + 1 = fact_user.year
                                                            GROUP BY album_db_id
															ORDER BY count(album_db_id) desc
															LIMIT 1, 1); 
                                                            
UPDATE lastfm_snowflake.fact_user
SET top_album_3_last_year =  ( Select album_db_id
															FROM dim_play
                                                            LEFT JOIN dim_track
                                                            ON dim_play.track_db_id = dim_track.track_db_id
															WHERE  username = fact_user.username and year(play_date) + 1= fact_user.year
                                                            GROUP BY album_db_id
															ORDER BY count(album_db_id) desc
															LIMIT 2, 1);           
                                                            