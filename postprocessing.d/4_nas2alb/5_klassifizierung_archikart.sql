SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

---
--- Klassifizierungen
---

SELECT alkis_dropobject('alkis_klassifizierungen');
CREATE TABLE alkis_klassifizierungen(
	name VARCHAR PRIMARY KEY,
	kennung VARCHAR,
	funktionsfeld VARCHAR,
	prefix VARCHAR,
	ackerzahl VARCHAR,
	bodenzahl VARCHAR,
	enumeration VARCHAR,
	bodenklasse VARCHAR,
	entstehungsart VARCHAR,
	sonstigeangaben VARCHAR,
	zustandsstufe VARCHAR,
	infofeld1 VARCHAR,
	infofeld2 VARCHAR
);

INSERT INTO alkis_klassifizierungen(
name, kennung, prefix, funktionsfeld, bodenzahl, ackerzahl, enumeration, 
bodenklasse, entstehungsart, sonstigeangaben, zustandsstufe, 
infofeld1, infofeld2) 
VALUES
('ax_bodenschaetzung', '72001', 'b', 'bodenart', 'bodenzahlodergruenlandgrundzahl', 'ackerzahlodergruenlandzahl', 'ax_nutzungsart_bodenschaetzung',
 'bodenart', 'translate(entstehungsart::text,''{}'','''')', 'translate(sonstigeangaben::text,''{}'','''')', 'zustandsstufe',
 'NULL::varchar', 'NULL::varchar'),
('ax_musterundvergleichsstueck', '72002', 'm', 'bodenart', 'bodenzahlodergruenlandgrundzahl', 'ackerzahlodergruenlandzahl', 'ax_nutzungsart_musterundvergleichsstueck',
 'bodenart', 'translate(entstehungsart::text,''{}'','''')', 'translate(sonstigeangaben::text,''{}'','''')', 'zustandsstufe',
 'NULL::varchar', 'NULL::varchar'),
('ax_bewertung', '72004', 'B', 'klassifizierung', 'NULL::varchar', 'NULL::varchar', 'ax_klassifizierung_bewertung',
 'NULL::integer', 'NULL::integer[]', 'NULL::integer[]', 'NULL::integer',
 'NULL::varchar', 'NULL::varchar'),
('ax_klassifizierungnachwasserrecht', '71003', 'W', 'artderfestlegung', 'NULL::varchar', 'NULL::varchar', 'ax_artderfestlegung_klassifizierungnachwasserrecht',
 'NULL::integer', 'NULL::integer[]', 'NULL::integer[]', 'NULL::integer',
 'coalesce(land || stelle)', 'bezeichnung'),
('ax_anderefestlegungnachwasserrecht', '71004', 'W1', 'artderfestlegung', 'NULL::varchar', 'NULL::varchar', 'ax_artderfestlegung_anderefestlegungnachwasserrecht',
 'NULL::integer', 'NULL::integer[]', 'NULL::integer[]', 'NULL::integer',
 'coalesce(land || stelle)', 'nummer'),
('ax_klassifizierungnachstrassenrecht', '71001', 'S', 'artderfestlegung', 'NULL::varchar', 'NULL::varchar', 'ax_artderfestlegung_klassifizierungnachstrassenrecht',
 'NULL::integer', 'NULL::integer[]', 'NULL::integer[]', 'NULL::integer',
 'coalesce(land || stelle)', 'bezeichnung'),
('ax_anderefestlegungnachstrassenrecht', '71002', 'S1', 'artderfestlegung', 'NULL::varchar', 'NULL::varchar', 'ax_artderfestlegung_anderefestlegungnachstrassenrecht',
 'NULL::integer', 'NULL::integer[]', 'NULL::integer[]', 'NULL::integer',
 'coalesce(land || stelle)', 'nummer'),
('ax_naturumweltoderbodenschutzrecht', '71006', 'BS', 'artderfestlegung', 'NULL::varchar', 'NULL::varchar', 'ax_artderfestlegung_naturumweltoderbodenschutzrecht',
 'NULL::integer', 'NULL::integer[]', 'NULL::integer[]', 'NULL::integer',
 'coalesce(land || stelle)', 'name'),
