SET search_path = :"alkis_schema", public;

DELETE FROM ak_fs_fuellfl_umfang_nutz;
INSERT INTO ak_fs_fuellfl_umfang_nutz(fs_gml_id,fuellfl_umfang,wkb_geometry)
  SELECT f.gml_id AS fs_gml_id,
         st_perimeter2d(st_difference(max(f.wkb_geometry),st_union(st_intersection(f.wkb_geometry,d.wkb_geometry)))) AS fuellfl_umfang,
         st_union(st_intersection(f.wkb_geometry,d.wkb_geometry)) AS wkb_fuellflaeche
  FROM ax_flurstueck f
  JOIN nutz_21 c ON c.fs_gml_id = f.gml_id
  JOIN ax_tatsaechlichenutzung d ON d.gml_id = c.nutz_gml_id AND d.endet = c.endet
  LEFT JOIN ak_fd_hist e ON e.gml_id = f.gml_id
  WHERE f.endet IS NULL OR e.gml_id IS NOT NULL
  GROUP BY f.gml_id;
