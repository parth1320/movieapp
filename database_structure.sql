create type unique_movies as
(
    movie_name   varchar,
    release_year integer
);

create type suggestion_list as
(
    movie_details unique_movies,
    cast_name     varchar,
    directed_by   varchar,
    genre         varchar,
    movies_rating double precision
);

create type suggested_list as
(
    movie_id      integer,
    movie_name    varchar,
    cast_name     varchar,
    directed_by   varchar,
    genre         varchar,
    movies_rating double precision
);

create type movie_suggestion_list as
(
    movie_details    unique_movies,
    cast_name        varchar,
    directed_by      varchar,
    mean_rating      double precision,
    sub_ordinated_to unique_movies,
    poster_url       varchar,
    genre1           varchar,
    genre2           varchar,
    genre3           varchar
);

create type suggestion_list_1 as
(
    movie_details unique_movies,
    cast_name     varchar,
    directed_by   varchar,
    written_by    varchar,
    genre         varchar,
    movies_rating double precision,
    movie_poster  varchar
);

create type suggestion_type as
(
    movie_details unique_movies,
    cast_name     varchar,
    directed_by   varchar,
    written_by    varchar,
    genre         varchar,
    movies_rating double precision,
    movie_poster  varchar,
    sub_ordinated unique_movies
);

create table if not exists movie_related_person
(
    person_name varchar not null,
    dob         date,
    sex         text,
    constraint movierelatedperson_pk
        primary key (person_name)
);

create unique index if not exists movierelatedperson_personname_uindex
    on movie_related_person (person_name);

create table if not exists user_list
(
    user_name varchar not null,
    dob       date,
    forename  varchar,
    surename  varchar,
    constraint user_pk
        primary key (user_name)
);

create table if not exists sub_ordinated_movies
(
    parent_movie unique_movies not null,
    child_movie  unique_movies not null
);

create table if not exists genres
(
    genres varchar not null,
    constraint genres_pk
        primary key (genres)
);

create table if not exists movie_list
(
    movie_and_year    unique_movies not null,
    leading_actor     varchar       not null,
    directed_by       varchar       not null,
    mean_rating       double precision,
    sub_ordinated_to  unique_movies,
    written_by        varchar       not null,
    genre1            varchar       not null,
    genre2            varchar,
    genre3            varchar,
    movie_poster_link varchar,
    constraint movie_list_pk
        primary key (movie_and_year),
    constraint movie_list_movie_related_person_person_name_fk
        foreign key (leading_actor) references movie_related_person,
    constraint movie_list_movie_related_person_person_name_fk_2
        foreign key (directed_by) references movie_related_person,
    constraint movie_list_genres_genres_fk
        foreign key (genre1) references genres,
    constraint movie_list_genres_genres_fk_2
        foreign key (genre2) references genres,
    constraint movie_list_genres_genres_fk_3
        foreign key (genre3) references genres,
    constraint movie_list_movie_related_person_person_name_fk_3
        foreign key (written_by) references movie_related_person
);

create table if not exists movies_watched
(
    user_name varchar          not null,
    rating    double precision not null,
    movie     unique_movies    not null,
    constraint movies_watched_pk
        primary key (user_name, movie),
    constraint movies_watched_movie_list_movie_and_year_fk
        foreign key (movie) references movie_list,
    constraint movies_watched_user_list_user_name_fk
        foreign key (user_name) references user_list
            on update cascade
            deferrable initially deferred,
    constraint mean_less_than_ten
        check ((rating >= (0)::double precision) AND (rating <= (10)::double precision))
);

create table if not exists suggestions
(
    movies suggestion_type
);

create or replace function ratings_copy() returns trigger
    language plpgsql
as
$$
BEGIN
    update movie_list mv set mean_rating = (select avg(rating) from movies_watched usr where mv.movie_and_year = usr.movie)from movies_watched usr where mv.movie_and_year = usr.movie;
    RETURN new;
END
$$;

create trigger numbers_insert
    after insert or update
    on movies_watched
    for each row
execute procedure ratings_copy();

create or replace function update_subordinate() returns trigger
    language plpgsql
as
$$
BEGIN
    insert into sub_ordinated_movies (parent_movie, child_movie) values (new.sub_ordinated_to, new.movie_and_year);
    RETURN new;
   
END
$$;

create trigger movie_to_sub
    after insert
    on movie_list
    for each row
    when (new.sub_ordinated_to IS NOT NULL)
execute procedure update_subordinate();

