CREATE OR REPLACE FUNCTION dz_sdo.remove_holes(
    p_input      IN GEOMETRY    
) RETURNS GEOMETRY
IMMUTABLE
AS
$BODY$ 
DECLARE
   ary_geom   GEOMETRY[];
   ary_final  GEOMETRY[];
   int_rings  INTEGER;
   
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
   -- Roll through and nuke the holes
   --------------------------------------------------------------------------
   FOR i IN 1 .. array_length(ary_geom,1)
   LOOP
      int_rings := ST_NRings(ary_geom[i]);
      
      IF int_rings > 1
      THEN
         ary_geom[i] := ST_MakePolygon(ST_ExteriorRing(ary_geom[i]));
         
      END IF;
   
   END LOOP;
   
   --------------------------------------------------------------------------
   -- Step 30
   -- Short circuit if single polygon
   --------------------------------------------------------------------------
   IF array_length(ary_geom,1) = 1
   THEN
      RETURN ary_geom[1];
      
   END IF;
   
   --------------------------------------------------------------------------
   -- Step 40
   -- Roll through and check for islands in holes
   --------------------------------------------------------------------------
   int_rings := 2;
   ary_final[1] := ary_geom[1];
   FOR i IN 2 .. array_length(ary_geom,1)
   LOOP
      IF ST_Contains(ary_geom[i],ary_final[1])
      OR ST_Contains(ary_final[1],ary_geom[i])
      THEN
         NULL;
         
      ELSE
         ary_final[int_rings] := ary_geom[i];
         int_rings := int_rings + 1;
      
      END IF;
   
   END LOOP;
   
   --------------------------------------------------------------------------
   -- Step 50
   -- Short circuit again if now single polygon
   --------------------------------------------------------------------------
   IF array_length(ary_final,1) = 1
   THEN
      RETURN ary_final[1];
      
   END IF;
   
   --------------------------------------------------------------------------
   -- Step 60
   -- Rebuild into multipolygon
   --------------------------------------------------------------------------
   RETURN ST_Collect(ary_final);
   
END;
$BODY$
LANGUAGE plpgsql;

ALTER FUNCTION dz_sdo.remove_holes(
    geometry
) OWNER TO nhdplus;

GRANT EXECUTE ON FUNCTION dz_sdo.remove_holes(
    geometry
) TO PUBLIC;

