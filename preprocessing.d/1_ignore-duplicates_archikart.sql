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
                  TG_TABLE_SCHEMA,'alkis_options',
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
                      TG_TABLE_SCHEMA,'alkis_komplettupdate',
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
                     TG_TABLE_SCHEMA,'alkis_insert',
                     TG_TABLE_NAME,NEW.gml_id);
    END IF;
    
    RETURN NEW;
  END IF;
END;
$$ SET search_path TO :"alkis_schema";
