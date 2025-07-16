SET search_path = :"alkis_schema", :"postgis_schema", public;

ALTER TABLE klas_3x
	ADD IF NOT EXISTS klas_endet character(20);

CREATE INDEX IF NOT EXISTS klas_3x_idx5 ON klas_3x (klas_endet);

ALTER TABLE nutz_21
	ADD IF NOT EXISTS nutz_endet character(20);

CREATE INDEX IF NOT EXISTS nutz_21_idx5 ON nutz_21 (nutz_endet);
