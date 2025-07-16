SET search_path = :"alkis_schema", public;

SELECT 'Erzeuge Sicht für historische Flurstücke...';

SELECT alkis_dropobject('ak_fs_hist');
CREATE VIEW ak_fs_hist AS 
	SELECT a.gml_id, a.beginnt, a.endet
	FROM ax_flurstueck a
	LEFT JOIN ax_flurstueck b ON b.gml_id = a.gml_id AND b.endet IS NULL
	INNER JOIN alkis_insert c ON c.featureid = a.gml_id
	WHERE a.endet IS NOT NULL
	AND b.gml_id IS NULL;
