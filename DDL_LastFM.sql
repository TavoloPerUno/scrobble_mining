SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';


CREATE SCHEMA IF NOT EXISTS `lastfm_snowflake` DEFAULT CHARACTER SET latin1 ;
USE `lastfm_snowflake` ;

CREATE TABLE IF NOT EXISTS `lastfm_snowflake`.`dim_album` (
  `album_db_id` int(11) NOT NULL AUTO_INCREMENT,
  `artist_db_id` int(11) NOT NULL,
  `album_name` varchar(256) DEFAULT NULL,
  `album_mbid` varchar(36) DEFAULT NULL,
  `creation_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`album_db_id`),
  UNIQUE KEY `idx_album_artist` (`album_name`,`artist_db_id`) USING BTREE,
  KEY `idx_album_name` (`album_name`) USING BTREE,
  KEY `fk_artist_db_id` (`artist_db_id`),
  CONSTRAINT `album_ibfk_1` FOREIGN KEY (`artist_db_id`) REFERENCES `artist` (`artist_db_id`)
) ENGINE=InnoDB AUTO_INCREMENT=18922 DEFAULT CHARSET=utf8 ROW_FORMAT=COMPRESSED;


CREATE TABLE IF NOT EXISTS `lastfm_snowflake`.`dim_artist` (
  `artist_db_id` int(11) NOT NULL AUTO_INCREMENT,
  `artist_name` varchar(512) NOT NULL,
  `artist_mbid` varchar(36) DEFAULT NULL,
  `creation_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`artist_db_id`),
  KEY `idx_artist_name` (`artist_name`(255)) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=11814 DEFAULT CHARSET=utf8 ROW_FORMAT=COMPRESSED;

CREATE TABLE IF NOT EXISTS `lastfm_snowflake`.`dim_play` (
  `play_db_id` int(11) NOT NULL AUTO_INCREMENT,
  `track_db_id` int(11) NOT NULL DEFAULT '0',
  `username` varchar(40) NOT NULL,
  `play_date_uts` varchar(10) NOT NULL,
  `play_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `creation_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`play_db_id`),
  KEY `idx_play_date` (`play_date`) USING BTREE,
  KEY `fk_track_db_id` (`track_db_id`),
  CONSTRAINT `play_ibfk_1` FOREIGN KEY (`track_db_id`) REFERENCES `track` (`track_db_id`)
) ENGINE=InnoDB AUTO_INCREMENT=135599 DEFAULT CHARSET=utf8 ROW_FORMAT=COMPRESSED;

