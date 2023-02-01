/****************************************
 * Setup database                       *
 ****************************************/

-- Crear base de datos
CREATE DATABASE trabajo_final_gad;

-- Conectarse a la base de datos
\c trabajo_final_gad;

-- Agregar extension imagecomparer
CREATE EXTENSION imagecomparer;

/****************************************
 * Schema                               *
 ****************************************/

-- Crear tabla para el árbol
CREATE TABLE fhqt (
	id serial primary key,
	fhqt_father_id integer REFERENCES fhqt(id),
	distance integer
);

-- Crear tabla de artistas
CREATE TABLE artist (
	id serial primary key,
	name varchar(64) not null,
	birth_year smallint not null CHECK (birth_year >= 0),
	death_year smallint CHECK (death_year is null OR death_year >= birth_year),
	genre varchar(128),
	nationality varchar(128),
	biourl varchar(256)
);

-- Crear tabla de obras de arte
CREATE TABLE artwork (
	id serial primary key,
	title varchar(128),
	artist_id integer not null REFERENCES artist(id),
	filename varchar(512) not null,
	pattern pattern,
	fhqt_leaf_id integer REFERENCES fhqt(id)
);

-- Crear tabla para los pivotes
CREATE TABLE pivot (
	level integer not null primary key,
	pattern pattern not null
);

/****************************************
 * Triggers                             *
 ****************************************/

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

CREATE OR REPLACE FUNCTION artwork_trigger_function_02()
RETURNS trigger AS
$$
DECLARE
  imageFilepath varchar;
  img_data_bytes bytea;
BEGIN
  imageFilepath := '/static/resized/' || new.filename;
  img_data_bytes := pg_read_binary_file(imageFilepath);

  new.pattern = image2pattern(img_data_bytes);
  
  RETURN new;
END
$$
LANGUAGE PlPgSQL;

CREATE TRIGGER artwork_trigger_02
BEFORE INSERT OR UPDATE ON artwork
FOR EACH ROW
EXECUTE PROCEDURE artwork_trigger_function_02();

CREATE OR REPLACE FUNCTION artwork_trigger_function_03() RETURNS TRIGGER AS
$$
DECLARE
	currentFhqt fhqt;
  pivotDistance int;
	pivotDistances int[] = ARRAY(
    SELECT get_discretized_distance_level(p.pattern, new.pattern)
    FROM pivot p
    ORDER BY p.level ASC
  );
BEGIN
	SELECT * INTO currentFhqt FROM fhqt nodo WHERE nodo.id = 1;
	
	FOREACH pivotDistance IN ARRAY pivotDistances LOOP
		IF EXISTS (SELECT * FROM fhqt nodo WHERE nodo.fhqt_father_id = currentFhqt.id AND nodo.distance = pivotDistance) THEN
			SELECT * INTO currentFhqt FROM fhqt nodo WHERE nodo.fhqt_father_id = currentFhqt.id AND nodo.distance = pivotDistance;
		ELSE
			INSERT INTO fhqt (fhqt_father_id, distance) VALUES (currentFhqt.id, pivotDistance) RETURNING * INTO currentFhqt;
		END IF;
	END LOOP;

	new.fhqt_leaf_id = currentFhqt.id;

	RETURN new;
END;
$$
LANGUAGE PlPgSQL;

CREATE TRIGGER artwork_trigger_03
BEFORE INSERT ON artwork
FOR EACH ROW
EXECUTE PROCEDURE artwork_trigger_function_03();

/****************************************
 * Stored procedures                    *
 ****************************************/

CREATE OR REPLACE FUNCTION get_discretized_distance_level(pattern, pattern, levels int default 10)
RETURNS integer AS
$$
	SELECT round(($1 </> $2) * levels);
$$
LANGUAGE SQL;
-- Ejemplo: SELECT get_discretized_distance_level((SELECT pattern FROM artwork where id = 25), (SELECT pattern FROM artwork where id = 56));

CREATE OR REPLACE FUNCTION similarity_search(search_pattern pattern, radius int)
RETURNS SETOF artwork AS
$$
DECLARE
  fhqtIds int[] = ARRAY(
    SELECT f.id
    FROM fhqt f
    ORDER BY f.id ASC
    LIMIT 1
  );
  pivotDistance int;
	pivotDistances int[] = ARRAY(
    SELECT get_discretized_distance_level(p.pattern, search_pattern)
    FROM pivot p
    ORDER BY p.level ASC
  );
BEGIN
	FOREACH pivotDistance IN ARRAY pivotDistances LOOP
		fhqtIds := ARRAY(
      SELECT f.id
      FROM fhqt f
      WHERE
        f.fhqt_father_id = ANY(fhqtIds) AND
        f.distance BETWEEN pivotDistance - radius AND pivotDistance + radius
    );
	END LOOP;

  RETURN QUERY
    SELECT a
    FROM artwork a
    ORDER BY a.pattern <-> search_pattern ASC;
END;
$$
LANGUAGE PlPgSQL;

