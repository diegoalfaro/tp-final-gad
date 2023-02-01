/****************************************
 * Triggers                             *
 ****************************************/

-- Conectarse a la base de datos
\c trabajo_final_gad;

CREATE OR REPLACE FUNCTION artwork_trigger_function_01() RETURNS TRIGGER AS
$$
BEGIN
	DELETE FROM artwork WHERE id = old.id;
	INSERT INTO artwork (id, title, artist_id, filename, fhqt_leaf_id) VALUES (new.id, new.title, new.artist_id, new.filename, new.fhqt_leaf_id);
	RETURN NULL;
END;
$$
LANGUAGE PlPgSQL;

CREATE TRIGGER artwork_trigger_01
BEFORE UPDATE ON artwork
FOR EACH ROW
EXECUTE PROCEDURE artwork_trigger_function_01();

CREATE OR REPLACE FUNCTION artwork_trigger_function_02() RETURNS TRIGGER AS
$$
DECLARE
	current_fhqt fhqt;
	pivot_distance int;
	pivot_distances int[] = ARRAY(
		SELECT get_discretized_distance_level(p.pattern, new.pattern)
		FROM pivot p
		ORDER BY p.level ASC
	);
BEGIN
	SELECT * INTO current_fhqt FROM fhqt WHERE id = 1;
	
	FOREACH pivot_distance IN ARRAY pivot_distances LOOP
		IF EXISTS (SELECT * FROM fhqt WHERE fhqt_father_id = current_fhqt.id AND distance = pivot_distance) THEN
			SELECT * INTO current_fhqt FROM fhqt WHERE fhqt_father_id = current_fhqt.id AND distance = pivot_distance;
		ELSE
			INSERT INTO fhqt (fhqt_father_id, distance) VALUES (current_fhqt.id, pivot_distance) RETURNING * INTO current_fhqt;
		END IF;
	END LOOP;

	new.fhqt_leaf_id = current_fhqt.id;

	RETURN new;
END;
$$
LANGUAGE PlPgSQL;

CREATE TRIGGER artwork_trigger_02
BEFORE INSERT ON artwork
FOR EACH ROW
EXECUTE PROCEDURE artwork_trigger_function_02();
