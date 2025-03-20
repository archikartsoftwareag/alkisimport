SET search_path = :"alkis_schema", public;

SELECT alkis_dropobject('ak_fs_fuellfl_umfang_klass');
CREATE TABLE ak_fs_fuellfl_umfang_klass (
	fs_gml_id character(16),
	fuellfl_umfang double precision,
        wkb_geometry geometry,	
	primary key (fs_gml_id)
);
COMMENT ON TABLE ak_fs_fuellfl_umfang_klass IS 'ARCHIKART: Füllflächenumfang Flurstücke - K0003AXAbschnittKF';
CREATE INDEX ak_fs_fuellfl_umfang_klass_idx1 ON ak_fs_fuellfl_umfang_klass(fs_gml_id);

SELECT alkis_dropobject('ak_fs_fuellfl_umfang_nutz_klass');
CREATE TABLE ak_fs_fuellfl_umfang_nutz_klass (
	fs_gml_id character(16),
	fuellfl_umfang double precision,
        wkb_geometry geometry,	
	primary key (fs_gml_id)
);
COMMENT ON TABLE ak_fs_fuellfl_umfang_nutz_klass IS 'ARCHIKART: Füllflächenumfang Flurstücke - K0003AXAbschnittNK';
CREATE INDEX ak_fs_fuellfl_umfang_nutz_klass_idx1 ON ak_fs_fuellfl_umfang_klass(fs_gml_id);

SELECT alkis_dropobject('ak_fs_fuellfl_umfang_nutz');
CREATE TABLE ak_fs_fuellfl_umfang_nutz(
	fs_gml_id character(16),
	fuellfl_umfang double precision,
        wkb_geometry geometry,		
	primary key (fs_gml_id)
);
COMMENT ON TABLE ak_fs_fuellfl_umfang_nutz IS 'ARCHIKART: Füllflächenumfang Flurstücke - K0003AXAbschnitt';
CREATE INDEX ak_fs_fuellfl_umfang_nutz_idx1 ON ak_fs_fuellfl_umfang_nutz(fs_gml_id);

DROP TABLE IF EXISTS alkis_options;
CREATE TABLE alkis_options (
	id serial NOT NULL,
	name varchar NOT NULL,
	value varchar NOT NULL,
	PRIMARY KEY (id)
);
CREATE INDEX idx_alkis_options_name 
ON alkis_options (name);

DROP TABLE IF EXISTS alkis_komplettupdate;
CREATE TABLE alkis_komplettupdate (
	id serial NOT NULL,
	typename varchar NOT NULL,
	featureid character(16) NOT NULL,
	PRIMARY KEY (id)
);
CREATE INDEX idx_alkis_komplettupdate_typename 
ON alkis_komplettupdate (typename);
CREATE INDEX idx_alkis_komplettupdate_featureid 
ON alkis_komplettupdate (featureid);

DROP TABLE IF EXISTS alkis_insert;
CREATE TABLE alkis_insert (
	id serial NOT NULL,
	typename varchar NOT NULL,
	featureid character(16) NOT NULL,
	PRIMARY KEY (id)
);
CREATE INDEX idx_alkis_insert_typename 
ON alkis_insert (typename);
CREATE INDEX idx_alkis_insert_featureid 
ON alkis_insert (featureid);

DROP TABLE IF EXISTS ak_object_not_found;
CREATE TABLE ak_object_not_found (
	id serial NOT NULL,
	typename varchar NOT NULL,
	featureid character(16) NOT NULL,
	PRIMARY KEY (id)
);

CREATE OR REPLACE function alkis_fs_fuellfl_geom(fs_id varchar, join_table varchar) RETURNS geometry
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  fs_ff_geom geometry;
BEGIN
  EXECUTE format('SELECT wkb_geometry
                  FROM %I
                  WHERE fs_gml_id = %L',
                 join_table,fs_id)
  INTO fs_ff_geom;
  
  RETURN fs_ff_geom;
END;
$$ SET search_path TO archikart, public;

CREATE OR REPLACE function alkis_fs_ab_geom(fs_id varchar, ab_id varchar, join_table varchar) RETURNS geometry
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  ab_geom geometry;
BEGIN
  EXECUTE format('SELECT st_intersection(f.wkb_geometry,j.wkb_geometry)
                  FROM ax_flurstueck f,
                  %I j
                  WHERE f.endet IS NULL
                  AND f.gml_id = %L
                  AND j.gml_id = %L',
                 join_table,fs_id,ab_id)
  INTO ab_geom;
  
  RETURN ab_geom;
END;
$$ SET search_path TO archikart, public;

CREATE OR REPLACE function alkis_buffer_test(geom geometry, buffer_offset float) RETURNS boolean
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  is_empty boolean;
BEGIN
  SELECT st_isempty(st_buffer(geom,-buffer_offset))
  INTO is_empty;
  
  RETURN is_empty;
END;
$$ SET search_path TO archikart, public;

CREATE OR REPLACE function alkis_fs_fuellfl_buffer_test(fs_id varchar, join_table varchar, buffer_offset float) RETURNS boolean
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  is_empty boolean;
BEGIN
  EXECUTE format('SELECT alkis_buffer_test(alkis_fs_fuellfl_geom(%L,%L),%s)',
                 fs_id,join_table,buffer_offset)
  INTO is_empty;
  
  RETURN is_empty;
END;
$$ SET search_path TO archikart, public;

CREATE OR REPLACE function alkis_fs_ab_buffer_test(fs_id varchar, ab_id varchar, join_table varchar, buffer_offset float) RETURNS boolean
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  is_empty boolean;
BEGIN
  EXECUTE format('SELECT alkis_buffer_test(alkis_fs_ab_geom(%L,%L,%L),%s)',
                 fs_id,ab_id,join_table,buffer_offset)
  INTO is_empty;
  
  RETURN is_empty;
END;
$$ SET search_path TO archikart, public;
