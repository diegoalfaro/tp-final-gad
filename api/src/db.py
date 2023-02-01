import os
import psycopg2
from psycopg2.extras import RealDictCursor

dsn = os.getenv('DATABASE_URL')

def use_db(callback):
    conn = psycopg2.connect(dsn)

    result = None

    with conn:
        with conn.cursor(cursor_factory=RealDictCursor) as curs:
            result = callback(curs, conn)

    conn.close()

    return result

def check_status():
    def db_callback(cur, _):
        cur.execute("SELECT 1 status")
        return cur.fetchone()
    result = use_db(db_callback)
    return result['status'] == 1

def get_all_artworks(url_prefix):
    def db_callback(cur, _):
        sql = """
            SELECT
                artwork.id,
                artwork.title,
                artwork.filepath,
                %(url_prefix)s || artwork.filepath image_url,
                get_base64_dataurl(pattern2image((artwork).pattern), 'jpeg') pattern_image_url,
                artist.name artist_name,
                artist.birth_year artist_birth_year,
                artist.death_year artist_death_year
            FROM
                artwork,
                artist
            WHERE
                artist.id = artwork.artist_id;
        """
        cur.execute(sql, {'url_prefix': url_prefix})
        return cur.fetchall()
    return use_db(db_callback)

def get_artwork(artwork_id, url_prefix):
    def db_callback(cur, _):
        sql = """
            SELECT
                artwork.id,
                artwork.title,
                artwork.filepath,
                %(url_prefix)s || artwork.filepath image_url,
                get_base64_dataurl(pattern2image((artwork).pattern), 'jpeg') pattern_image_url,
                artist.name artist_name,
                artist.birth_year artist_birth_year,
                artist.death_year artist_death_year
            FROM
                artwork,
                artist
            WHERE
                artwork.id = %(artwork_id)s AND
                artist.id = artwork.artist_id;
        """
        cur.execute(sql, {'artwork_id': artwork_id, 'url_prefix': url_prefix})
        return cur.fetchone()
    return use_db(db_callback)

def get_artworks_random(limit, url_prefix):
    def db_callback(cur, _):
        sql = """
            SELECT
                artwork.id,
                artwork.title,
                artwork.filepath,
                %(url_prefix)s || artwork.filepath image_url,
                get_base64_dataurl(pattern2image((artwork).pattern), 'jpeg') pattern_image_url,
                artist.name artist_name,
                artist.birth_year artist_birth_year,
                artist.death_year artist_death_year
            FROM
                artwork,
                artist
            WHERE
                artist.id = artwork.artist_id
            ORDER BY
                random()
            LIMIT
                %(limit)s;
        """
        cur.execute(sql, {'limit': limit, 'url_prefix': url_prefix})
        return cur.fetchall()
    return use_db(db_callback)

def get_similar_artworks(param, radius, limit, url_prefix):
    def db_callback(cur, _):
        sql = """
            SELECT
                distance,
                dicrete_distance_level,
                proportional_distance,
                similarity,
                percentage_similarity,
                (artwork).id,
                (artwork).title,
                (artwork).filepath,
                %(url_prefix)s || (artwork).filepath image_url,
                get_base64_dataurl(pattern2image((artwork).pattern), 'jpeg') pattern_image_url,
                (artist).name artist_name,
                (artist).birth_year artist_birth_year,
                (artist).death_year artist_death_year
            FROM
                similarity_search(%(param)s, %(radius)s)
            LIMIT
                %(limit)s;
        """
        cur.execute(sql, {'param': param, 'radius': radius, 'limit': limit, 'url_prefix': url_prefix})
        return cur.fetchall()
    return use_db(db_callback)

def insert_artwork(title, artist_id, filepath, resized_image, url_prefix):
    def db_callback(cur, _):
        sql = """
            INSERT INTO artwork (
                title,
                artist_id,
                filepath,
                pattern
            ) VALUES (
                %(title)s,
                %(artist_id)s,
                %(filepath)s,
                image2pattern(%(resized_image)s)
            ) RETURNING id;
        """
        cur.execute(sql, {'title': title, 'artist_id': artist_id, 'filepath': filepath, 'resized_image': resized_image})
        return cur.fetchone()
    artwork = use_db(db_callback)
    return get_artwork(artwork['id'], url_prefix)

def get_all_artists():
    def db_callback(cur, _):
        sql = """
            SELECT *
            FROM artist;
        """
        cur.execute(sql)
        return cur.fetchall()
    return use_db(db_callback)

def get_artist(artist_id):
    def db_callback(cur, _):
        sql = """
            SELECT *
            FROM artist
            WHERE id = %(artist_id)s;
        """
        cur.execute(sql, {'artist_id': artist_id})
        return cur.fetchone()
    return use_db(db_callback)

def get_all_pivots():
    def db_callback(cur, _):
        sql = """
            SELECT
                pivot.level,
                get_base64_dataurl(pattern2image(pivot.pattern), 'jpeg') image_url
            FROM
                pivot;
        """
        cur.execute(sql)
        return cur.fetchall()
    return use_db(db_callback)
