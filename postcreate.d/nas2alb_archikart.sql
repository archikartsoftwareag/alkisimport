SET search_path = :"alkis_schema", :"postgis_schema", public;

ALTER TABLE klas_3x
	ADD IF NOT EXISTS umfang double precision,
	ADD IF NOT EXISTS typ_name varchar,
	ADD IF NOT EXISTS klas_gml_id character(16),
	ADD IF NOT EXISTS fs_gml_id character(16),
	ADD IF NOT EXISTS klas_endet character(20);

SELECT alkis_dropobject('klas_3x_idx3');
SELECT alkis_dropobject('klas_3x_idx4');
SELECT alkis_dropobject('klas_3x_idx5');
CREATE INDEX IF NOT EXISTS klas_3x_idx_ak_1 ON klas_3x (klas_gml_id);
CREATE INDEX IF NOT EXISTS klas_3x_idx_ak_2 ON klas_3x (fs_gml_id);
CREATE INDEX IF NOT EXISTS klas_3x_idx_ak_3 ON klas_3x (klas_endet);

ALTER TABLE nutz_21
	ADD IF NOT EXISTS umfang double precision,
	ADD IF NOT EXISTS typ_name varchar,
	ADD IF NOT EXISTS nutz_gml_id character(16),
	ADD IF NOT EXISTS fs_gml_id character(16),
	ADD IF NOT EXISTS nutz_endet character(20);

SELECT alkis_dropobject('nutz_21_idx3');
SELECT alkis_dropobject('nutz_21_idx4');
SELECT alkis_dropobject('nutz_21_idx5');
CREATE INDEX IF NOT EXISTS nutz_21_idx_ak_1 ON nutz_21 (nutz_gml_id);
CREATE INDEX IF NOT EXISTS nutz_21_idx_ak_2 ON nutz_21 (fs_gml_id);
CREATE INDEX IF NOT EXISTS nutz_21_idx_ak_3 ON nutz_21 (nutz_endet);
