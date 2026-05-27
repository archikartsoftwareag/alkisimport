SET search_path = :"alkis_schema", public;

DELETE FROM ak_fs_fuellfl_umfang_klass;
INSERT INTO ak_fs_fuellfl_umfang_klass(fs_gml_id, fuellfl_umfang, wkb_geometry)
  SELECT fs_gml_id, fuellfl_umfang, wkb_fuellflaeche FROM (
    SELECT f.gml_id AS fs_gml_id,
           st_perimeter2d(ak_alkis_difference(st_geomfromewkt(max(st_asewkt(f.wkb_geometry))),st_union(st_intersection(f.wkb_geometry,d.wkb_geometry)),'ax_flurstueck: '||f.gml_id)) AS fuellfl_umfang,
           st_union(st_intersection(f.wkb_geometry,d.wkb_geometry)) AS wkb_fuellflaeche,
           st_area(st_geomfromewkt(max(st_asewkt(f.wkb_geometry)))) AS fs_fl,
           st_area(st_union(st_intersection(f.wkb_geometry,d.wkb_geometry))) AS klas_fl
    FROM ax_flurstueck f
    JOIN klas_3x c ON c.fs_gml_id = f.gml_id
    JOIN ax_klassifizierung d ON d.gml_id = c.klas_gml_id AND d.endet IS NOT DISTINCT FROM c.klas_endet
    LEFT JOIN ak_fs_hist e ON e.gml_id = f.gml_id
    WHERE (f.endet IS NULL OR e.gml_id IS NOT NULL)
    AND ASCII(SUBSTRING(c.klf,1,1)) < 96
    AND c.klf NOT LIKE 'B:%'
    GROUP BY f.gml_id) temp
  WHERE (fs_fl - klas_fl) > (SELECT value FROM ak_alkis_options WHERE name = 'MinFüllfläche')::float;
