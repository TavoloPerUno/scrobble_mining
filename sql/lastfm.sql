# Encoding: Unicode (UTF-8)

# Needed (+ ROW_FORMAT=COMPRESSED) on MariaDb to avoid this error:
# #1071 - Specified key was too long; max key length is 767 bytes

create database if not exists `lastfm`
  default character set utf8
  default collate utf8_general_ci;

use lastfm;

create table `artist` (
  `artist_db_id`  int(11)      not null auto_increment,
  `artist_name`   varchar(512) not null,
  `artist_mbid`   varchar(36)           default null,
  `creation_date` timestamp    null     default CURRENT_TIMESTAMP,
  `update_date`   timestamp    null     default CURRENT_TIMESTAMP,
  primary key (`artist_db_id`),
  key `idx_artist_name` (`artist_name`(255)) using btree
)
  engine = InnoDB
  default charset = utf8
  row_format = compressed
  ;


create table `album` (
  `album_db_id`   int(11) not null auto_increment,
  `artist_db_id`  int(11) not null,
  `album_name`    varchar(256)     default null,
  `album_mbid`    varchar(36)      default null,
  `creation_date` datetime         default CURRENT_TIMESTAMP,
  `update_date`   datetime         default CURRENT_TIMESTAMP,
  primary key (`album_db_id`),
  unique key `idx_album_artist` (`album_name`, `artist_db_id`) using btree,
  key `idx_album_name` (`album_name`) using btree,
  key `fk_artist_db_id` (`artist_db_id`),
  foreign key (`artist_db_id`) references `artist` (`artist_db_id`)
)
  engine = InnoDB
  default charset = utf8
  row_format = compressed;


create table `track` (
  `track_db_id`    int(11)   not null auto_increment,
  `artist_db_id`   int(11)            default '0',
  `album_db_id`    int(11)            default '0',
  `track_name`     varchar(512)       default null,
  `track_duration` time      null,
  `track_url`      text,
  `track_mbid`     varchar(36)        default null,
  `creation_date`  timestamp null     default CURRENT_TIMESTAMP,
  `update_date`    timestamp null     default CURRENT_TIMESTAMP,
  primary key (`track_db_id`),
  key `idx_track_name` (`track_name`) using btree,
  key `idx_names` (`track_name`, `artist_db_id`, `album_db_id`) using btree,
  key `fk_track_artist_db_id` (`artist_db_id`),
  key `fk_album_db_id` (`album_db_id`),
  foreign key (`album_db_id`) references `album` (`album_db_id`),
  foreign key (`artist_db_id`) references `artist` (`artist_db_id`)
)
  engine = InnoDB
  default charset = utf8
  row_format = compressed;


create table `play` (
  `play_db_id`    int(11)     not null auto_increment,
  `track_db_id`   int(11)     not null default '0',
  `username` varchar(40) not null,
  `play_date_uts` varchar(10) not null,
  `play_date`     datetime    not null default CURRENT_TIMESTAMP,
  `creation_date` timestamp   null     default CURRENT_TIMESTAMP,
  `update_date`   timestamp   null     default CURRENT_TIMESTAMP,
  primary key (`play_db_id`),
  key `idx_play_date` (`play_date`) using btree,
  key `fk_track_db_id` (`track_db_id`),
  foreign key (`track_db_id`) references `track` (`track_db_id`)
)
  engine = InnoDB
  default charset = utf8
  row_format = compressed;


create table `various_artists` (
  `va_db_id`       int(11)      not null auto_increment,
  `va_album_name`  varchar(512) not null,
  `va_artist_name` varchar(512)          default null,
  `creation_date`  timestamp    null     default CURRENT_TIMESTAMP,
  `update_date`    timestamp    null     default CURRENT_TIMESTAMP,
  primary key (`va_db_id`),
  unique key `idx_va_album_name` (`va_album_name`) using btree
)
  engine = InnoDB
  default charset = utf8
  row_format = compressed;

