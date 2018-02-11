CREATE OR REPLACE FUNCTION dz_sdo.has_holes(
    p_input      IN GEOMETRY    
) RETURNS BOOLEAN
IMMUTABLE
AS
$BODY$ 
DECLARE
   ary_geom  GEOMETRY[];
   int_rings INTEGER;
   
BEGIN

   --------------------------------------------------------------------------
   -- Step 10
   -- Check over incoming parameters
   --------------------------------------------------------------------------
   IF p_input IS NULL
   THEN
      RETURN NULL;
      
   ELSIF ST_GeometryType(p_input) = 'ST_Polygon'
   THEN
      ary_geom[1] := p_input;
      
   ELSIF ST_GeometryType(p_input) = 'ST_MultiPolygon'
   THEN
      SELECT
      array_agg(a.shape::geometry)
      INTO 
      ary_geom
      FROM (
         SELECT (ST_Dump(p_input)).geom AS shape
      ) a;
      
   ELSE
      RAISE EXCEPTION 'Input must be polygon or multipolygon';
      
   END IF;
   
   --------------------------------------------------------------------------
   -- Step 20
   -- Examine each item for holes
   --------------------------------------------------------------------------
   FOR i IN 1 .. array_length(ary_geom,1)
   LOOP
      int_rings := ST_NRings(ary_geom[i]);
      
      IF int_rings > 1
      THEN
         RETURN TRUE;
         
      END IF;
   
   END LOOP;
   
   --------------------------------------------------------------------------
   -- Step 30
   -- If no hits then results is false
   --------------------------------------------------------------------------
   RETURN FALSE;
   
END;
$BODY$
LANGUAGE plpgsql;

ALTER FUNCTION dz_sdo.has_holes(
    geometry
) OWNER TO nhdplus;

GRANT EXECUTE ON FUNCTION dz_sdo.has_holes(
    geometry
) TO PUBLIC;