create or replace function detect_cycle() returns trigger
    language plpgsql
as
$$
declare
    test unique_movies = new.movie_and_year;
BEGIN

    
    if (new.sub_ordinated_to is not null) then
        if (SELECT not exists(SELECT 1 FROM movie_list WHERE movie_and_year = new.sub_ordinated_to LIMIT 1)) then
            raise exception 'Cannot add movie, which is not previously present in database';
        end if;
    end if;

    IF EXISTS (
            WITH RECURSIVE search_graph (parentid, path, cycle) AS (
                SELECT NEW.movie_and_year, ARRAY[NEW.sub_ordinated_to, NEW.movie_and_year], (NEW.sub_ordinated_to = NEW.movie_and_year) FROM movie_list WHERE sub_ordinated_to = NEW.movie_and_year
                UNION ALL
                SELECT movie_list.movie_and_year, path || movie_list.movie_and_year, movie_list.movie_and_year = ANY(path) FROM search_graph JOIN movie_list ON sub_ordinated_to = search_graph.parentid WHERE NOT cycle
            )
            SELECT 1 FROM search_graph WHERE cycle LIMIT 1
        ) THEN
        Raise exception 'Are you trying to create a cycle? If yes, then don''t :)' ;
    END IF;
    RETURN NEW;

END;
$$;

create trigger prevent_cycle
    before insert or update
    on movie_list
    for each row
execute procedure detect_cycle();

create or replace function delete_child_movies() returns trigger
    language plpgsql
as
$$
DECLARE
        previous_child unique_movies;

    BEGIN
        previous_child = old.child_movie;
        delete from sub_ordinated_movies where parent_movie = previous_child;
        delete from movie_list where movie_and_year = previous_child;
        return old;
        END;
$$;

create trigger clear_sub
    after delete
    on sub_ordinated_movies
    for each row
execute procedure delete_child_movies();

create or replace function clear_from_sub_ordinated() returns trigger
    language plpgsql
as
$$
BEGIN

     delete from sub_ordinated_movies where parent_movie = old.movie_and_year;
    return old;
END;
$$;

create trigger clean_subs
    after delete
    on movie_list
    for each row
execute procedure clear_from_sub_ordinated();

create or replace function delete_from_movies_by_mrp() returns trigger
    language plpgsql
as
$$
BEGIN
        delete from movie_list where (movie_list.leading_actor = old.person_name) or (movie_list.directed_by = old.person_name) or (movie_list.written_by = old.person_name);
        return old;
    END;
$$;

create trigger delete_related_personmovies
    before delete
    on movie_related_person
    for each row
execute procedure delete_from_movies_by_mrp();

create or replace function delete_from_moviewatched() returns trigger
    language plpgsql
as
$$
BEGIN
        delete from movies_watched where movie = old.movie_and_year;
        return old;
    end;
$$;

create trigger clear_movie_watched
    before delete
    on movie_list
    for each row
execute procedure delete_from_moviewatched();

create or replace function update_insertmovieswatched() returns trigger
    language plpgsql
as
$$
BEGIN
INSERT into movies_watched (user_name, movie, rating) values (new.user_name, new.movie, new.rating)on conflict (user_name, movie) do update set rating = new.rating where movies_watched.user_name=new.user_name and movies_watched.movie = new.movie;
return null;

END;
$$;

create trigger edit_movieswatched
    before insert
    on movies_watched
    for each row
    when (pg_trigger_depth() = 0)
execute procedure update_insertmovieswatched();

create or replace function prevent_update_subs() returns trigger
    language plpgsql
as
$$
BEGIN
    
    if(old.sub_ordinated_to is null) then
        insert into sub_ordinated_movies (parent_movie, child_movie) VALUES (new.sub_ordinated_to,new.movie_and_year);
        return new;

        elsif  (new.sub_ordinated_to is null)then
            raise exception 'Cannot update sub-ordinate to null';

        else update sub_ordinated_movies set parent_movie = new.sub_ordinated_to where parent_movie=old.sub_ordinated_to and child_movie = old.movie_and_year;
        return new;
    end if;
        END
$$;

create trigger donot_update_subs
    after update
        of sub_ordinated_to
    on movie_list
    for each row
execute procedure prevent_update_subs();

create or replace function check_if_movie_exists() returns trigger
    language plpgsql
as
$$
BEGIN
        if (SELECT exists ((SELECT 1 FROM movie_list WHERE movie_and_year = new.parent_movie LIMIT 1))AND(SELECT exists (SELECT 1 FROM movie_list WHERE movie_and_year = new.child_movie LIMIT 1))) then
            return new;
            else
            raise exception 'Movies added does not exist in database';
        end if;