CREATE TABLE IF NOT EXISTS `lastfm_snowflake`.`dim_track` (
  `track_db_id` int(11) NOT NULL AUTO_INCREMENT,
  `artist_db_id` int(11) DEFAULT '0',
  `album_db_id` int(11) DEFAULT '0',
  `track_name` varchar(512) DEFAULT NULL,
  `track_duration` time DEFAULT NULL,
  `track_url` text,
  `track_mbid` varchar(36) DEFAULT NULL,
  `creation_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`track_db_id`),
  KEY `idx_track_name` (`track_name`) USING BTREE,
  KEY `idx_names` (`track_name`,`artist_db_id`,`album_db_id`) USING BTREE,
  KEY `fk_track_artist_db_id` (`artist_db_id`),
  KEY `fk_album_db_id` (`album_db_id`),
  CONSTRAINT `track_ibfk_1` FOREIGN KEY (`album_db_id`) REFERENCES `album` (`album_db_id`),
  CONSTRAINT `track_ibfk_2` FOREIGN KEY (`artist_db_id`) REFERENCES `artist` (`artist_db_id`)
) ENGINE=InnoDB AUTO_INCREMENT=44111 DEFAULT CHARSET=utf8 ROW_FORMAT=COMPRESSED;

CREATE TABLE IF NOT EXISTS `lastfm_snowflake`.`dim_various_artists` (
  `va_db_id` int(11) NOT NULL AUTO_INCREMENT,
  `va_album_name` varchar(512) NOT NULL,
  `va_artist_name` varchar(512) DEFAULT NULL,
  `creation_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`va_db_id`),
  UNIQUE KEY `idx_va_album_name` (`va_album_name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPRESSED;

CREATE TABLE `dim_tag` (
  `tag_id` int(11) NOT NULL AUTO_INCREMENT,
  `tag_name` varchar(255) NOT NULL,
  `tag_url` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`tag_id`),
  UNIQUE KEY `name_UNIQUE` (`tag_name`)
) ENGINE=InnoDB AUTO_INCREMENT=29558 DEFAULT CHARSET=utf8;

CREATE TABLE `dim_track_tag` (
  `track_tag_id` int(11) NOT NULL AUTO_INCREMENT,
  `track_db_id` int(11) NOT NULL,
  `tag_id` int(11) NOT NULL,
  `count` int(11) NOT NULL,
  PRIMARY KEY (`track_tag_id`),
  KEY `fk_track_tag_tag_id_idx` (`tag_id`),
  KEY `fk_track_tag_track_id_idx` (`track_db_id`),
  CONSTRAINT `fk_track_tag_tag_id` FOREIGN KEY (`tag_id`) REFERENCES `tag` (`tag_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_track_tag_track_id` FOREIGN KEY (`track_db_id`) REFERENCES `track` (`track_db_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=156465 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `lastfm_snowflake`.`year_lag` (
  `number` INT(11) NULL DEFAULT NULL)
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;

CREATE TABLE IF NOT EXISTS `lastfm_snowflake`.`years` (
  `number` INT(11) NULL DEFAULT NULL)
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;

use lastfm_snowflake;
CREATE TABLE numbers (n INT);
INSERT INTO numbers VALUES (0),(1),(2),(3),(4);
INSERT INTO numbers SELECT n+5 FROM numbers;
INSERT INTO numbers SELECT n+10 FROM numbers;
INSERT INTO numbers SELECT n+20 FROM numbers;
INSERT INTO numbers SELECT n+40 FROM numbers;

CREATE TABLE `years` (
  `number` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


 CREATE TABLE `fact_user` (
  `id` int(10) NOT NULL,
  `username` varchar(50) NOT NULL,
  `year` int(4) NOT NULL,
  `listens_since_joining` int(10) NOT NULL,
  `listens_current_year` int(10) NOT NULL,
  `listens_last_year` int(10) NOT NULL,
  `top_song_1_current_year` int(10) DEFAULT NULL,
  `top_song_2_current_year` int(10) DEFAULT NULL,
  `top_song_3_current_year` int(10) DEFAULT NULL,
  `top_song_1_last_year` int(10) DEFAULT NULL,
  `top_song_2_last_year` int(10) DEFAULT NULL,
  `top_song_3_last_year` int(10) DEFAULT NULL,
  `top_artist_1_current_year` int(10) DEFAULT NULL,
  `top_artist_2_current_year` int(10) DEFAULT NULL,
  `top_artist_3_current_year` int(10) DEFAULT NULL,
  `top_artist_1_last_year` int(10) DEFAULT NULL,
  `top_artist_2_last_year` int(10) DEFAULT NULL,
  `top_artist_3_last_year` int(10) DEFAULT NULL,
  `top_genre_1_current_year` int(10) DEFAULT NULL,
  `top_genre_2_current_year` int(10) DEFAULT NULL,
  `top_genre_3_current_year` int(10) DEFAULT NULL,
  `top_genre_1_last_year` int(10) DEFAULT NULL,
  `top_genre_2_last_year` int(10) DEFAULT NULL,
  `top_genre_3_last_year` int(10) DEFAULT NULL,
  `top_album_1_current_year` int(10) DEFAULT NULL,
  `top_album_2_current_year` int(10) DEFAULT NULL,
  `top_album_3_current_year` int(10) DEFAULT NULL,
  `top_album_1_last_year` int(10) DEFAULT NULL,
  `top_album_2_last_year` int(10) DEFAULT NULL,
  `top_album_3_last_year` int(10) DEFAULT NULL,
  PRIMARY KEY (`id`),
  
  UNIQUE KEY `username` (`username`),
  KEY `fk_top_artist_idx` (`top_artist_1_last_year`,`top_artist_2_last_year`,`top_artist_3_last_year`,`top_artist_1_current_year`,`top_artist_2_current_year`,`top_artist_3_current_year`),
  KEY `fk_top_album_idx` (`top_album_1_current_year`,`top_album_2_current_year`,`top_album_3_current_year`,`top_album_1_last_year`,`top_album_2_last_year`,`top_album_3_last_year`),
  KEY `fk_top_genre_idx` (`top_genre_1_current_year`,`top_genre_2_current_year`,`top_genre_3_current_year`,`top_genre_1_last_year`,`top_genre_2_last_year`,`top_genre_3_last_year`),
  KEY `fk_user_track_top_current_idx` (`top_song_2_current_year`),
  KEY `fk_user_track_top_current_3_idx` (`top_song_3_current_year`),
  KEY `fk_user_track_top_current_1_idx` (`top_song_1_current_year`),
  KEY `fk_user_track_top_last_1_idx` (`top_song_1_last_year`),
  KEY `fk_user_track_top_last_2_idx` (`top_song_2_last_year`),
  KEY `fk_user_track_top_last_3_idx` (`top_song_3_last_year`),
  KEY `fk_user_artist_current_1_idx` (`top_artist_1_current_year`),
  KEY `fk_user_artist_current_2_idx` (`top_artist_2_current_year`),
  KEY `fk_user_artist_current_3_idx` (`top_artist_3_current_year`),
  KEY `fk_user_artist_last_2_idx` (`top_artist_2_last_year`),
  KEY `fk_user_artist_last_3_idx` (`top_artist_3_last_year`),
  KEY `fk_user_album_current_2_idx` (`top_album_2_current_year`),
  KEY `fk_user_album_current_3_idx` (`top_album_3_current_year`),
  KEY `fk_user_album_last_1_idx` (`top_album_1_last_year`),
  KEY `fk_user_album_last_2_idx` (`top_album_2_last_year`),
  KEY `fk_user_album_last_3_idx` (`top_album_3_last_year`),
  KEY `fk_user_genre_current_2_idx` (`top_genre_2_current_year`),
  KEY `fk_user_genre_current_3_idx` (`top_genre_3_current_year`),
  KEY `fk_user_genre_last_1_idx` (`top_genre_1_last_year`),
  KEY `fk_user_genre_current_2_idx1` (`top_genre_2_last_year`),
  KEY `fk_user_genre_current_3_idx1` (`top_genre_3_last_year`),
  CONSTRAINT `fk_user_album_current_1` FOREIGN KEY (`top_album_1_current_year`) REFERENCES `dim_album` (`album_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_album_current_2` FOREIGN KEY (`top_album_2_current_year`) REFERENCES `dim_album` (`album_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_album_current_3` FOREIGN KEY (`top_album_3_current_year`) REFERENCES `dim_album` (`album_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_album_last_1` FOREIGN KEY (`top_album_1_last_year`) REFERENCES `dim_album` (`album_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_album_last_2` FOREIGN KEY (`top_album_2_last_year`) REFERENCES `dim_album` (`album_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_album_last_3` FOREIGN KEY (`top_album_3_last_year`) REFERENCES `dim_album` (`album_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_artist_current_1` FOREIGN KEY (`top_artist_1_current_year`) REFERENCES `dim_artist` (`artist_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_artist_current_2` FOREIGN KEY (`top_artist_2_current_year`) REFERENCES `dim_artist` (`artist_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_artist_current_3` FOREIGN KEY (`top_artist_3_current_year`) REFERENCES `dim_artist` (`artist_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_artist_last_1` FOREIGN KEY (`top_artist_1_last_year`) REFERENCES `dim_artist` (`artist_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_artist_last_2` FOREIGN KEY (`top_artist_2_last_year`) REFERENCES `dim_artist` (`artist_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_artist_last_3` FOREIGN KEY (`top_artist_3_last_year`) REFERENCES `dim_artist` (`artist_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_genre_current_1` FOREIGN KEY (`top_genre_1_current_year`) REFERENCES `dim_tag` (`tag_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_genre_current_2` FOREIGN KEY (`top_genre_2_current_year`) REFERENCES `dim_tag` (`tag_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_genre_current_3` FOREIGN KEY (`top_genre_3_current_year`) REFERENCES `dim_tag` (`tag_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_genre_last_1` FOREIGN KEY (`top_genre_1_last_year`) REFERENCES `dim_tag` (`tag_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_track_top_current_1` FOREIGN KEY (`top_song_1_current_year`) REFERENCES `dim_track` (`track_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_track_top_current_2` FOREIGN KEY (`top_song_2_current_year`) REFERENCES `dim_track` (`track_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_track_top_current_3` FOREIGN KEY (`top_song_3_current_year`) REFERENCES `dim_track` (`track_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_track_top_last_1` FOREIGN KEY (`top_song_1_last_year`) REFERENCES `dim_track` (`track_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_track_top_last_2` FOREIGN KEY (`top_song_2_last_year`) REFERENCES `dim_track` (`track_db_id`) ON DELETE SET NULL ON UPDATE SET NULL,
  CONSTRAINT `fk_user_track_top_last_3` FOREIGN KEY (`top_song_3_last_year`) REFERENCES `dim_track` (`track_db_id`) ON DELETE SET NULL ON UPDATE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1
;
    
SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;