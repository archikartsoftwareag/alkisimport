SET search_path TO :"alkis_schema",public;

CREATE OR REPLACE procedure fullupdate_hist()
LANGUAGE plpgsql 
AS $$
DECLARE
  options record;
  metadata record;
  impdate varchar;
  table_schema varchar;
  table_name varchar;
  tabledata record;
  featureid varchar;
  fullupdate boolean;
  sql_table varchar;
  count_table integer;
  count_data integer;
  count_hist integer;
  index integer := 0;
  sql_base varchar;
  sql_hist varchar;
  sql_count varchar;
BEGIN
  FOR options IN
    SELECT *
    FROM alkis_options
    WHERE lower(name) IN ('komplettupdate', 'lastimportdate')
  LOOP
    CASE lower(options.name)
      WHEN 'komplettupdate' THEN
        fullupdate := options.value::boolean;
      WHEN 'lastimportdate' THEN
        impdate := options.value;
    END CASE;
  END LOOP;

  IF fullupdate THEN
    raise notice 'Historisierung Komplettupdate gestartet...';
    
    sql_table := 'SELECT a.table_schema, a.table_name
                  FROM information_schema.columns a
                  JOIN information_schema.columns b
                  ON b.table_schema = a.table_schema
                  AND b.table_name = a.table_name
                  AND b.column_name = ''beginnt''
                  JOIN information_schema.columns c
                  ON c.table_schema = a.table_schema
                  AND c.table_name = a.table_name
                  AND c.column_name = ''endet''
                  JOIN information_schema.tables d
                  ON d.table_schema = a.table_schema 
                  AND d.table_name = a.table_name
                  AND d.table_type = ''BASE TABLE''
                  WHERE a.table_schema = ''archikart''
                  AND substr(a.table_name, 1, 3) IN (''ax_'', ''ap_'', ''ln_'', ''lb_'', ''au_'', ''aa_'')
                  AND a.column_name = ''gml_id''
                  ORDER BY a.table_name';
    
    EXECUTE format('SELECT COUNT(*)
                    FROM (%s) temp',
                   sql_table)
    INTO count_table;
    
    FOR metadata IN
      EXECUTE sql_table
    LOOP
      table_schema := metadata.table_schema;
      table_name := metadata.table_name;
      index := index + 1;
      sql_base := 'SELECT %s
                   FROM %I.%I a
                   LEFT JOIN %I.%I b
                   ON b.featureid = a.gml_id
                   LEFT JOIN %I.%I c
                   ON c.featureid = a.gml_id
                   LEFT JOIN %I.%I d
                   ON d.featureid = a.gml_id
                   WHERE a.beginnt <= %L
                   AND a.endet IS NULL
                   AND b.id IS NULL
                   AND c.id IS NULL
                   AND d.ogc_fid IS NULL';
      sql_count := format(sql_base,
                          'COUNT(*)',
                          table_schema,table_name,
                          table_schema,'alkis_komplettupdate',
                          table_schema,'alkis_insert',
                          table_schema,'delete',
                          impdate);
      sql_hist := format(sql_base,
                         'a.gml_id, a.beginnt',
                         table_schema,table_name,
                         table_schema,'alkis_komplettupdate',
                         table_schema,'alkis_insert',
                         table_schema,'delete',
                         impdate);

      raise notice 'Historisierung Tabelle <%> (% / %)',table_name,index,count_table;

      EXECUTE sql_count INTO count_hist;
      EXECUTE format('SELECT COUNT(*)
                      FROM %I.%I
                      WHERE endet IS NULL',
                      table_schema,table_name)
      INTO count_data;

      IF (count_hist > 0) AND (count_data <> count_hist) THEN
        raise notice '% Datensätze werden historisiert...',count_hist;

        FOR tabledata IN
          EXECUTE sql_hist
        LOOP
          featureid := tabledata.gml_id || translate(tabledata.beginnt,':-','');

          EXECUTE format('INSERT INTO %I.%I
                          (typename, featureid, context, safetoignore, replacedby)
                          VALUES
                          (%L, %L, %L, %L, %L)',
                         table_schema,'delete',
                         table_name,tabledata.gml_id,'delete','false',featureid);
        END LOOP;
      END IF;
    END LOOP;

    PERFORM 'UPDATE ax_gemarkung '
            || 'SET endet = NULL '
            || 'WHERE EXSITS(SELECT gml_id FROM ax_flurstueck WHERE gemarkungsnummer = gemarkungsnummer AND endet IS NULL) '
            || 'AND endet IS NOT NULL';
    PERFORM 'UPDATE ax_buchungsblattbezirk '
            || 'SET endet = NULL '
            || 'WHERE EXSITS(SELECT gml_id FROM ax_buchungsblatt WHERE bezirk = bezirk AND endet IS NULL) '
            || 'AND endet IS NOT NULL';

    raise notice 'Historisierung Komplettupdate beendet';
  END IF;
END;
$$ SET search_path TO :"alkis_schema";

CALL fullupdate_hist();