END;
$$;

create trigger integrity_check_subs_ordinate
    after insert or update
    on sub_ordinated_movies
    for each row
execute procedure check_if_movie_exists();

create or replace function update_username() returns trigger
    language plpgsql
as
$$
BEGIN
    update movies_watched set user_name = new.user_name where user_name = old.user_name;
    return new;
    end
$$;

create trigger modify_moviewatched_username
    after update
        of user_name
    on user_list
    for each row
execute procedure update_username();

create or replace function get_me_my_movies(person character varying)
    returns TABLE(m unique_movies, cn character varying, db character varying, mr double precision, ss unique_movies, pr character varying, g1 character varying, g2 character varying, g3 character varying)
    language plpgsql
as
$$
DECLARE
    highest_ratedmovie unique_movies;
    out2               varchar;
    out3               varchar;
    genre_1            varchar;
    genre_2            varchar;
    genre_3            varchar;
    count_entries      int;


BEGIN

    for highest_ratedmovie in select movie from movies_watched where user_name = person order by rating desc
        loop

            genre_1 =
                    (select genre1 from movie_list where movie_and_year = highest_ratedmovie.movie_name::unique_movies);
            genre_2 =
                    (select genre2 from movie_list where movie_and_year = highest_ratedmovie.movie_name::unique_movies);
            genre_3 =
                    (select genre3 from movie_list where movie_and_year = highest_ratedmovie.movie_name::unique_movies);
            out2 = (select cast_name
                    from movie_list
                    where movie_and_year = highest_ratedmovie.movie_name::unique_movies);
            out3 = (select directed_by
                    from movie_list
                    where movie_and_year = highest_ratedmovie.movie_name::unique_movies);

            count_entries = (SELECT COUNT(*)
                             FROM (

                                 select distinct on ((movie_and_year).movie_name) *

                                   from movie_list

                                   WHERE NOT EXISTS(select movie
                                                    from movies_watched
                                                    where movie_and_year = movie and user_name = person)
                                     AND (
                                           (highest_ratedmovie.movie_name::unique_movies in (sub_ordinated_to)) or
                                           ((movie_list.cast_name = out2 AND movie_list.directed_by = out3)) OR
                                           (genre1 = genre_1 AND genre2 = genre_2 AND genre3 = genre_3) OR
                                           (genre1 = genre_2 AND genre2 = genre_3 AND genre3 = genre_1) OR
                                           (genre1 = genre_3 AND genre2 = genre_1 AND genre3 = genre_2) OR
                                           (
                                                   (genre1 = genre_1 AND genre2 = genre_1) OR
                                                   (genre1 = genre_2 AND genre2 = genre_2) OR
                                                   (genre1 = genre_3 AND genre2 = genre_3)
                                               ) OR
                                           (genre1 = genre_1 or genre1 = genre_2 or genre1 = genre_3)
                                       )) as ss);

            RETURN QUERY
                select *

                from movie_list

                WHERE NOT EXISTS(select movie from movies_watched where movie_and_year = movie and user_name = person)
                  AND (
                        (highest_ratedmovie.movie_name::unique_movies in (sub_ordinated_to)) or
                        ((movie_list.cast_name = out2 AND movie_list.directed_by = out3)) OR
                        (genre1 = genre_1 AND genre2 = genre_2 AND genre3 = genre_3) OR
                        (genre1 = genre_2 AND genre2 = genre_3 AND genre3 = genre_1) OR
                        (genre1 = genre_3 AND genre2 = genre_1 AND genre3 = genre_2) OR
                        (
                                (genre1 = genre_1 AND genre2 = genre_1) OR
                                (genre1 = genre_2 AND genre2 = genre_2) OR
                                (genre1 = genre_3 AND genre2 = genre_3)
                            ) OR
                        (genre1 = genre_1 or genre1 = genre_2 or genre1 = genre_3)
                    );
        end loop;

    if (count_entries < 5) then
        RETURN QUERY (select movie_and_year,
                             cast_name,
                             directed_by,
                             concat(genre1, ' ,', genre2, ', ', genre3),
                             mean_rating

                      from movie_list
                      WHERE NOT EXISTS(select movie
                                       from movies_watched
                                       where movie_and_year = movie
                                         and user_name = person)
                      order by mean_rating desc);
    end if;
END
$$;

