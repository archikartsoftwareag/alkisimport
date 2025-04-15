SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

---
--- Nutzungen
--- 

SELECT alkis_dropobject('alkis_nutzungen');
CREATE TABLE alkis_nutzungen(
	name VARCHAR PRIMARY KEY,
	kennung VARCHAR,
	funktionsfeld VARCHAR,
	relationstext VARCHAR,
	elementtext VARCHAR,
	enumeration VARCHAR,
	attributname VARCHAR,
	attributfeld VARCHAR,
	attributname2 VARCHAR,
	attributfeld2 VARCHAR
);

INSERT INTO alkis_nutzungen(name, kennung, funktionsfeld, relationstext, elementtext, enumeration, attributname, attributfeld, attributname2, attributfeld2) VALUES
	('ax_bahnverkehr', '42010', 'funktion', ', ', 'Bahnverkehr', 'ax_funktion_bahnverkehr', 'Bezeichnung', 'coalesce(unverschluesselt,land || regierungsbezirk || kreis || gemeinde || lage)', 'Bahnkategorie', 'translate(bahnkategorie::text,''{}'','''')'),
	('ax_bergbaubetrieb', '41004', 'abbaugut', ' von ', 'Bergbaubetrieb', 'ax_abbaugut_bergbaubetrieb', 'Name', 'name', NULL, NULL),
	('ax_flaechebesondererfunktionalerpraegung', '41007', 'funktion', ', ', 'Fläche besonderer funktionaler Prägung', 'ax_funktion_flaechebesondererfunktionalerpraegung', 'Name', 'name', NULL, NULL),
	('ax_flaechegemischternutzung', '41006', 'funktion', ', ', 'Fläche gemischter Nutzung', 'ax_funktion_flaechegemischternutzung', 'Name', 'name', NULL, NULL),
	('ax_fliessgewaesser', '44001', 'funktion', ', ', 'Fließgewässer', 'ax_funktion_fliessgewaesser', 'Name', 'coalesce(unverschluesselt,land || regierungsbezirk || kreis || gemeinde || lage)', NULL, NULL),
	('ax_flugverkehr', '42015', 'funktion', ', ', 'Flugverkehr', 'ax_funktion_flugverkehr', 'Name', 'coalesce(unverschluesselt,land || regierungsbezirk || kreis || gemeinde || lage)', 'Art', 'art'),
	('ax_friedhof', '41009', 'funktion', ', ', 'Friedhof', 'ax_funktion_friedhof', 'Name', 'name', NULL, NULL),
	('ax_gehoelz', '43003', 'funktion', ', ', 'Gehölz', 'ax_funktion_gehoelz', 'Name', 'name', NULL, NULL),
	('ax_hafenbecken', '44005', 'funktion', ', ', 'Hafenbecken', 'ax_funktion_hafenbecken', 'Name', 'coalesce(unverschluesselt,land || regierungsbezirk || kreis || gemeinde || lage)', NULL, NULL),
	('ax_halde', '41003', 'lagergut', ', ', 'Halde', 'ax_lagergut_halde', 'Name', 'name', NULL, NULL),
	('ax_heide', '43004', 'NULL', '', 'Heide', NULL, NULL, NULL, NULL, NULL),
	('ax_industrieundgewerbeflaeche', '41002', 'funktion', ', ', 'Industrie- und Gewerbefläche', 'ax_funktion_industrieundgewerbeflaeche', 'Name', 'name', NULL, NULL),
	('ax_landwirtschaft', '43001', 'vegetationsmerkmal', ', ', 'Landwirtschaft', 'ax_vegetationsmerkmal_landwirtschaft', 'Name', 'name', NULL, NULL),
	('ax_meer', '44007', 'funktion', ', ', 'Meer', 'ax_funktion_meer', 'Name', 'coalesce(unverschluesselt,land || regierungsbezirk || kreis || gemeinde || lage)', NULL, NULL),
	('ax_moor', '43005', 'NULL','', 'Moor', NULL, NULL, NULL, NULL, NULL),
	('ax_platz', '42009', 'funktion', ', ', 'Platz', 'ax_funktion_platz', 'Name', 'coalesce(unverschluesselt,land || regierungsbezirk || kreis || gemeinde || lage)', NULL, NULL),
	('ax_schiffsverkehr', '42016', 'funktion', ', ', 'Schiffsverkehr', 'ax_funktion_schiffsverkehr', 'Name', 'coalesce(unverschluesselt,land || regierungsbezirk || kreis || gemeinde || lage)', NULL, NULL),
	('ax_sportfreizeitunderholungsflaeche', '41008', 'funktion', ', ', 'Sport-, Freizeit- und Erholungsfläche', 'ax_funktion_sportfreizeitunderholungsflaeche', 'Name', 'name', NULL, NULL),
	('ax_stehendesgewaesser', '44006', 'funktion', ', ', 'Stehendes Gewässer', 'ax_funktion_stehendesgewaesser', 'Name', 'coalesce(unverschluesselt,land || regierungsbezirk || kreis || gemeinde || lage)', NULL, NULL),
	('ax_strassenverkehr', '42001', 'funktion', ', ', 'Straßenverkehr', 'ax_funktion_strasse', 'Name', 'coalesce(unverschluesselt,land || regierungsbezirk || kreis || gemeinde || lage)', NULL, NULL),
	('ax_sumpf', '43006', 'NULL', '', 'Sumpf', NULL, NULL, NULL, NULL, NULL),
	('ax_tagebaugrubesteinbruch', '41005', 'abbaugut', ' von ', 'Tagebau, Grube, Steinbruch', 'ax_abbaugut_tagebaugrubesteinbruch', 'Name', 'name', NULL, NULL),
	('ax_unlandvegetationsloseflaeche', '43007', 'funktion', ', ', 'Unland, vegetationslose Fläche', 'ax_funktion_unlandvegetationsloseflaeche', 'Name', 'name', 'Oberflächenmaterial', 'oberflaechenmaterial'),
	('ax_wald', '43002', 'vegetationsmerkmal', ', ', 'Wald', 'ax_vegetationsmerkmal_wald', 'Name', 'name', NULL, NULL),
	('ax_weg', '42006', 'funktion', ', ', 'Weg', 'ax_funktion_weg', 'Name', 'coalesce(unverschluesselt,land || regierungsbezirk || kreis || gemeinde || lage)', NULL, NULL),
	('ax_wohnbauflaeche', '41001', 'artderbebauung', ' mit Art der Bebauung ', 'Wohnbaufläche', 'ax_artderbebauung_wohnbauflaeche', 'Name', 'name', NULL, NULL);

SELECT alkis_dropobject('alkis_createnutzung');
CREATE OR REPLACE FUNCTION pg_temp.alkis_createnutzung() RETURNS varchar AS $$
DECLARE
	r  RECORD;
	nv VARCHAR;
	kv VARCHAR;
	d  VARCHAR;
	i  INTEGER;
	res VARCHAR;
	invalid INTEGER;
BEGIN
	nv := E'CREATE VIEW ax_tatsaechlichenutzung AS\n  ';
	kv := E'CREATE VIEW ax_tatsaechlichenutzungsschluessel AS\n  ';
	d := '';

	i := 0;
	FOR r IN
		SELECT
			name,
			kennung,
			funktionsfeld,
			relationstext,
			elementtext,
			enumeration,
			attributname,
			attributfeld,
			attributname2,
			attributfeld2
		FROM alkis_nutzungen
	LOOP
		res := alkis_string_append(res, alkis_fixareas(r.name));

		nv := nv
		   || d
		   || 'SELECT '
		   || 'ogc_fid*32+' || i ||' AS ogc_fid, '
		   || '''' || r.name || '''::text AS name, '
		   || 'gml_id, '
		   || alkis_toint(r.kennung) || ' AS kennung, '
		   || r.funktionsfeld  || '::text AS funktion, '
		   || '''' || r.kennung || ''' ||coalesce('':'' || ' || r.funktionsfeld || ','''')::text AS nutzung, '
		   || coalesce('''' || r.attributname || '''','NULL') || '::text AS attributname, '
		   || coalesce(r.attributfeld,'NULL') || '::text AS attributwert, '
		   || coalesce('''' || r.attributname2 || '''','NULL') || '::text AS attributname2, '
		   || coalesce(r.attributfeld2,'NULL') || '::text AS attributwert2, '
		   || 'beginnt, '
		   || 'wkb_geometry'
		   || ' FROM ' || r.name
		   || ' WHERE endet IS NULL AND hatdirektunten IS NULL AND istweiterenutzung IS NULL'
		   ;

		kv := kv
		   || d
		   || 'SELECT ''' || r.kennung || ''' AS nutzung,''' || r.elementtext ||''' AS name'
		   ;

		IF r.funktionsfeld<>'NULL' THEN
			kv := kv
			   || ' UNION SELECT ''' || r.kennung || ':''|| wert AS nutzung,'''
			   || coalesce(r.elementtext,'') || coalesce(r.relationstext,'') || '''|| beschreibung AS name'
			   || ' FROM ' || r.enumeration
			   ;
		END IF;

		d := E' UNION ALL\n  ';
		i := i + 1;
	END LOOP;

	PERFORM alkis_dropobject('ax_tatsaechlichenutzung');
	EXECUTE nv;

	PERFORM alkis_dropobject('ax_tatsaechlichenutzungsschluessel');
	EXECUTE kv;

	RETURN alkis_string_append(res, 'ax_tatsaechlichenutzung und ax_tatsaechlichenutzungsschluessel erzeugt.');
END;
$$ LANGUAGE plpgsql;

SELECT 'Erzeuge Sicht für Nutzungen...';
SELECT pg_temp.alkis_createnutzung();

DELETE FROM nutz_shl;
INSERT INTO nutz_shl(nutzshl,nutzung)
  SELECT nutzung,name FROM ax_tatsaechlichenutzungsschluessel;

SELECT 'Bestimme Flurstücksnutzungen...';

SELECT alkis_dropobject('nutz_shl_pk_seq');
CREATE SEQUENCE nutz_shl_pk_seq;

DELETE FROM nutz_21;
INSERT INTO nutz_21(flsnr,pk,nutzsl,gemfl,umfang,fl,ff_entst,ff_stand,typ_name,nutz_gml_id,fs_gml_id)
  SELECT
    alkis_flsnr(f) AS flsnr,
    to_hex(nextval('nutz_shl_pk_seq'::regclass)) AS pk,
    n.nutzung AS nutzsl,
     sum(st_area(alkis_intersection(f.wkb_geometry,n.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||n.name||':'||n.gml_id))) AS gemfl,
     sum(st_perimeter2d(alkis_intersection(f.wkb_geometry,n.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||n.name||':'||n.gml_id))) AS umfang,
    (sum(st_area(alkis_intersection(f.wkb_geometry,n.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||n.name||':'||n.gml_id))*amtlicheflaeche/NULLIF(st_area(f.wkb_geometry),0)))::int AS fl,
    0 AS ff_entst,
    0 AS ff_stand,
    n.name AS typ_name,
    n.gml_id AS nutz_gml_id,
    f.gml_id AS fs_gml_id
  FROM ax_flurstueck f
  JOIN ax_tatsaechlichenutzung n
      ON f.wkb_geometry && n.wkb_geometry
      AND alkis_relate(f.wkb_geometry,n.wkb_geometry,'2********','ax_flurstueck:'||f.gml_id||'<=>'||n.name||':'||n.gml_id)
  WHERE f.endet IS NULL
  GROUP BY alkis_flsnr(f), f.wkb_geometry, n.nutzung, n.gml_id, f.gml_id, n.name;
