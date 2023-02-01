-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION imagecomparer" to load this file. \quit

CREATE FUNCTION pattern_in(cstring)
RETURNS pattern
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION pattern_out(pattern)
RETURNS cstring
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE TYPE pattern (
	INTERNALLENGTH = -1,
	INPUT = pattern_in,
	OUTPUT = pattern_out,
	STORAGE = extended
);

CREATE FUNCTION image2pattern(bytea)
RETURNS pattern
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION pattern2image(pattern)
RETURNS bytea
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION max_pattern_distance()
RETURNS float4
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION pattern_distance(pattern, pattern)
RETURNS float4
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR <-> (
	LEFTARG = pattern,
	RIGHTARG = pattern,
	FUNCTION = pattern_distance
);

CREATE FUNCTION pattern_proportional_distance(pattern, pattern)
RETURNS float4 AS
$$
    SELECT ($1 <-> $2) / max_pattern_distance()
$$
LANGUAGE SQL IMMUTABLE STRICT;

CREATE OPERATOR </> (
	LEFTARG = pattern,
	RIGHTARG = pattern,
	FUNCTION = pattern_proportional_distance
);

CREATE FUNCTION pattern_similarity(pattern, pattern)
RETURNS float4 AS
$$
    SELECT 1 - ($1 </> $2)
$$
LANGUAGE SQL IMMUTABLE STRICT;

CREATE OPERATOR <=> (
	LEFTARG = pattern,
	RIGHTARG = pattern,
	FUNCTION = pattern_similarity
);

CREATE FUNCTION pattern_percentage_similarity(pattern, pattern)
RETURNS float4 AS
$$
    SELECT round(CAST((($1 <=> $2) * 100) as numeric), 2)
$$
LANGUAGE SQL IMMUTABLE STRICT;

CREATE OPERATOR <%> (
	LEFTARG = pattern,
	RIGHTARG = pattern,
	FUNCTION = pattern_percentage_similarity
);