create or replace function get_suggestions(person character varying) returns SETOF suggestion_type
    language plpgsql
as
$$
DECLARE
    highest_ratedmovie unique_movies;
    out2               varchar;
    out3               varchar;
    genre_1            varchar;
    genre_2            varchar;
    genre_3            varchar;
    rec                suggestion_type;
    count_entries      int;


BEGIN

    truncate suggestions;
    for highest_ratedmovie in select movie
                              from movies_watched
                              where user_name = person and rating > 5
                              order by rating desc
        loop

            genre_1 =
                    (select genre1 from movie_list where movie_and_year = highest_ratedmovie.movie_name::unique_movies);
            genre_2 =
                    (select genre2 from movie_list where movie_and_year = highest_ratedmovie.movie_name::unique_movies);
            genre_3 =
                    (select genre3 from movie_list where movie_and_year = highest_ratedmovie.movie_name::unique_movies);
            out2 = (select leading_actor
                    from movie_list
                    where movie_and_year = highest_ratedmovie.movie_name::unique_movies);
            out3 = (select directed_by
                    from movie_list
                    where movie_and_year = highest_ratedmovie.movie_name::unique_movies);


            for rec in
                select movie_and_year,
                       leading_actor,
                       directed_by,
                       written_by,
                       concat(genre1, ' ,', genre2, ', ', genre3),
                       mean_rating,
                       movie_poster_link,
                       sub_ordinated_to

                from movie_list

                WHERE NOT EXISTS(select movie from movies_watched where movie_and_year = movie and user_name = person)
                  AND (
                       (highest_ratedmovie.movie_name::unique_movies in (sub_ordinated_to)) 
                            or
                        (
                            ((movie_list.leading_actor = out2 AND movie_list.directed_by = out3)) OR

                            (genre1 = genre_1 AND genre2 = genre_2 AND genre3 = genre_3) OR
                            (genre1 = genre_2 AND genre2 = genre_3 AND genre3 = genre_1) OR
                            (genre1 = genre_3 AND genre2 = genre_1 AND genre3 = genre_2) OR
                            (
                                (genre1 = genre_1 AND genre2 = genre_1) OR
                                (genre1 = genre_2 AND genre2 = genre_2) OR
                                (genre1 = genre_3 AND genre2 = genre_3)
                            ) OR
                        (genre1 = genre_1 or genre1 = genre_2 or genre1 = genre_3)) and(movie_list.movie_and_year not in(select child_movie from sub_ordinated_movies) )
                    )
                loop
                    insert into suggestions (movies) values (rec);
                    return next rec;
                end loop;
        end loop;

    count_entries = (SELECT COUNT(*) FROM (SELECT DISTINCT on ((movies).movie_details) * FROM suggestions) as ss);
    if(count_entries =0) then

        for rec in
            select movie_and_year,
                   leading_actor,
                   directed_by,
                   written_by,
                   concat(genre1, ' ,', genre2, ', ', genre3),
                   mean_rating,
                   movie_poster_link,
                   sub_ordinated_to
            FROM movie_list mv
            WHERE
                    NOT EXISTS(select movie from movies_watched where  mv.movie_and_year = movie and user_name = person) 
                        AND mv.movie_and_year not in(select child_movie from sub_ordinated_movies)
                    
               OR NOT EXISTS(select movie from movies_watched where mv.movie_and_year = movie and user_name = person)
                AND NOT EXISTS(select movies
                               from suggestions
                               where (movies).movie_details = movie_and_year
                    )

            loop
                insert into suggestions (movies) values (rec);
                return next rec;
            end loop;

   elseif  (count_entries < 5) then
        for rec in
            select movie_and_year,
                   leading_actor,
                   directed_by,
                   written_by,
                   concat(genre1, ' ,', genre2, ', ', genre3),
                   mean_rating,
                   movie_poster_link
            ,sub_ordinated_to
            FROM movie_list mv
            WHERE
                  NOT EXISTS(select movie from movies_watched where  mv.movie_and_year = movie and user_name = person)
               AND
                    NOT EXISTS(select movies
                               from suggestions
                               where (movies).movie_details =mv.movie_and_year
                    )AND ((mv.movie_and_year not in(select child_movie from sub_ordinated_movies))) AND (mean_rating >5)

            group by mv.movie_and_year,(mv.movie_and_year).movie_name
            order by mean_rating desc NULLS LAST

            loop
                insert into suggestions (movies) values (rec);
                return next rec;
            end loop;
    end if;

END
$$;