CREATE OR REPLACE FUNCTION similarity_search(artworkId integer, radius integer)
RETURNS SETOF artwork AS
$$
DECLARE
	search_pattern pattern = (SELECT pattern FROM artwork WHERE id = artworkId);
BEGIN
	RETURN QUERY SELECT * FROM similarity_search(search_pattern, radius);
END;
$$
LANGUAGE PlPgSQL;

CREATE OR REPLACE FUNCTION similarity_search(img_data_bytes bytea, radius integer)
RETURNS SETOF artwork AS
$$
DECLARE
	search_pattern pattern = image2pattern(img_data_bytes);
BEGIN
	RETURN QUERY SELECT * FROM similarity_search(search_pattern, radius);
END;
$$
LANGUAGE PlPgSQL;
-- Ejemplo: SELECT * FROM similarity_search(pg_read_binary_file('/static/images/Henri_Matisse_66.jpg'), 10);

CREATE OR REPLACE FUNCTION similarity_search(search_artwork artwork, radius integer)
RETURNS SETOF artwork AS
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
RETURNS VARCHAR AS
$$
BEGIN
	RETURN 'data:image/' || extension || ';base64,' || encode(img_data_bytes, 'base64');
END;
$$
LANGUAGE PlPgSQL;

/****************************************
 * Data                                 *
 ****************************************/

-- Insertar nodo padre del arbol FHQT
INSERT INTO fhqt (fhqt_father_id, distance) VALUES (null, null);

