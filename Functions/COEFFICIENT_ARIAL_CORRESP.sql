CREATE OR REPLACE FUNCTION dz_sdo.coefficient_arial_corresp(
    p_input_1       IN  GEOMETRY
   ,p_input_2       IN  GEOMETRY
   ,p_tolerance     IN  NUMERIC DEFAULT 0.05
   ,p_srid          IN  NUMERIC DEFAULT NULL
) RETURNS NUMERIC
IMMUTABLE
AS
$BODY$ 
DECLARE
  sdo_input_1           GEOMETRY := p_input_1;
  sdo_input_2           GEOMETRY := p_input_2;
  sdo_intersection_geom GEOMETRY;
  sdo_union_geom        GEOMETRY;
  sdo_intersection_area NUMERIC;
  sdo_union_area        NUMERIC;
  num_tolerance         NUMERIC := p_tolerance;
  int_srid              INTEGER := p_srid;
  boo_validate          BOOLEAN;
  
BEGIN

   --------------------------------------------------------------------------
   -- Step 10
   -- Check over incoming parameters
   --------------------------------------------------------------------------
   IF num_tolerance IS NULL
   THEN
      num_tolerance := 0.05;
      
   END IF;
   
   IF sdo_input_1 IS NULL
   THEN
      RAISE EXCEPTION 'input geometry 1 is NULL';
      
   END IF;
   
   IF sdo_input_2 IS NULL
   THEN
      RAISE EXCEPTION 'input geometry 2 is NULL';
      
   END IF;
   
   IF ST_GeometryType(sdo_input_1) NOT IN ('ST_Polygon','ST_MultiPolygon')
   THEN
      RAISE EXCEPTION 'input geometry 1 must be polygon';
      
   END IF;
   
   IF ST_GeometryType(sdo_input_2) NOT IN ('ST_Polygon','ST_MultiPolygon')
   THEN
      RAISE EXCEPTION 'input geometry 2 must be polygon';
      
   END IF;
   
   IF ST_SRID(sdo_input_1) <> ST_SRID(sdo_input_2)
   THEN
      RAISE EXCEPTION 'geometries must use the same coordinate system';
      
   END IF;
   
   IF int_srid IS NOT NULL
   AND int_srid <> ST_SRID(sdo_input_1)
   THEN
      sdo_input_1 := ST_Transform(sdo_input_1,int_srid);
      sdo_input_2 := ST_Transform(sdo_input_2,int_srid);
      
   END IF;
   
   --------------------------------------------------------------------------
   -- Step 20
   -- Validate the geometries
   --------------------------------------------------------------------------
   boo_validate := ST_IsValid(
      sdo_input_1
   );
   
   IF NOT boo_validate
   THEN
      RAISE EXCEPTION 'input geometry 1 does not validate.';
      
   END IF;
   
   boo_validate := ST_IsValid(
      sdo_input_2
   );
   
   IF NOT boo_validate
   THEN
      RAISE EXCEPTION 'input geometry 2 does not validate.';
      
   END IF;
   
   --------------------------------------------------------------------------
   -- Step 30
   -- Do the intersection
   --------------------------------------------------------------------------
   sdo_intersection_geom := ST_Intersection(
       ST_SnapToGrid(sdo_input_1,num_tolerance)
      ,ST_SnapToGrid(sdo_input_2,num_tolerance)
   );
   
   IF ST_GeometryType(sdo_intersection_geom) IN ('ST_Collection')
   THEN
      sdo_intersection_geom := ST_CollectionExtract(sdo_intersection_geom,3);
      
   END IF;
   
   IF sdo_intersection_geom IS NULL
   OR ST_GeometryType(sdo_intersection_geom) NOT IN ('ST_Polygon','ST_MultiPolygon')
   THEN
      RETURN 0;
      
   END IF;
   
   sdo_intersection_area := ST_Area(
      ST_Transform(sdo_intersection_geom,4326)::GEOGRAPHY
   );
   
   --------------------------------------------------------------------------
   -- Step 30
   -- Do the union
   --------------------------------------------------------------------------
   sdo_union_geom := ST_Union(
       ST_SnapToGrid(sdo_input_1,num_tolerance)
      ,ST_SnapToGrid(sdo_input_2,num_tolerance)
   );
   
   IF ST_GeometryType(sdo_union_geom) IN ('ST_Collection')
   THEN
      sdo_union_geom := ST_CollectionExtract(sdo_union_geom,3);
      
   END IF;
   
   IF sdo_union_geom IS NULL
   OR ST_GeometryType(sdo_union_geom) NOT IN ('ST_Polygon','ST_MultiPolygon')
   THEN
      RAISE EXCEPTION 'error evaluating geometries via ST_Union';
      
   END IF;
   
   sdo_union_area := ST_Area(
      ST_Transform(sdo_union_geom,4326)::GEOGRAPHY
   );
   
   IF sdo_union_area = 0
   THEN
      RAISE EXCEPTION 'evaluating geometries via SDO_UNION returned zero area';
      
   END IF;
   
   --------------------------------------------------------------------------
   -- Step 40
   -- Return the coefficient
   --------------------------------------------------------------------------
   RETURN sdo_intersection_area/sdo_union_area;
   
END;
$BODY$
LANGUAGE plpgsql;

ALTER FUNCTION dz_sdo.coefficient_arial_corresp(
    GEOMETRY
   ,GEOMETRY
   ,NUMERIC
   ,NUMERIC
) OWNER TO nhdplus;

GRANT EXECUTE ON FUNCTION dz_sdo.coefficient_arial_corresp(
    GEOMETRY
   ,GEOMETRY
   ,NUMERIC
   ,NUMERIC
) TO PUBLIC;

