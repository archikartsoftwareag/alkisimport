\if :alkis_avoiddupes

SET search_path TO :"alkis_schema",public;

CREATE OR REPLACE FUNCTION ignore_duplicate() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  i INTEGER;
  ku BOOLEAN;
  fid VARCHAR;
BEGIN
  EXECUTE format('SELECT COUNT(*)
                  FROM %I.%I
                  WHERE lower(name) = %L
                  AND lower(value) = %L',
                  TG_TABLE_SCHEMA,'ak_alkis_options',
                  'komplettupdate','true')
                  INTO i;
  
  ku := i > 0;

  EXECUTE format('SELECT COUNT(*)
                  FROM %I.%I
                  WHERE gml_id=%L
                  AND beginnt=%L
                  AND endet IS NULL',
                  TG_TABLE_SCHEMA,TG_TABLE_NAME,
                  NEW.gml_id,
                  NEW.beginnt)
                  INTO i;

  IF i>0 THEN
    IF ku THEN
      EXECUTE format('INSERT INTO %I.%I (typename, featureid)
                      VALUES (%L, %L)',
                      TG_TABLE_SCHEMA,'ak_alkis_komplettupdate',
                      TG_TABLE_NAME,NEW.gml_id);
    END IF;
    
    RETURN NULL;
  ELSE
    EXECUTE format('SELECT COUNT(*)
                    FROM %I.%I
                    WHERE gml_id=%L
                    AND endet IS NULL',
                    TG_TABLE_SCHEMA,TG_TABLE_NAME,
                    NEW.GML_ID)
                    INTO i;
    
    IF ku THEN
      IF i > 0 THEN
        fid = NEW.gml_id || translate(NEW.beginnt,'-:','');
        EXECUTE format('INSERT INTO %I.%I (typename, featureid, context, safetoignore, replacedby, endet)
                        VALUES (%L, %L, %L, %L, %L, %L)',
                        TG_TABLE_SCHEMA,'delete',
                        TG_TABLE_NAME,NEW.gml_id,'update','false',fid,NEW.beginnt);
      END IF;
    END IF;
    
    IF i = 0 THEN
      EXECUTE format('INSERT INTO %I.%I (typename, featureid)
                      VALUES (%L, %L)',
                     TG_TABLE_SCHEMA,'ak_alkis_insert',
                     TG_TABLE_NAME,NEW.gml_id);
    END IF;
    
    RETURN NEW;
  END IF;
END;
$$ SET search_path TO :"alkis_schema";

SELECT
	'SELECT alkis_dropobject(' || quote_literal(a.table_name || '_insert') || E');\n' ||
	'CREATE TRIGGER ' || quote_ident(a.table_name || '_insert') || ' BEFORE INSERT ON ' || quote_ident(a.table_schema) || '.' || quote_ident(a.table_name) || ' FOR EACH ROW EXECUTE PROCEDURE ignore_duplicate();'
FROM information_schema.columns a
JOIN information_schema.columns b ON a.table_schema=b.table_schema AND a.table_name=b.table_name AND b.column_name='beginnt'
WHERE a.table_schema=:'alkis_schema'
  AND substr(a.table_name,1,3) IN ('ax_','ap_','ln_','lb_','au_','aa_')
  AND a.column_name='gml_id';
\gexec

\endif