-- Insertar pivotes
INSERT INTO pivot (level, pattern) VALUES (1,  image2pattern(pg_read_binary_file('/static/resized/Albrecht_Durer_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (2,  image2pattern(pg_read_binary_file('/static/resized/Alfred_Sisley_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (3,  image2pattern(pg_read_binary_file('/static/resized/Amedeo_Modigliani_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (4,  image2pattern(pg_read_binary_file('/static/resized/Andrei_Rublev_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (5,  image2pattern(pg_read_binary_file('/static/resized/Andy_Warhol_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (6,  image2pattern(pg_read_binary_file('/static/resized/Camille_Pissarro_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (7,  image2pattern(pg_read_binary_file('/static/resized/Caravaggio_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (8,  image2pattern(pg_read_binary_file('/static/resized/Claude_Monet_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (9,  image2pattern(pg_read_binary_file('/static/resized/Diego_Rivera_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (10, image2pattern(pg_read_binary_file('/static/resized/Diego_Velazquez_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (11, image2pattern(pg_read_binary_file('/static/resized/Edgar_Degas_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (12, image2pattern(pg_read_binary_file('/static/resized/Edouard_Manet_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (13, image2pattern(pg_read_binary_file('/static/resized/Edvard_Munch_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (14, image2pattern(pg_read_binary_file('/static/resized/El_Greco_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (15, image2pattern(pg_read_binary_file('/static/resized/Eugene_Delacroix_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (16, image2pattern(pg_read_binary_file('/static/resized/Francisco_Goya_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (17, image2pattern(pg_read_binary_file('/static/resized/Frida_Kahlo_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (18, image2pattern(pg_read_binary_file('/static/resized/Georges_Seurat_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (19, image2pattern(pg_read_binary_file('/static/resized/Giotto_di_Bondone_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (20, image2pattern(pg_read_binary_file('/static/resized/Gustav_Klimt_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (21, image2pattern(pg_read_binary_file('/static/resized/Gustave_Courbet_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (22, image2pattern(pg_read_binary_file('/static/resized/Henri_Matisse_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (23, image2pattern(pg_read_binary_file('/static/resized/Henri_Rousseau_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (24, image2pattern(pg_read_binary_file('/static/resized/Henri_de_Toulouse-Lautrec_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (25, image2pattern(pg_read_binary_file('/static/resized/Hieronymus_Bosch_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (26, image2pattern(pg_read_binary_file('/static/resized/Jackson_Pollock_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (27, image2pattern(pg_read_binary_file('/static/resized/Jan_van_Eyck_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (28, image2pattern(pg_read_binary_file('/static/resized/Joan_Miro_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (29, image2pattern(pg_read_binary_file('/static/resized/Kazimir_Malevich_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (30, image2pattern(pg_read_binary_file('/static/resized/Leonardo_da_Vinci_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (31, image2pattern(pg_read_binary_file('/static/resized/Marc_Chagall_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (32, image2pattern(pg_read_binary_file('/static/resized/Michelangelo_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (33, image2pattern(pg_read_binary_file('/static/resized/Mikhail_Vrubel_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (34, image2pattern(pg_read_binary_file('/static/resized/Pablo_Picasso_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (35, image2pattern(pg_read_binary_file('/static/resized/Paul_Cezanne_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (36, image2pattern(pg_read_binary_file('/static/resized/Paul_Gauguin_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (37, image2pattern(pg_read_binary_file('/static/resized/Paul_Klee_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (38, image2pattern(pg_read_binary_file('/static/resized/Peter_Paul_Rubens_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (39, image2pattern(pg_read_binary_file('/static/resized/Pierre-Auguste_Renoir_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (40, image2pattern(pg_read_binary_file('/static/resized/Piet_Mondrian_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (41, image2pattern(pg_read_binary_file('/static/resized/Pieter_Bruegel_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (42, image2pattern(pg_read_binary_file('/static/resized/Raphael_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (43, image2pattern(pg_read_binary_file('/static/resized/Rembrandt_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (44, image2pattern(pg_read_binary_file('/static/resized/Rene_Magritte_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (45, image2pattern(pg_read_binary_file('/static/resized/Salvador_Dali_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (46, image2pattern(pg_read_binary_file('/static/resized/Sandro_Botticelli_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (47, image2pattern(pg_read_binary_file('/static/resized/Titian_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (48, image2pattern(pg_read_binary_file('/static/resized/Vasiliy_Kandinskiy_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (49, image2pattern(pg_read_binary_file('/static/resized/Vincent_van_Gogh_1.jpg')));
INSERT INTO pivot (level, pattern) VALUES (50, image2pattern(pg_read_binary_file('/static/resized/William_Turner_1.jpg')));

-- Insertar los artistas con sus respectivas obras de arte
DO
$$
DECLARE
    artistId integer;
BEGIN

  INSERT INTO artist (
    name,
    birth_year,
    death_year,
    genre,
    nationality,
    biourl
  ) VALUES (
    'Leonardo da Vinci',
    1452,
    1519,
    'High Renaissance',
    'Italian',
    'http://en.wikipedia.org/wiki/Leonardo_da_Vinci'
  ) RETURNING id INTO artistId;

  RAISE NOTICE 'Inserting artworks of Leonardo da Vinci';

  INSERT INTO artwork (title, artist_id, filename) VALUES ('Virgin and Child with Two Angels', artistId, 'Leonardo_da_Vinci_1.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Studies of the sexual act and male sexual organ', artistId, 'Leonardo_da_Vinci_2.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('An Angel in Green with a Vielle', artistId, 'Leonardo_da_Vinci_3.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('An Angel in Red with a Lute', artistId, 'Leonardo_da_Vinci_4.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Scythed Chariot', artistId, 'Leonardo_da_Vinci_5.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Madona Benois', artistId, 'Leonardo_da_Vinci_6.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('La batalla de Anghiari', artistId, 'Leonardo_da_Vinci_7.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_8.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Giclee Print:Banner Study', artistId, 'Leonardo_da_Vinci_9.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_10.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_11.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_12.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Leonardo da Vinci Canvas Art Anatomy of a Foot', artistId, 'Leonardo_da_Vinci_13.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Cannon foundry', artistId, 'Leonardo_da_Vinci_14.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Design for an enormous crossbow', artistId, 'Leonardo_da_Vinci_15.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Cabeza de la Virgen vista de tres cuartos, mirando a la derecha', artistId, 'Leonardo_da_Vinci_16.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study for the Head of Leda', artistId, 'Leonardo_da_Vinci_17.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Head of Leda', artistId, 'Leonardo_da_Vinci_18.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Head of Christ', artistId, 'Leonardo_da_Vinci_19.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Autorretrato', artistId, 'Leonardo_da_Vinci_20.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('recto: Study for the Head of a Soldier in the Battle of Anghiari', artistId, 'Leonardo_da_Vinci_21.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Profile of an ancient captain', artistId, 'Leonardo_da_Vinci_22.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Hombre de Vitruvio', artistId, 'Leonardo_da_Vinci_23.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Old man with ivy wreath and lion''s head', artistId, 'Leonardo_da_Vinci_24.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('La Virgen, el Niño Jesús y Santa Ana', artistId, 'Leonardo_da_Vinci_25.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Heads of an old man and a youth', artistId, 'Leonardo_da_Vinci_26.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Grotesque Head', artistId, 'Leonardo_da_Vinci_27.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('La duquesa fea', artistId, 'Leonardo_da_Vinci_28.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Anunciación', artistId, 'Leonardo_da_Vinci_29.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_30.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Cabezas grotescas', artistId, 'Leonardo_da_Vinci_31.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Grotesque Profile', artistId, 'Leonardo_da_Vinci_32.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Leonardo Da Vinci: The Divine and the Grotesque', artistId, 'Leonardo_da_Vinci_33.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Cecilia Gallerani', artistId, 'Leonardo_da_Vinci_34.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Matched Couple', artistId, 'Leonardo_da_Vinci_35.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Cabeza de muchacha', artistId, 'Leonardo_da_Vinci_36.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Woman''s Head', artistId, 'Leonardo_da_Vinci_37.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_38.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_39.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study for the Kneeling Leda', artistId, 'Leonardo_da_Vinci_40.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('A Miracle of Saint Donatus of Arezzo', artistId, 'Leonardo_da_Vinci_41.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Design for a flying machine', artistId, 'Leonardo_da_Vinci_43.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Flying machine', artistId, 'Leonardo_da_Vinci_44.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('De divina proportione', artistId, 'Leonardo_da_Vinci_45.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Storm over a landscape', artistId, 'Leonardo_da_Vinci_46.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Cartón de Burlington House', artistId, 'Leonardo_da_Vinci_47.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Virgin and Child with a Cat', artistId, 'Leonardo_da_Vinci_48.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study for the Madonna with the Fruit Bowl', artistId, 'Leonardo_da_Vinci_49.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study of St Anne, Mary and the Christ Child', artistId, 'Leonardo_da_Vinci_50.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Crossbow Machine', artistId, 'Leonardo_da_Vinci_51.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Retrato de un músico', artistId, 'Leonardo_da_Vinci_52.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Head of a Man', artistId, 'Leonardo_da_Vinci_53.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Landscape drawing for Santa Maria della Neve', artistId, 'Leonardo_da_Vinci_54.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Comparison of scalp skin and onion', artistId, 'Leonardo_da_Vinci_55.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Landscape drawing for Santa Maria della Neve', artistId, 'Leonardo_da_Vinci_56.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Hanging of Bernardo Bandini Baroncelli', artistId, 'Leonardo_da_Vinci_57.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Perspectival study of the Adoration of the Magi', artistId, 'Leonardo_da_Vinci_58.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study for the Adoration of the Magi', artistId, 'Leonardo_da_Vinci_59.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Retrato de Isabel de Este', artistId, 'Leonardo_da_Vinci_60.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Portrait of Lorenzo the Magnificent', artistId, 'Leonardo_da_Vinci_61.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('La Bella Principessa', artistId, 'Leonardo_da_Vinci_62.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study of St. Anne, Mary, the Christ Child and the young St. John', artistId, 'Leonardo_da_Vinci_63.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Compositional Sketches for the Virgin Adoring the Christ Child, with and without the Infant St. John the Baptist', artistId, 'Leonardo_da_Vinci_64.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Madonna, Study', artistId, 'Leonardo_da_Vinci_65.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Studies of Water passing Obstacles and falling', artistId, 'Leonardo_da_Vinci_66.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('La Virgen de las Rocas', artistId, 'Leonardo_da_Vinci_67.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Cartoon for the head of the infant Saint John the Baptist', artistId, 'Leonardo_da_Vinci_68.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study for the Last Supper', artistId, 'Leonardo_da_Vinci_69.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Half-Length Figure of an Apostle, 1493-1495', artistId, 'Leonardo_da_Vinci_70.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Madonna Litta', artistId, 'Leonardo_da_Vinci_71.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Head of Christ', artistId, 'Leonardo_da_Vinci_72.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study for the Last Supper', artistId, 'Leonardo_da_Vinci_73.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study of an apostle''s head and architectural study', artistId, 'Leonardo_da_Vinci_74.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The head of St Philip', artistId, 'Leonardo_da_Vinci_75.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study for the Last Supper: Judas', artistId, 'Leonardo_da_Vinci_76.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('A deluge', artistId, 'Leonardo_da_Vinci_77.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Estudio para un monumento ecuestre', artistId, 'Leonardo_da_Vinci_78.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Drapery for a Seated Figure', artistId, 'Leonardo_da_Vinci_79.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study for Madonna and Child with St. Anne', artistId, 'Leonardo_da_Vinci_80.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Drapery for a Seated Figure', artistId, 'Leonardo_da_Vinci_81.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Anunciación', artistId, 'Leonardo_da_Vinci_82.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Drapery for a Seated Figure', artistId, 'Leonardo_da_Vinci_83.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Drapery for a Seated Figure', artistId, 'Leonardo_da_Vinci_84.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Drapery Study for the Angel of the Annunciation', artistId, 'Leonardo_da_Vinci_85.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study sheet with cats, dragon and other animals', artistId, 'Leonardo_da_Vinci_86.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Masquerader in the Guise of a Prisoner', artistId, 'Leonardo_da_Vinci_87.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study of Two Warriors'' Heads for the Battle of Anghiari', artistId, 'Leonardo_da_Vinci_88.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Drawing of lilies, for an Annunciation', artistId, 'Leonardo_da_Vinci_89.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study sheet with horses', artistId, 'Leonardo_da_Vinci_90.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Caballo de Leonardo', artistId, 'Leonardo_da_Vinci_91.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_92.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Lucrezia Crivelli', artistId, 'Leonardo_da_Vinci_93.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Studies of legs of man and the leg of a horse', artistId, 'Leonardo_da_Vinci_94.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Profile of a man and study of two riders', artistId, 'Leonardo_da_Vinci_95.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_96.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Old man with ivy wreath and lion''s head', artistId, 'Leonardo_da_Vinci_97.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_98.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Hombre de Vitruvio', artistId, 'Leonardo_da_Vinci_99.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_100.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_101.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study of hands', artistId, 'Leonardo_da_Vinci_102.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study of battles on horseback', artistId, 'Leonardo_da_Vinci_103.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_104.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('A star-of-Bethlehem and other plants', artistId, 'Leonardo_da_Vinci_105.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_106.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Cabezas grotescas', artistId, 'Leonardo_da_Vinci_107.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Los Cuadernos de Da Vinci', artistId, 'Leonardo_da_Vinci_108.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Head of a Woman', artistId, 'Leonardo_da_Vinci_109.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('MuchoWow Textilposter Etruskische Grabhügel in Montecalvario bei Castellina in Chianti', artistId, 'Leonardo_da_Vinci_110.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Head of a Young Woman', artistId, 'Leonardo_da_Vinci_111.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study of an apostle''s head and architectural study', artistId, 'Leonardo_da_Vinci_112.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study sheet', artistId, 'Leonardo_da_Vinci_113.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('La última cena', artistId, 'Leonardo_da_Vinci_114.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('La última cena', artistId, 'Leonardo_da_Vinci_115.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('La última cena', artistId, 'Leonardo_da_Vinci_116.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('La última cena', artistId, 'Leonardo_da_Vinci_117.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_118.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('San Jerónimo', artistId, 'Leonardo_da_Vinci_119.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('La Virgen de las Rocas', artistId, 'Leonardo_da_Vinci_120.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Mona Lisa de Isleworth', artistId, 'Leonardo_da_Vinci_121.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('San Juan Bautista', artistId, 'Leonardo_da_Vinci_122.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('La Virgen, el Niño Jesús y Santa Ana', artistId, 'Leonardo_da_Vinci_123.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('San Juan Bautista', artistId, 'Leonardo_da_Vinci_124.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Landscape drawing for Santa Maria della Neve', artistId, 'Leonardo_da_Vinci_125.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('A seated man, and studies and notes on the movement of water', artistId, 'Leonardo_da_Vinci_126.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Adoración de los Magos', artistId, 'Leonardo_da_Vinci_127.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Bautismo de Cristo', artistId, 'Leonardo_da_Vinci_128.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Retrato de Ginebra de Benci', artistId, 'Leonardo_da_Vinci_129.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Wreath of Laurel, Palm, and Juniper with a Scroll inscribed Virtutem Forma Decorat [reverse]', artistId, 'Leonardo_da_Vinci_130.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Madonna Dreyfus', artistId, 'Leonardo_da_Vinci_131.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Virgen del clavel', artistId, 'Leonardo_da_Vinci_132.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_133.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Cabeza de muchacha', artistId, 'Leonardo_da_Vinci_134.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('La última cena', artistId, 'Leonardo_da_Vinci_135.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Madona Benois', artistId, 'Leonardo_da_Vinci_136.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_137.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Autorretrato', artistId, 'Leonardo_da_Vinci_138.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Allegory', artistId, 'Leonardo_da_Vinci_139.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Anatomical studies (larynx and leg)', artistId, 'Leonardo_da_Vinci_140.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Anatomical Drawings', artistId, 'Leonardo_da_Vinci_141.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Anatomical studies of the shoulder', artistId, 'Leonardo_da_Vinci_142.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Leonardo_da_Vinci_143.jpg');

  INSERT INTO artist (
    name,
    birth_year,
    death_year,
    genre,
    nationality,
    biourl
  ) VALUES (
    'Marc Chagall',
    1887,
    1985,
    'Primitivism',
    'French, Jewish, Belarusian',
    'http://en.wikipedia.org/wiki/Marc_Chagall'
  ) RETURNING id INTO artistId;

  RAISE NOTICE 'Inserting artworks of Marc Chagall';

  INSERT INTO artwork (title, artist_id, filename) VALUES ('Old Woman with a Ball of Yarn', artistId, 'Marc_Chagall_1.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Blue Lovers', artistId, 'Marc_Chagall_2.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_3.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('A Group of People', artistId, 'Marc_Chagall_4.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Old Man and Old Woman', artistId, 'Marc_Chagall_5.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The house on the forest edge', artistId, 'Marc_Chagall_6.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Strawberries. Bella and Ida at the Table', artistId, 'Marc_Chagall_7.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Marching', artistId, 'Marc_Chagall_8.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_9.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_10.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_11.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_12.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Barber''s Shop (Uncle Zusman)', artistId, 'Marc_Chagall_13.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_14.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('A Rooster', artistId, 'Marc_Chagall_15.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_16.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_17.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Fainting goat', artistId, 'Marc_Chagall_18.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Two Heads', artistId, 'Marc_Chagall_19.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_20.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_21.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Acrobat with Bouquet', artistId, 'Marc_Chagall_22.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_23.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Old Vitebsk', artistId, 'Marc_Chagall_24.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Uncle Mitiai - Uncle Miniai', artistId, 'Marc_Chagall_25.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('A House in Liozna', artistId, 'Marc_Chagall_26.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Selifan', artistId, 'Marc_Chagall_27.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_28.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_29.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_30.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_31.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Madame Korobotchka', artistId, 'Marc_Chagall_32.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_33.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Marc Chagall et Ambroise Vollard', artistId, 'Marc_Chagall_34.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Nozdriov', artistId, 'Marc_Chagall_35.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Apothecary in Vitebsk', artistId, 'Marc_Chagall_36.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The house painters', artistId, 'Marc_Chagall_37.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Nozdriov', artistId, 'Marc_Chagall_38.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Sobakevitch', artistId, 'Marc_Chagall_39.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Gathering of peasants', artistId, 'Marc_Chagall_40.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_41.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Sobakevitch', artistId, 'Marc_Chagall_42.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_43.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Sobakevitch', artistId, 'Marc_Chagall_44.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Portrait of Brother David with Mandolin', artistId, 'Marc_Chagall_45.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Madame Sobakevitch', artistId, 'Marc_Chagall_46.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Sobakevich at table', artistId, 'Marc_Chagall_47.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The over-flowing table', artistId, 'Marc_Chagall_48.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Tchitchikov and Sobakevich after dinner', artistId, 'Marc_Chagall_49.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_50.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Pliushkin''s village', artistId, 'Marc_Chagall_51.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Arlequins playing', artistId, 'Marc_Chagall_52.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Pliushkin treats Tchtchikov', artistId, 'Marc_Chagall_53.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_54.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_55.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Portrait of Sister Maryasinka', artistId, 'Marc_Chagall_56.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Disputation of Pliushkin and Mavra', artistId, 'Marc_Chagall_57.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Pliushkin treats Tchtchikov', artistId, 'Marc_Chagall_58.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_59.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('A man without passport with policeman', artistId, 'Marc_Chagall_60.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Banquet at the Police Chief''s House', artistId, 'Marc_Chagall_61.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Tchitchikov triumphant', artistId, 'Marc_Chagall_62.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Nozdryov and Tchitchikov', artistId, 'Marc_Chagall_63.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_64.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Marc Chagall', artistId, 'Marc_Chagall_65.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Revelations of Nozdryov', artistId, 'Marc_Chagall_66.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Red Jew', artistId, 'Marc_Chagall_67.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Banquet degenerates into brawl', artistId, 'Marc_Chagall_68.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Kopeikin and Napoléon', artistId, 'Marc_Chagall_69.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_70.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Chichikov shaves', artistId, 'Marc_Chagall_71.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Nozdryov and Tchitchikov', artistId, 'Marc_Chagall_72.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Selifan', artistId, 'Marc_Chagall_73.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Gogol and Chagall', artistId, 'Marc_Chagall_74.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_75.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Tchitchikov''s father educates him', artistId, 'Marc_Chagall_76.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_77.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Window Vitebsk', artistId, 'Marc_Chagall_78.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Gogol and Chagall', artistId, 'Marc_Chagall_79.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Self Portrait', artistId, 'Marc_Chagall_80.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_81.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_82.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Mesa de los pecados capitales', artistId, 'Marc_Chagall_83.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_84.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_85.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_86.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Yellow Rooster', artistId, 'Marc_Chagall_87.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('A jew by Marc Chagall', artistId, 'Marc_Chagall_88.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_89.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The blue bird', artistId, 'Marc_Chagall_90.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Couple and Fish', artistId, 'Marc_Chagall_91.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Lovers in the sky of Nice', artistId, 'Marc_Chagall_92.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_93.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Self Portrait', artistId, 'Marc_Chagall_94.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Profile and Red Child', artistId, 'Marc_Chagall_95.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_96.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Circus with the Yellow Clown', artistId, 'Marc_Chagall_97.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_98.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Starlit Circus', artistId, 'Marc_Chagall_99.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Small Drawing Room', artistId, 'Marc_Chagall_100.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Bella and Ida by the Window', artistId, 'Marc_Chagall_101.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Marc Chagall Acrobatics 12.5 x 9.5 Lithograph 1963 Modernism', artistId, 'Marc_Chagall_102.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Apparition at the Circus', artistId, 'Marc_Chagall_103.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Marc Chagall Payaso con flores 31 8cm x 24 1cm Litografía 1963 Hombre', artistId, 'Marc_Chagall_104.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('A blue cow', artistId, 'Marc_Chagall_105.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The heart of the circus', artistId, 'Marc_Chagall_106.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Marc Chagall The Wandering Musicians 31 8cm x 24 1cm Litografía 1957 Hombre', artistId, 'Marc_Chagall_107.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Itinerant players', artistId, 'Marc_Chagall_108.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Clown in Love', artistId, 'Marc_Chagall_109.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_110.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The clown musician', artistId, 'Marc_Chagall_111.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Lilies of the Valley', artistId, 'Marc_Chagall_112.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Branch and flute-player', artistId, 'Marc_Chagall_113.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Bouquet with hand', artistId, 'Marc_Chagall_114.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The two profiles', artistId, 'Marc_Chagall_115.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_116.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_117.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Still Life with Bouquet', artistId, 'Marc_Chagall_118.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_119.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_120.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Summer Evening', artistId, 'Marc_Chagall_121.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_122.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Strawberries. Bella and Ida at the Table', artistId, 'Marc_Chagall_123.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Lovers with bouquet under the trees', artistId, 'Marc_Chagall_124.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Painter and Model', artistId, 'Marc_Chagall_125.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Marc Chagall-Before the Picture-1963 Mourlot Lithograph', artistId, 'Marc_Chagall_126.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_127.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Lovers'' sky', artistId, 'Marc_Chagall_128.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_129.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_130.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_131.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('A Big Peasant', artistId, 'Marc_Chagall_132.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Peasant with bouquet', artistId, 'Marc_Chagall_133.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Bathing of a Baby', artistId, 'Marc_Chagall_134.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_135.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Little peasants', artistId, 'Marc_Chagall_136.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Couple of peasants', artistId, 'Marc_Chagall_137.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Nocturne at Vence', artistId, 'Marc_Chagall_138.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Sun over Saint-Paul de Vence', artistId, 'Marc_Chagall_139.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Blue Nymph', artistId, 'Marc_Chagall_140.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Drawing by Marc Chagall for Vladimir Mayakovsky''s 70th birthday', artistId, 'Marc_Chagall_141.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_142.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Drawing by Marc Chagall for Vladimir Mayakovsky''s 70th birthday', artistId, 'Marc_Chagall_143.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_144.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Lovers'' Heaven', artistId, 'Marc_Chagall_145.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_146.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Untitled (Flying fish)', artistId, 'Marc_Chagall_147.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Peasant with a Clock', artistId, 'Marc_Chagall_148.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_149.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Lovers for Berggruen (The offering)', artistId, 'Marc_Chagall_150.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The circus', artistId, 'Marc_Chagall_151.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_152.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_153.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Musicians on a green background', artistId, 'Marc_Chagall_154.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Peasant with a violin', artistId, 'Marc_Chagall_155.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Window over a Garden', artistId, 'Marc_Chagall_156.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The ''Antilopa'' Passengers', artistId, 'Marc_Chagall_157.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Flowers in front of window', artistId, 'Marc_Chagall_158.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Cemetery Gates', artistId, 'Marc_Chagall_159.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Grey Lovers', artistId, 'Marc_Chagall_160.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Promenade', artistId, 'Marc_Chagall_161.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Self Portrait with Muse (Dream)', artistId, 'Marc_Chagall_162.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Window Vitebsk', artistId, 'Marc_Chagall_163.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Self Portrait with Muse (Dream)', artistId, 'Marc_Chagall_164.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Summer House Backyard', artistId, 'Marc_Chagall_165.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Interior with Flowers', artistId, 'Marc_Chagall_166.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_167.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_168.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Blue Face', artistId, 'Marc_Chagall_169.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The bay', artistId, 'Marc_Chagall_170.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('View at Peira Cava', artistId, 'Marc_Chagall_171.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_172.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Bride with Blue Face', artistId, 'Marc_Chagall_173.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Birth', artistId, 'Marc_Chagall_174.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Hour between Wolf and Dog (Betwenn Darkness and Light)', artistId, 'Marc_Chagall_175.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Self Portrait with a Clock In front of Crucifixion', artistId, 'Marc_Chagall_176.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Lovers near Bridge', artistId, 'Marc_Chagall_177.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Clock with Blue Wing', artistId, 'Marc_Chagall_178.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_179.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Portrait of Vava', artistId, 'Marc_Chagall_180.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('On Two Banks', artistId, 'Marc_Chagall_181.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Newlyweds and Violinist', artistId, 'Marc_Chagall_182.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_183.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Artist at Easel', artistId, 'Marc_Chagall_184.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Mazin, the Poet', artistId, 'Marc_Chagall_185.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Cows over Vitebsk', artistId, 'Marc_Chagall_186.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Horsewoman on Red Horse', artistId, 'Marc_Chagall_187.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Portrait of Vava', artistId, 'Marc_Chagall_188.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Lunaria', artistId, 'Marc_Chagall_189.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Laid Table with View of Saint-Paul de Vance', artistId, 'Marc_Chagall_190.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Fisherman''s Family', artistId, 'Marc_Chagall_191.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_192.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('King David''s Tower', artistId, 'Marc_Chagall_193.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Artist and His Wife', artistId, 'Marc_Chagall_194.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Lovers over Sant Paul', artistId, 'Marc_Chagall_195.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Newspaper Seller', artistId, 'Marc_Chagall_196.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Artist and His Model', artistId, 'Marc_Chagall_197.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_198.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Jacob''s Dream', artistId, 'Marc_Chagall_199.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_200.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Song of Songs', artistId, 'Marc_Chagall_201.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Blue Village', artistId, 'Marc_Chagall_202.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Holy Family', artistId, 'Marc_Chagall_203.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Tree of Jesse', artistId, 'Marc_Chagall_204.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_205.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Dawn', artistId, 'Marc_Chagall_206.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Autoportrait au chevalet', artistId, 'Marc_Chagall_207.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Window in Artist''s Studio', artistId, 'Marc_Chagall_208.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The rest', artistId, 'Marc_Chagall_209.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Saint-Paul de Vance at Sunset', artistId, 'Marc_Chagall_210.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Angel over Vitebsk', artistId, 'Marc_Chagall_211.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Child with a Dove', artistId, 'Marc_Chagall_212.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Artist over Vitebsk', artistId, 'Marc_Chagall_213.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Child with a Dove', artistId, 'Marc_Chagall_214.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Artist and His Bride', artistId, 'Marc_Chagall_215.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Artist and His Bride', artistId, 'Marc_Chagall_216.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_217.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Clock', artistId, 'Marc_Chagall_218.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Artist''s Reminiscence', artistId, 'Marc_Chagall_219.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Self Portrait with Bouquet', artistId, 'Marc_Chagall_220.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Artist over Vitebsk', artistId, 'Marc_Chagall_221.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Self Portrait with Bouquet', artistId, 'Marc_Chagall_222.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_223.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Eiffel Tower', artistId, 'Marc_Chagall_224.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The circus', artistId, 'Marc_Chagall_225.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Butcher', artistId, 'Marc_Chagall_226.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Study for the painting Rain', artistId, 'Marc_Chagall_227.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Jewish Wedding', artistId, 'Marc_Chagall_228.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Green Lovers', artistId, 'Marc_Chagall_229.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_230.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Street in Vitebsk', artistId, 'Marc_Chagall_231.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Judío errante', artistId, 'Marc_Chagall_232.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Wounded Soldier', artistId, 'Marc_Chagall_233.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Man with a Cat and Woman with a Child', artistId, 'Marc_Chagall_234.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Judío errante', artistId, 'Marc_Chagall_235.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_236.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('On the stretcher (wounded soldier)', artistId, 'Marc_Chagall_237.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_238.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Marc_Chagall_239.jpg');

  INSERT INTO artist (
    name,
    birth_year,
    death_year,
    genre,
    nationality,
    biourl
  ) VALUES (
    'Michelangelo',
    1475,
    1564,
    'High Renaissance',
    'Italian',
    'https://en.wikipedia.org/wiki/Michelangelo'
  ) RETURNING id INTO artistId;

  RAISE NOTICE 'Inserting artworks of Michelangelo';

  INSERT INTO artwork (title, artist_id, filename) VALUES ('Bóveda de la Capilla Sixtina', artistId, 'Michelangelo_1.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Ignudo', artistId, 'Michelangelo_2.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Ignudo', artistId, 'Michelangelo_3.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('La creación de Adán', artistId, 'Michelangelo_4.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Bóveda de la Capilla Sixtina', artistId, 'Michelangelo_5.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Creación de Eva', artistId, 'Michelangelo_6.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Caída del Hombre, pecado original y expulsión del Paraíso', artistId, 'Michelangelo_7.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('El Diluvio Universal', artistId, 'Michelangelo_8.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Bóveda de la Capilla Sixtina', artistId, 'Michelangelo_9.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Creación de Eva', artistId, 'Michelangelo_10.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('El Sacrificio de Noé', artistId, 'Michelangelo_11.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Ignudo', artistId, 'Michelangelo_12.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Sibila Pérsica', artistId, 'Michelangelo_13.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Sistine Chapel: A New Vision', artistId, 'Michelangelo_14.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Jeremías', artistId, 'Michelangelo_15.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Ezequiel', artistId, 'Michelangelo_16.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Joel', artistId, 'Michelangelo_17.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Isaías', artistId, 'Michelangelo_18.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Ancestors of Christ', artistId, 'Michelangelo_19.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Michelangelo_20.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Ancestors of Christ', artistId, 'Michelangelo_21.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Ancestors of Christ: Manasseh, Amon', artistId, 'Michelangelo_22.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Jacob and Joseph', artistId, 'Michelangelo_23.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Ancestors of Christ: Salmon, Boaz, Obed', artistId, 'Michelangelo_24.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Ancestors of Christ: Salmon', artistId, 'Michelangelo_25.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Bóveda de la Capilla Sixtina', artistId, 'Michelangelo_26.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Bóveda de la Capilla Sixtina', artistId, 'Michelangelo_27.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Judith y Holofernes.', artistId, 'Michelangelo_28.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('David and Goliath', artistId, 'Michelangelo_29.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('David and Goliath', artistId, 'Michelangelo_30.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('El Juicio Final', artistId, 'Michelangelo_31.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('El Juicio Final', artistId, 'Michelangelo_32.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('El Juicio Final', artistId, 'Michelangelo_33.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('El Juicio Final', artistId, 'Michelangelo_34.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Michelangelo_35.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Michelangelo_36.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES (null, artistId, 'Michelangelo_37.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Tentación de san Antonio', artistId, 'Michelangelo_38.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Bóveda de la Capilla Sixtina', artistId, 'Michelangelo_39.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Madonna de Manchester', artistId, 'Michelangelo_40.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('The Dream of Human Life', artistId, 'Michelangelo_41.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Leda y el cisne', artistId, 'Michelangelo_42.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Santo Entierro', artistId, 'Michelangelo_43.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Tondo Doni', artistId, 'Michelangelo_44.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Sibila Délfica', artistId, 'Michelangelo_45.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Sibila Cumana', artistId, 'Michelangelo_46.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Sibila Líbica', artistId, 'Michelangelo_47.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('Sibila Eritrea', artistId, 'Michelangelo_48.jpg');
  INSERT INTO artwork (title, artist_id, filename) VALUES ('El Juicio Final', artistId, 'Michelangelo_49.jpg');

END;
$$
LANGUAGE PlPgSQL;