use lastfm;
CREATE TABLE `tag` (
  `tag_id` int(11) NOT NULL AUTO_INCREMENT,
  `tag_name` varchar(255) NOT NULL,
  `tag_url` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`tag_id`),
  UNIQUE KEY `name_UNIQUE` (`tag_name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

CREATE TABLE `track_tag` (
  `track_tag_id` int(11) NOT NULL AUTO_INCREMENT,
  `track_db_id` int(11) NOT NULL,
  `tag_id` int(11) NOT NULL,
  `count` int(11) NOT NULL,
  PRIMARY KEY (`track_tag_id`),
  KEY `fk_track_tag_tag_id_idx` (`tag_id`),
  KEY `fk_track_tag_track_id_idx` (`track_db_id`),
  CONSTRAINT `fk_track_tag_tag_id` FOREIGN KEY (`tag_id`) REFERENCES `tag` (`tag_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_track_tag_track_id` FOREIGN KEY (`track_db_id`) REFERENCES `track` (`track_db_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


create function lastfm.nb_days()
  returns integer deterministic no sql return @nb_days;

create function lastfm.for_year()
  returns integer deterministic no sql return @for_year;

create or replace view view_plays as
  select
    p.play_db_id,
    t.track_name,
    a.artist_name,
    b.album_name,
    p.play_date_uts,
    p.play_date,
    p.username
  from play p, artist a, track t
    left outer join album b on b.album_db_id = t.album_db_id
  where p.track_db_id = t.track_db_id
        and t.artist_db_id = a.artist_db_id
  order by p.play_db_id desc;

create or replace view view_play_count_by_month as
  select
    date_format(p.play_date, '%Y-%m') as month,
    count(p.play_db_id)               as count,
    p.username as username
  from play p
  group by p.username, month
  order by month;

create or replace view view_play_count_for_year as
  select
    count(`p`.`play_db_id`) as `count`,
    p.username as username
  from `lastfm`.`play` `p`
  where year(p.play_date) = for_year()
group by p.username;

create or replace view view_top_artists_for_last_n_days as
select
    `a`.`artist_name`       as `artist_name`,
    `p`.`username`       as `username`,
    count(`p`.`play_db_id`) as `play_count`
  from ((`lastfm`.`play` `p`
    join `lastfm`.`artist` `a`) join `lastfm`.`track` `t`)
  where ((`p`.`track_db_id` = `t`.`track_db_id`) and (`t`.`artist_db_id` = `a`.`artist_db_id`) and
         (((`nb_days`() is not null) and (`p`.`play_date` > (now() + interval -(`nb_days`()) day))) or
          isnull(`nb_days`())) and (not ((`a`.`artist_name` like 'VA %'))))
  group by `p`.`username`,  `a`.`artist_name`
  order by count(`p`.`play_db_id`) desc;

create view view_top_artists_for_year as
  select
    `a`.`artist_name`       as `artist_name`,
    `p`.`username`       as `username`,
    count(`p`.`play_db_id`) as `play_count`
  from ((`lastfm`.`play` `p`
    join `lastfm`.`artist` `a`) join `lastfm`.`track` `t`)
  where ((`p`.`track_db_id` = `t`.`track_db_id`) and (`t`.`artist_db_id` = `a`.`artist_db_id`) and
         (((year(`p`.`play_date`) = for_year()))) and (not ((`a`.`artist_name` like 'VA %'))))
  group by  `p`.`username`,  `a`.`artist_name`
  order by count(`p`.`play_db_id`) desc;

create or replace view view_top_albums_for_year as
  select
    `b`.`album_name`        as `album_name`,
    `p`.`username`       as `username`,
    `a`.`artist_name`       as `artist_name`,
    count(`p`.`play_db_id`) as `play_count`
  from ((`lastfm`.`play` `p`
    join `lastfm`.`artist` `a`) join
    (`lastfm`.`track` `t` left join `lastfm`.`album` `b` on ((`b`.`album_db_id` = `t`.`album_db_id`))))
  where ((`p`.`track_db_id` = `t`.`track_db_id`) and (`t`.`artist_db_id` = `a`.`artist_db_id`) and
         (((year(`p`.`play_date`) = for_year()))))
  group by  `p`.`username`,  `b`.`album_name`, `a`.`artist_name`
  order by count(`p`.`play_db_id`) desc;

create or replace view view_top_albums_for_last_n_days as
select
    `b`.`album_name`        as `album_name`,
    `p`.`username`       as `username`,
    `a`.`artist_name`       as `artist_name`,
    count(`p`.`play_db_id`) as `play_count`
  from ((`lastfm`.`play` `p`
    join `lastfm`.`artist` `a`) join
    (`lastfm`.`track` `t` left join `lastfm`.`album` `b` on ((`b`.`album_db_id` = `t`.`album_db_id`))))
  where ((`p`.`track_db_id` = `t`.`track_db_id`) and (`t`.`artist_db_id` = `a`.`artist_db_id`) and
         (((`nb_days`() is not null) and (`p`.`play_date` > (now() + interval -(`nb_days`()) day))) or
          isnull(`nb_days`())))
  group by `p`.`username`,  `b`.`album_name`, `a`.`artist_name`
  order by count(`p`.`play_db_id`) desc;

create or replace view view_top_tracks_for_last_n_days as
select
   `p`.`username`       as `username`,
    `t`.`track_name`        as `track_name`,
    `a`.`artist_name`       as `artist_name`,
    `b`.`album_name`        as `album_name`,
    count(`p`.`play_db_id`) as `play_count`
  from ((`lastfm`.`play` `p`
    join `lastfm`.`artist` `a`) join
    (`lastfm`.`track` `t` left join `lastfm`.`album` `b` on ((`b`.`album_db_id` = `t`.`album_db_id`))))
  where ((`p`.`track_db_id` = `t`.`track_db_id`) and (`t`.`artist_db_id` = `a`.`artist_db_id`) and
         (((`nb_days`() is not null) and (`p`.`play_date` > (now() + interval -(`nb_days`()) day))) or
          isnull(`nb_days`())))
  group by `p`.`username`,  `t`.`track_name`, `a`.`artist_name`, `b`.`album_name`
  order by count(`p`.`play_db_id`) desc;

create or replace view view_top_tracks_for_year as
  select
  `p`.`username`       as `username`,
    `t`.`track_name`        as `track_name`,
    `a`.`artist_name`       as `artist_name`,
    `b`.`album_name`        as `album_name`,
    count(`p`.`play_db_id`) as `play_count`
  from ((`lastfm`.`play` `p`
    join `lastfm`.`artist` `a`) join
    (`lastfm`.`track` `t` left join `lastfm`.`album` `b` on ((`b`.`album_db_id` = `t`.`album_db_id`))))
  where ((`p`.`track_db_id` = `t`.`track_db_id`) and (`t`.`artist_db_id` = `a`.`artist_db_id`) and
         (((year(`p`.`play_date`) = for_year()))))
  group by `p`.`username`,  `t`.`track_name`, `a`.`artist_name`, `b`.`album_name`
  order by count(`p`.`play_db_id`) desc;
use lastfm;

DELIMITER $$
CREATE DEFINER=`root`@`%` PROCEDURE `insert_play`(in username    varchar(512),
                                                  in track_name_in     varchar(512),
                                                     in track_mbid_in     varchar(36),
                                                     in track_url_in      text,
                                                     in play_date_uts_in  varchar(10),
                                                     in artist_name_in    text,
                                                     in artist_mbid_in    varchar(36),
                                                     in album_name_in     varchar(256),
                                                     in album_mbid_in     varchar(36),
												 OUT track_id_out INT(11)
                                                     )
    MODIFIES SQL DATA
    DETERMINISTIC
begin
    declare found_artist_db_id int;
    declare found_album_db_id int;
    declare found_track_db_id int;
    declare va_artist_name varchar(512);
    
    start transaction;

    ## Various artists
    select v.va_artist_name
    from various_artists v
    where v.va_album_name = album_name_in
          and ((v.va_artist_name is not null and v.va_artist_name like concat('%', artist_name_in, '%'))
               or v.va_artist_name is null)
    into va_artist_name;
    if (va_artist_name is not null)
    then
      select va_artist_name
      from dual
      into artist_name_in;
    end if;

    ## Find artist
    select a.artist_db_id
    from artist a
    where a.artist_name = artist_name_in
    into found_artist_db_id;

    ## Create if not found
    if (found_artist_db_id is null)
    then
      insert into artist (artist_name, artist_mbid) values (artist_name_in, artist_mbid_in);
      select a.artist_db_id
      from artist a
      where a.artist_name = artist_name_in
      into found_artist_db_id;
    end if;

    ## Find album
    if (album_name_in is not null)
    then
      select a.album_db_id
      from album a
      where a.album_name = album_name_in and a.artist_db_id = found_artist_db_id
      into found_album_db_id;

      ## Create if not found
      if (found_album_db_id is null)
      then
        insert into album (artist_db_id, album_name, album_mbid)
        values (found_artist_db_id, album_name_in, album_mbid_in);

        select a.album_db_id
        from album a
        where a.album_name = album_name_in and a.artist_db_id = found_artist_db_id
        into found_album_db_id;
      end if;
    end if;

    ## Find track
    select t.track_db_id
    from track t
    where
      (t.track_name = track_name_in and t.artist_db_id = found_artist_db_id and t.album_db_id = found_album_db_id and
       found_album_db_id is not null)
      or (t.track_name = track_name_in and t.artist_db_id = found_artist_db_id and found_album_db_id is null and
          t.album_db_id is null)
    into found_track_db_id;

    ## Create if not found
    if (found_track_db_id is null)
    then
      insert into track (artist_db_id, album_db_id, track_name, track_mbid, track_url)
      values (found_artist_db_id, found_album_db_id, track_name_in, track_mbid_in,
              track_url_in);

      select t.track_db_id
      from track t
      where
        (t.track_name = track_name_in and t.artist_db_id = found_artist_db_id and t.album_db_id = found_album_db_id and
         found_album_db_id is not null)
        or (t.track_name = track_name_in and t.artist_db_id = found_artist_db_id and found_album_db_id is null and
            t.album_db_id is null)
      into found_track_db_id;
    end if;
	
    ## Create play
    insert into play (username, track_db_id, play_date_uts, play_date)
    values (username, found_track_db_id, play_date_uts_in, FROM_UNIXTIME(play_date_uts_in));
	
    SELECT found_track_db_id INTO track_id_out;
    commit;
  end$$
DELIMITER ;


DELIMITER $$
create function check_track_in_db(track_name_in varchar(512), artist_name_in text, album_name_in varchar(256))
  returns tinyint(1)
  begin
    declare found_artist_db_id int;
    declare found_album_db_id int;
    declare found_track_db_id int;
    declare va_artist_name varchar(512);

    select v.va_artist_name
    from various_artists v
    where v.va_album_name = album_name_in
    into va_artist_name;
    if (va_artist_name is not null)
    then
      select va_artist_name
      from dual
      into artist_name_in;
    end if;

    select a.artist_db_id
    from artist a
    where a.artist_name = artist_name_in
    into found_artist_db_id;

    if (found_artist_db_id is null)
    then
      return false;
    end if;

    if (album_name_in is not null)
    then
      select a.album_db_id
      from album a
      where a.album_name = album_name_in and a.artist_db_id = found_artist_db_id
      into found_album_db_id;

      if (found_album_db_id is null)
      then
        return false;
      end if;
    end if;

    select t.track_db_id
    from track t
    where
      (t.track_name = track_name_in and t.artist_db_id = found_artist_db_id and t.album_db_id = found_album_db_id and
       found_album_db_id is not null)
      or (t.track_name = track_name_in and t.artist_db_id = found_artist_db_id and found_album_db_id is null and
          t.album_db_id is null)
    into found_track_db_id;

    return found_track_db_id is not null;
  end;$$
DELIMITER ;
use lastfm;
DELIMITER $$
create function check_tag_in_db(tag_name_in varchar(512))
  returns int(11)
  begin
    declare tag_id_out int;
    SELECT tag_id FROM tag WHERE TRIM(lower(tag_name)) like TRIM(lower(tag_name_in)) LIMIT 1 into tag_id_out;
    return tag_id_out;
  end;$$
DELIMITER ;

# Grant rights
use mysql;
