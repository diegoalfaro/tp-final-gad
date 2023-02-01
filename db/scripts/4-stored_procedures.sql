/****************************************
 * Stored procedures                    *
 ****************************************/

-- Conectarse a la base de datos
\c trabajo_final_gad;

CREATE OR REPLACE FUNCTION get_discretized_distance_level(pattern, pattern, levels int default 16)
RETURNS int AS
$$
	SELECT round(($1 </> $2) * levels);
$$
LANGUAGE SQL;
-- Ejemplo: SELECT get_discretized_distance_level((SELECT pattern FROM artwork where id = 25), (SELECT pattern FROM artwork where id = 56));

CREATE OR REPLACE FUNCTION similarity_search(search_pattern pattern, radius int)
RETURNS SETOF similaritysearchresultitem AS
$$
DECLARE
  fhqt_ids int[] = array(
    SELECT f.id
    FROM fhqt f
    ORDER BY f.id ASC
    LIMIT 1
  );
  pivot_distance int;
	pivot_distances int[] = array(
    SELECT get_discretized_distance_level(p.pattern, search_pattern)
    FROM pivot p
    ORDER BY p.level ASC
  );
BEGIN
	FOREACH pivot_distance IN array pivot_distances LOOP
		fhqt_ids = array(
      SELECT f.id
      FROM fhqt f
      WHERE
        f.fhqt_father_id = ANY(fhqt_ids) AND
        f.distance BETWEEN pivot_distance - radius AND pivot_distance + radius
    );
	END LOOP;

  RETURN QUERY
    SELECT
      artwork.pattern <-> search_pattern distance,
      get_discretized_distance_level(artwork.pattern, search_pattern) dicrete_distance_level,
      artwork.pattern </> search_pattern proportional_distance,
      artwork.pattern <=> search_pattern similarity,
      artwork.pattern <%> search_pattern percentage_similarity,
      artwork,
      artist
    FROM
      artwork,
      artist
    WHERE
      artist.id = artwork.artist_id AND
      artwork.fhqt_leaf_id = ANY(fhqt_ids)
    ORDER BY
      artwork.pattern <-> search_pattern ASC;
END;
$$
LANGUAGE PlPgSQL;

CREATE OR REPLACE FUNCTION similarity_search(artwork_id int, radius int)
RETURNS SETOF similaritysearchresultitem AS
$$
DECLARE
	search_pattern pattern = (SELECT pattern FROM artwork WHERE id = artwork_id);
BEGIN
	RETURN QUERY SELECT * FROM similarity_search(search_pattern, radius);
END;
$$
LANGUAGE PlPgSQL;

CREATE OR REPLACE FUNCTION similarity_search(img_data_bytes bytea, radius int)
RETURNS SETOF similaritysearchresultitem AS
$$
DECLARE
	search_pattern pattern = image2pattern(img_data_bytes);
BEGIN
	RETURN QUERY SELECT * FROM similarity_search(search_pattern, radius);
END;
$$
LANGUAGE PlPgSQL;
-- Ejemplo: SELECT * FROM similarity_search(pg_read_binary_file('/static/images/Henri_Matisse_66.jpg'), 10);

CREATE OR REPLACE FUNCTION similarity_search(search_artwork artwork, radius int)
RETURNS SETOF similaritysearchresultitem AS
$$
DECLARE
	search_pattern pattern = (search_artwork).pattern;
BEGIN
	RETURN QUERY SELECT * FROM similarity_search(search_pattern, radius);
END;
$$
LANGUAGE PlPgSQL;

-- Funcion que obtiene el dataurl base64 de una imagen
CREATE OR REPLACE FUNCTION get_base64_dataurl(img_data_bytes bytea, extension varchar)
RETURNS varchar AS
$$
BEGIN
	RETURN 'data:image/' || extension || ';base64,' || encode(img_data_bytes, 'base64');
END;
$$
LANGUAGE PlPgSQL;

CREATE OR REPLACE FUNCTION get_pivots(K int, N int, A int, patterns pattern[])
RETURNS SETOF pattern AS
$$
DECLARE
	patterns_a1 pattern[] = array(SELECT pattern FROM unnest(patterns) arr(pattern) ORDER BY random() LIMIT A);
	patterns_a2 pattern[] = array(SELECT pattern FROM unnest(patterns) arr(pattern) ORDER BY random() LIMIT A);
	patterns_n pattern[];
	pattern_n pattern;
	items getpivotsitem[];
	item getpivotsitem;
	max_efficiency_item getpivotsitem;
BEGIN
	FOR i IN 1..K LOOP
		patterns_n = array(SELECT pattern FROM unnest(patterns) arr(pattern) ORDER BY random() LIMIT N);
		items = '{}';
	
		FOREACH pattern_n IN array patterns_n LOOP
			items = items || array(
				SELECT 
					(pattern_n, avg(signature) OVER w)::getpivotsitem
				FROM (
					SELECT
						GREATEST(
							get_discretized_distance_level(patterns_a1[j], pattern_n),
							get_discretized_distance_level(patterns_a2[j], pattern_n)
						)
					FROM generate_series(1, A) gs(j)
				) signatures(signature)
				WINDOW w AS (PARTITION BY signature)
			);
		END LOOP;
		
		max_efficiency_item = items[1];

		FOREACH item IN array items LOOP
			IF item.efficiency > max_efficiency_item.efficiency THEN
				max_efficiency_item = item;
			END IF;
		END LOOP;

		RETURN NEXT max_efficiency_item.pattern;
	END LOOP;
END;
$$
LANGUAGE PlPgSQL;
