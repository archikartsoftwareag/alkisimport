SET search_path = :"alkis_schema", :"postgis_schema", public;

SELECT alkis_dropobject('klas_3x');
CREATE TABLE klas_3x (
	flsnr character(21),
	pk character(8) NOT NULL,
	klf character(32),
	fl character(16),
	gemfl double precision,
	umfang double precision,
	klz character(10),
	wertz1 character(10),
	wertz2 character(10),
	bem character(5),
	unf_anm character(20),
	ff_entst integer,
	ff_stand integer,
	typ_name varchar,
	klas_gml_id character(16),
	klas_endet character(20),
	fs_gml_id character(16),
	primary key (pk)
);
COMMENT ON TABLE klas_3x IS 'BASE: Klassifizierungen';

CREATE INDEX klas_3x_idx1 ON klas_3x(flsnr);
CREATE INDEX klas_3x_idx2 ON klas_3x(klf);
CREATE INDEX klas_3x_idx3 ON klas_3x(klas_gml_id);
CREATE INDEX klas_3x_idx4 ON klas_3x(klas_endet);
CREATE INDEX klas_3x_idx5 ON klas_3x(fs_gml_id);

SELECT alkis_dropobject('nutz_21');
CREATE TABLE nutz_21 (
	flsnr varchar,
	pk character(8) NOT NULL,
	nutzsl character(32),
	fl character(16),
	gemfl double precision,
	umfang double precision,
	ff_entst INTEGER,
	ff_stand INTEGER,
	typ_name varchar,
	nutz_gml_id character(16),
	nutz_endet character(20),
	fs_gml_id character(16),
	primary key (pk)
);
COMMENT ON TABLE nutz_21 IS 'BASE: Nutzungen';

CREATE INDEX nutz_21_idx1 ON nutz_21(flsnr);
CREATE INDEX nutz_21_idx2 ON nutz_21(nutzsl);
CREATE INDEX nutz_21_idx3 ON nutz_21(nutz_gml_id);
CREATE INDEX nutz_21_idx4 ON nutz_21(nutz_endet);
CREATE INDEX nutz_21_idx5 ON nutz_21(fs_gml_id);
