/****************************************
 * Schema                               *
 ****************************************/

-- Conectarse a la base de datos
\c trabajo_final_gad;

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
  filepath varchar(512) not null,
  pattern pattern,
  fhqt_leaf_id integer REFERENCES fhqt(id)
);

-- Crear tabla para los pivotes
CREATE TABLE pivot (
  level integer not null primary key,
  pattern pattern not null
);

CREATE TYPE similaritysearchresultitem AS (
  distance real,
  dicrete_distance_level int,
  proportional_distance real,
  similarity real,
  percentage_similarity real,
  artwork artwork,
  artist artist
);

CREATE TYPE getpivotsitem AS (
  pattern pattern,
  efficiency real
);
