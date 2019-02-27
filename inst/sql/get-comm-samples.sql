SELECT TRIP_START_DATE,
  SM.TRIP_ID,
  SM.FISHING_EVENT_ID,
  SM.GEAR_CODE AS GEAR,
  SM.SPECIES_CODE, 
  SPP.SPECIES_COMMON_NAME, 
  SPP.SPECIES_SCIENCE_NAME, 
  SP.SAMPLE_ID,
  SP.SPECIMEN_ID, 
  SP.SPECIMEN_SEX_CODE AS SEX,
  CASE WHEN SPECIMEN_COLLECTED_IND = 'Y' THEN 1 ELSE 0 END AS AGE_SPECIMEN_COLLECTED,
  SPECIMEN_AGE AS AGE,
  AGEING_METHOD_CODE,
  CAST(ROUND(Best_Length / 10.0, 1) AS DECIMAL(8,1)) AS LENGTH,
  ROUND_WEIGHT AS WEIGHT,
  SP.MATURITY_CODE,
  SM.MATURITY_CONVENTION_CODE,
  MC.MATURITY_CONVENTION_DESC,
  SM.TRIP_SUB_TYPE_CODE,
  TRIP_SUB_TYPE_DESC,
  SM.SAMPLE_TYPE_CODE,
  SM.SAMPLE_WEIGHT,
  SM.SPECIES_CATEGORY_CODE,
  SM.SAMPLE_SOURCE_CODE,
  SM.CATCH_WEIGHT,
  SM.CATCH_COUNT,
  SM.MAJOR_STAT_AREA_CODE,
  MAJOR_STAT_AREA_NAME,
  SM.MINOR_STAT_AREA_CODE,
  CASE WHEN SM.GEAR_CODE IN (1, 6, 11) THEN ISNULL(TRSP.USABILITY_CODE, 0)
  WHEN SM.GEAR_CODE IN (2) THEN ISNULL(TPSP.USABILITY_CODE, 0)
  WHEN SM.GEAR_CODE IN (5) THEN ISNULL(LLSP.USABILITY_CODE, 0)
  WHEN SM.GEAR_CODE IN (4) THEN ISNULL(HLSP.USABILITY_CODE, 0)
  ELSE 0 END AS USABILITY_CODE,
  CASE WHEN SPECIES_CATEGORY_CODE IN (0, 1, 5, 6, 7) AND (SAMPLE_SOURCE_CODE IS NULL OR SAMPLE_SOURCE_CODE = 1) 
		THEN 'UNSORTED'
	WHEN SPECIES_CATEGORY_CODE IN(1, 2) AND SAMPLE_SOURCE_CODE = 2 
		THEN 'KEEPERS'
	WHEN SPECIES_CATEGORY_CODE = 3 AND (SAMPLE_SOURCE_CODE IS NULL OR SAMPLE_SOURCE_CODE IN(1, 2)) 
		THEN 'KEEPERS'
	WHEN SPECIES_CATEGORY_CODE = 1 AND SAMPLE_SOURCE_CODE = 3 
		THEN 'DISCARDS'
	WHEN SPECIES_CATEGORY_CODE = 4 AND SAMPLE_SOURCE_CODE IN(1, 3) 
		THEN 'DISCARDS'
	ELSE 'TBD' END AS SAMPLING_DESC,
	VESSEL_ID
FROM GFBioSQL.dbo.B21_Samples SM
	INNER JOIN GFBioSQL.dbo.B22_Specimens SP ON SM.SAMPLE_ID = SP.SAMPLE_ID
	INNER JOIN GFBioSQL.dbo.SPECIES SPP ON SPP.SPECIES_CODE = SM.SPECIES_CODE
	INNER JOIN GFBioSQL.dbo.Maturity_Convention MC ON SM.MATURITY_CONVENTION_CODE = MC.MATURITY_CONVENTION_CODE
	INNER JOIN GFBioSQL.dbo.FISHING_EVENT FE ON FE.FISHING_EVENT_ID = SM.FISHING_EVENT_ID
	INNER JOIN GFBioSQL.dbo.MAJOR_STAT_AREA MSA ON SM.MAJOR_STAT_AREA_CODE = MSA.MAJOR_STAT_AREA_CODE
	LEFT OUTER JOIN GFBioSQL.dbo.MATURITY_DESCRIPTION MD ON SM.MATURITY_CONVENTION_CODE = MD.MATURITY_CONVENTION_CODE 
	  AND SP.MATURITY_CODE = MD.MATURITY_CODE AND SP.SPECIMEN_SEX_CODE = MD.SPECIMEN_SEX_CODE
    LEFT JOIN GFBioSQL.dbo.TRAWL_SPECS TRSP ON TRSP.FISHING_EVENT_ID = SM.FISHING_EVENT_ID
    LEFT JOIN GFBioSQL.dbo.TRAP_SPECS TPSP ON TPSP.FISHING_EVENT_ID = SM.FISHING_EVENT_ID
    LEFT JOIN GFBioSQL.dbo.LONGLINE_SPECS LLSP ON LLSP.FISHING_EVENT_ID = SM.FISHING_EVENT_ID
    LEFT JOIN GFBioSQL.dbo.HANDLINE_SPECS HLSP ON HLSP.FISHING_EVENT_ID = SM.FISHING_EVENT_ID
	INNER JOIN GFBioSQL.dbo.TRIP_SUB_TYPE TST ON TST.TRIP_SUB_TYPE_CODE = SM.TRIP_SUB_TYPE_CODE
	LEFT JOIN (SELECT SAMPLE_ID, MIN(SPECIMEN_ID) AS SPECIMEN_ID, SPECIMEN_COLLECTED_IND
		FROM GFBioSQL.dbo.SPECIMEN_COLLECTED
		WHERE COLLECTED_ATTRIBUTE_CODE BETWEEN 20 AND 25
		GROUP BY SAMPLE_ID, SPECIMEN_COLLECTED_IND) SC ON     SP.SPECIMEN_ID = SC.SPECIMEN_ID
WHERE SM.FE_PARENT_EVENT_ID IS NULL AND SM.TRIP_SUB_TYPE_CODE NOT IN (2, 3) AND
  SM.SAMPLE_TYPE_CODE IN (1,2,6,7,8) AND
  (SPECIES_CATEGORY_CODE IS NULL OR SPECIES_CATEGORY_CODE IN (0, 1, 3, 4, 5, 6, 7)) AND
  (SP.MATURITY_CODE <= MC.MATURITY_CONVENTION_MAXVALUE OR SP.MATURITY_CODE IS NULL)
-- insert species here
ORDER BY SAMPLING_DESC,
YEAR(TRIP_START_DATE)

