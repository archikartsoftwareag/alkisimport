SET search_path = :"alkis_schema", public;

-- Löschsatz verarbeiten (MIT Historie)
-- context='delete'        => "endet" auf aktuelle Zeit setzen
-- context='replace'       => "endet" des ersetzten auf "beginnt" des neuen Objekts setzen
-- context='update'        => "endet" auf übergebene Zeit setzen und "anlass" festhalten
CREATE OR REPLACE FUNCTION delete_feature_hist() RETURNS TRIGGER AS $$
DECLARE
	n INTEGER;
	beginnt TEXT;
	s TEXT;
BEGIN
	NEW.context := coalesce(lower(NEW.context),'delete');

	IF length(NEW.featureid)=32 THEN
		beginnt := substr(NEW.featureid, 17, 4) || '-'
			|| substr(NEW.featureid, 21, 2) || '-'
			|| substr(NEW.featureid, 23, 2) || 'T'
			|| substr(NEW.featureid, 26, 2) || ':'
			|| substr(NEW.featureid, 28, 2) || ':'
			|| substr(NEW.featureid, 30, 2) || 'Z'
			;
	ELSIF length(NEW.featureid)=16 THEN
		-- Ältestes nicht gelöschtes Objekt
		EXECUTE 'SELECT min(beginnt) FROM ' || NEW.typename
			|| ' WHERE gml_id=''' || NEW.featureid || ''''
			|| ' AND endet IS NULL'
			INTO beginnt;

		IF beginnt IS NULL THEN
			EXECUTE format('INSERT INTO %I.%I (typename, context, featureid)
							VALUES (%L, %L, %L)',
							TG_TABLE_SCHEMA,'ak_object_not_found',
							NEW.typename, NEW.context, NEW.featureid);
			RETURN NULL;
		END IF;
	ELSE
		RAISE EXCEPTION '%: Identifikator gescheitert.', NEW.featureid;
	END IF;

	IF NEW.context='delete' THEN
		SELECT value
		INTO NEW.endet
		FROM ak_alkis_options
		WHERE lower(name) = 'importdate';

	ELSIF NEW.context='update' THEN
		IF NEW.endet IS NULL THEN
			RAISE EXCEPTION '%: Endedatum nicht gesetzt', NEW.featureid;
		END IF;

	ELSIF NEW.context='replace' THEN
		NEW.safetoignore := lower(NEW.safetoignore);
		IF NEW.safetoignore IS NULL THEN
			RAISE EXCEPTION '%: safeToIgnore nicht gesetzt.', NEW.featureid;
		ELSIF NEW.safetoignore<>'true' AND NEW.safetoignore<>'false' THEN
			RAISE EXCEPTION '%: safeToIgnore ''%'' ungültig (''true'' oder ''false'' erwartet).', NEW.featureid, NEW.safetoignore;
		END IF;

		IF length(NEW.replacedby)=32 AND NEW.replacedby<>NEW.featureid THEN
			NEW.endet := substr(NEW.replacedby, 17, 4) || '-'
				  || substr(NEW.replacedby, 21, 2) || '-'
				  || substr(NEW.replacedby, 23, 2) || 'T'
				  || substr(NEW.replacedby, 26, 2) || ':'
				  || substr(NEW.replacedby, 28, 2) || ':'
				  || substr(NEW.replacedby, 30, 2) || 'Z'
				  ;
		END IF;

		IF NEW.endet IS NULL THEN
			-- Beginn des ersten Nachfolgeobjektes
			EXECUTE 'SELECT min(beginnt) FROM ' || NEW.typename || ' a'
				|| ' WHERE gml_id=''' || substr(NEW.replacedby, 1, 16) || ''''
				|| ' AND beginnt>''' || beginnt || ''''
				INTO NEW.endet;
		ELSE
			EXECUTE 'SELECT count(*) FROM ' || NEW.typename
				|| ' WHERE gml_id=''' || substr(NEW.replacedby, 1, 16) || ''''
				|| ' AND beginnt=''' || NEW.endet || ''''
				INTO n;
			IF n<>1 THEN
				RAISE EXCEPTION '%: Ersatzobjekt % % nicht gefunden.', NEW.featureid, NEW.replacedby, NEW.endet;
			END IF;
		END IF;

		IF NEW.endet IS NULL THEN
			-- Abbrechen, wenn Austausch nicht ignoriert werden
			-- darf, aber nicht wenn ein Objekt (sinnloserweise?)
			-- gegen selbst getauscht werden soll.
			IF NEW.safetoignore='false' AND NEW.featureid<>NEW.replacedby THEN
				RAISE EXCEPTION '%: Beginn des Ersatzobjekts % nicht gefunden.', NEW.featureid, NEW.replacedby;
				-- RAISE NOTICE '%: Beginn des ersetzenden Objekts % nicht gefunden.', NEW.featureid, NEW.replacedby;
			END IF;

			NEW.ignored=true;
			RETURN NEW;
		END IF;

	ELSE
		RAISE EXCEPTION '%: Ungültiger Kontext % (''delete'', ''replace'' oder ''update'' erwartet).', NEW.featureid, NEW.context;

	END IF;

	s := 'UPDATE ' || NEW.typename || ' SET endet=''' || NEW.endet || '''';

	IF NEW.context='update' AND NEW.anlass IS NOT NULL THEN
		s := s || ',anlass=array_cat(anlass,''{' || array_to_string(NEW.anlass,',') || '}'')';
	END IF;

	s := s || ' WHERE gml_id=''' || substr(NEW.featureid, 1, 16) || ''''
	       || ' AND beginnt=''' || beginnt || ''''
	       ;
	EXECUTE s;
	GET DIAGNOSTICS n = ROW_COUNT;
	-- RAISE NOTICE 'SQL[%]:%', n, s;
	IF n<>1 THEN
		IF n=0 THEN
			s := 'SELECT count(*),min(beginnt) FROM ' || NEW.typename || ' WHERE gml_id=''' || substr(NEW.featureid, 1, 16) || ''' AND endet IS NULL';
			EXECUTE s INTO n, beginnt;
			IF (n=0 AND NEW.context IN ('delete','update')) OR (n=1 AND NEW.context='replace') THEN
				RAISE NOTICE '%: Kein Objekt gefunden [%:%]', NEW.featureid, NEW.context, n;
				NEW.ignored=true;
				RETURN NEW;
			ELSIF n=2 AND beginnt IS NOT NULL THEN
				s := 'UPDATE ' || NEW.typename || ' a SET endet=''' || NEW.endet || '''';

				IF NEW.anlass IS NOT NULL THEN
					s := s || ',anlass=array_cat(anlass,''{' || array_to_string(NEW.anlass,',') || '}'')';
				END IF;

				s := s || ' WHERE gml_id=''' || substr(NEW.featureid, 1, 16) || ''''
				       || ' AND beginnt=''' || beginnt || ''''
				       ;
				EXECUTE s;
				GET DIAGNOSTICS n = ROW_COUNT;
				-- RAISE NOTICE 'SQL[%]:%', n, s;
				IF n<>1 THEN
					RAISE EXCEPTION '%: Aktualisierung des Vorgängerobjekts von % schlug fehl [%:%]', NEW.featureid, beginnt, NEW.context, n;
				END IF;
			ELSE
				RAISE NOTICE '%: Kein eindeutiges Vorgängerobjekt gefunden [%:%]', NEW.featureid, NEW.context, n;
				RETURN NEW;
			END IF;
		ELSE
			RAISE EXCEPTION '%: % schlug fehl [%]', NEW.featureid, NEW.context, n;
		END IF;
	END IF;

	NEW.ignored := false;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = :"alkis_schema", public;

CREATE FUNCTION pg_temp.create_trigger(hist BOOLEAN) RETURNS void AS $$
BEGIN
	IF hist THEN
		CREATE OR REPLACE TRIGGER delete_feature_trigger
			BEFORE INSERT ON delete
			FOR EACH ROW
			EXECUTE PROCEDURE delete_feature_hist();
		RAISE NOTICE 'Historische Objekte werden geführt.';
	END IF;
END;
$$ LANGUAGE plpgsql;

SELECT pg_temp.create_trigger(:alkis_hist);
DELETE FROM delete;
