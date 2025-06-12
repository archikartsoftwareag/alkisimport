/***************************************************************************
 *                                                                         *
 * Project:  norGIS ALKIS Import                                           *
 * Purpose:  Duplikate ignorieren                                          *
 * Author:   Jürgen E. Fischer <jef@norbit.de>                             *
 *                                                                         *
 ***************************************************************************
 * Copyright (c) 2012-2023, Jürgen E. Fischer <jef@norbit.de>              *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

\if :alkis_avoiddupes

SET search_path TO :"alkis_schema",public;

CREATE OR REPLACE FUNCTION ignore_duplicate() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  i INTEGER;
  ku BOOLEAN;
  fid VARCHAR;
  endet VARCHAR;
BEGIN
  EXECUTE format('SELECT COUNT(*)
                  FROM %I.%I
                  WHERE lower(name) = %L
                  AND lower(value) = %L',
                 TG_TABLE_SCHEMA,'alkis_options',
                 'komplettupdate','true')
                 INTO i;
  
  ku := i > 0;

  EXECUTE format('SELECT COUNT(*), COALESCE(MAX(endet),'''')
                  FROM %I.%I
                  WHERE gml_id=%L
                  AND beginnt=%L',
                 TG_TABLE_SCHEMA,TG_TABLE_NAME,
                 NEW.gml_id,
                 NEW.beginnt)
                 INTO i, endet;

  IF i > 0 THEN
    IF ku THEN
      IF endet = '' THEN
        EXECUTE format('INSERT INTO %I.%I (typename, featureid)
                        VALUES (%L, %L)',
                       TG_TABLE_SCHEMA,'alkis_komplettupdate',
                       TG_TABLE_NAME,NEW.gml_id);
      ELSE
        EXECUTE format('UPDATE %I.%I
                        SET endet = NULL
                        WHERE gml_id = %L
                        AND beginnt = %L',
                       TG_TABLE_SCHEMA,TG_TABLE_NAME,
                       NEW.gml_id,
                       NEW.beginnt);
        EXECUTE format('INSERT INTO %I.%I (typename, featureid)
                        VALUES (%L, %L)',
                       TG_TABLE_SCHEMA,'alkis_insert',
                       TG_TABLE_NAME,NEW.gml_id);
      END IF;
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

SELECT format(E'DROP TRIGGER IF EXISTS %I ON %I.%I;\nCREATE TRIGGER %I BEFORE INSERT ON %I.%I FOR EACH ROW EXECUTE PROCEDURE ignore_duplicate();',
        a.table_name || '_insert', a.table_schema, a.table_name,
        a.table_name || '_insert', a.table_schema, a.table_name)
    FROM information_schema.columns a
    JOIN information_schema.columns b ON a.table_schema=b.table_schema AND a.table_name=b.table_name AND b.column_name='beginnt'
    JOIN information_schema.tables c ON c.table_schema=a.table_schema AND c.table_name=a.table_name AND c.table_type='BASE TABLE'
    WHERE a.table_schema=:'alkis_schema'
      AND substr(a.table_name,1,3) IN ('ax_','ap_','ln_','lb_','au_','aa_')
      AND a.column_name='gml_id';
\gexec

\endif