('ax_bauraumoderbodenordnungsrecht', '71008', 'BO', 'artderfestlegung', 'NULL::varchar', 'NULL::varchar', 'ax_artderfestlegung_bauraumoderbodenordnungsrecht',
 'NULL::integer', 'NULL::integer[]', 'NULL::integer[]', 'NULL::integer',
 'coalesce(land || stelle)', 'nullif(concat_ws(''; '',''Name: '' || name, ''Bezeichnung: '' || bezeichnung, ''Datum: '' || datumrechtskraeftig),'''')'),
('ax_denkmalschutzrecht', '71009', 'DS', 'artderfestlegung', 'NULL::varchar', 'NULL::varchar', 'ax_artderfestlegung_denkmalschutzrecht',
 'NULL::integer', 'NULL::integer[]', 'NULL::integer[]', 'NULL::integer',
 'coalesce(land || stelle)', 'bezeichnung'),
('ax_forstrecht', '71010', 'F', 'artderfestlegung', 'NULL::varchar', 'NULL::varchar','ax_artderfestlegung_forstrecht',
 'NULL::integer', 'NULL::integer[]', 'NULL::integer[]', 'NULL::integer',
 'coalesce(land || stelle)', 'bezeichnung'),
('ax_sonstigesrecht', '71011', 'SO', 'artderfestlegung', 'NULL::varchar', 'NULL::varchar', 'ax_artderfestlegung_sonstigesrecht',
 'NULL::integer', 'NULL::integer[]', 'NULL::integer[]', 'NULL::integer',
 'coalesce(land || stelle)', 'name');

SELECT alkis_dropobject('alkis_createklassifizierung');
CREATE FUNCTION pg_temp.alkis_createklassifizierung() RETURNS varchar AS $$
DECLARE
	r  RECORD;
	nv VARCHAR;
	kv VARCHAR;
	d  VARCHAR;
	i  INTEGER;
	res VARCHAR;
	invalid INTEGER;
BEGIN
	nv := E'CREATE VIEW ax_klassifizierung AS\n  ';
	kv := E'CREATE VIEW ax_klassifizierungsschluessel AS\n  ';
	d := '';

	i := 0;
	FOR r IN
		SELECT
			name,
			kennung,
			funktionsfeld,
			prefix,
			bodenzahl,
			ackerzahl,
			enumeration,
			bodenklasse,
			entstehungsart,
			sonstigeangaben,
			zustandsstufe,
			infofeld1,
			infofeld2
		FROM alkis_klassifizierungen
	LOOP
		res := alkis_string_append(res, alkis_fixareas(r.name));

		nv := nv
		   || d
		   || 'SELECT '
		   || 'ogc_fid*32+' || i || ' AS ogc_fid, '
		   || '''' || r.name    || '''::text AS name, '
		   || 'gml_id, '
		   || alkis_toint(r.kennung) || ' AS kennung, '
		   || r.funktionsfeld || ' AS artderfestlegung, '
		   || r.bodenzahl || ' AS bodenzahl, '
		   || r.ackerzahl || ' AS ackerzahl, '
		   || '''' || r.prefix || ':'' || ' || r.funktionsfeld || ' AS klassifizierung, '
		   || r.bodenklasse || ' AS bodenklasse, '
		   || r.entstehungsart || '::text AS entstehungsart, '
		   || r.sonstigeangaben || '::text AS sonstigeangaben, '
		   || r.zustandsstufe || ' AS zustandsstufe, '
		   || r.infofeld1 || ' AS infofeld1, '
		   || r.infofeld2 || ' AS infofeld2, '
		   || 'beginnt, '
		   || 'wkb_geometry'
		   || ' FROM ' || r.name
		   || ' WHERE endet IS NULL'
		   ;

		IF r.enumeration IS NOT NULL THEN
			kv := kv
			   || d
			   || 'SELECT '
			   || '''' || r.prefix || ':''|| wert AS klassifizierung, beschreibung AS name'
			   || '  FROM ' || r.enumeration
			   ;
		END IF;

		d := E' UNION\n  ';
		i := i + 1;
	END LOOP;

	PERFORM alkis_dropobject('ax_klassifizierung');
	EXECUTE nv;

	PERFORM alkis_dropobject('ax_klassifizierungsschluessel');
	EXECUTE kv;

	RETURN alkis_string_append(res, 'ax_klassifizierung und ax_klassifizierungsschluessel erzeugt.');
END;
$$ LANGUAGE plpgsql;

SELECT 'Erzeuge Sicht für Klassifizierungen...';
SELECT pg_temp.alkis_createklassifizierung();

DELETE FROM kls_shl;
INSERT INTO kls_shl(klf,klf_text)
  SELECT klassifizierung,name FROM ax_klassifizierungsschluessel;

SELECT 'Bestimme Flurstücksklassifizierungen...';

SELECT alkis_dropobject('klas_3x_pk_seq');
CREATE SEQUENCE klas_3x_pk_seq;

UPDATE ax_bodenschaetzung SET bodenzahlodergruenlandgrundzahl=NULL WHERE bodenzahlodergruenlandgrundzahl IN ('nicht belegt','');

DELETE FROM klas_3x;
INSERT INTO klas_3x(flsnr,pk,klf,wertz1,wertz2,gemfl,umfang,fl,ff_entst,ff_stand,typ_name,klas_gml_id,fs_gml_id)
  SELECT
    alkis_flsnr(f) AS flsnr,
    to_hex(nextval('klas_3x_pk_seq'::regclass)) AS pk,
    k.klassifizierung AS klf,
    k.bodenzahl,
    k.ackerzahl,
     sum(st_area(alkis_intersection(f.wkb_geometry,k.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||k.name||':'||k.gml_id))) AS gemfl,
     sum(st_perimeter2d(alkis_intersection(f.wkb_geometry,k.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||k.name||':'||k.gml_id))) AS umfang,
    (sum(st_area(alkis_intersection(f.wkb_geometry,k.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||k.name||':'||k.gml_id)))*amtlicheflaeche/NULLIF(st_area(f.wkb_geometry),0))::int AS fl,
    0 AS ff_entst,
    0 AS ff_stand,
    k.name AS typ_name,
    k.gml_id AS klas_gml_id,
    f.gml_id AS fs_gml_id
  FROM ax_flurstueck f
  JOIN ax_klassifizierung k
      ON f.wkb_geometry && k.wkb_geometry
      AND alkis_relate(f.wkb_geometry,k.wkb_geometry,'2********','ax_flurstueck:'||f.gml_id||'<=>'||k.name||':'||k.gml_id)
  WHERE f.endet IS NULL
  GROUP BY alkis_flsnr(f), f.amtlicheflaeche, f.wkb_geometry, k.klassifizierung, k.bodenzahl, k.ackerzahl, k.gml_id, f.gml_id, k.name;
