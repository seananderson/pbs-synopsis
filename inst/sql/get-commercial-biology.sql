SELECT SM.TRIP_ID, TRIP_START_DATE,
SP.SPECIMEN_ID, SP.SAMPLE_ID,
  SPECIMEN_SEX_CODE AS SEX,
  SPECIMEN_AGE AS AGE,
  CAST(ROUND(Best_Length / 10.0, 1) AS DECIMAL(8,1)) AS LENGTH,
  MATURITY_CODE, SM.MATURITY_CONVENTION_CODE,
  MC.MATURITY_CONVENTION_DESC,
  MC.MATURITY_CONVENTION_MAXVALUE,
  ROUND_WEIGHT AS WEIGHT,
  SM.SPECIES_CODE, SPP.SPECIES_COMMON_NAME, SPP.SPECIES_SCIENCE_NAME,
  SM.SPECIES_CATEGORY_CODE,
  TRIP_SUB_TYPE_CODE, SM.SAMPLE_SOURCE_CODE, SM.SAMPLE_TYPE_CODE, SM.GEAR_CODE,
  CASE FE.GEAR_CODE WHEN 1 THEN TRSP.USABILITY_CODE WHEN 11 THEN TRSP.USABILITY_CODE WHEN 4 THEN LLSP.USABILITY_CODE WHEN 5 THEN LLSP.USABILITY_CODE
                   ELSE 0 END AS USABILITY_CODE,
  SM.CATCH_WEIGHT, SM.CATCH_COUNT
FROM GFBioSQL.dbo.B21_Samples SM
INNER JOIN GFBioSQL.dbo.B22_Specimens SP ON SM.SAMPLE_ID = SP.SAMPLE_ID
INNER JOIN GFBioSQL.dbo.SPECIES SPP ON SPP.SPECIES_CODE = SM.SPECIES_CODE
INNER JOIN GFBioSQL.dbo.Maturity_Convention MC ON SM.MATURITY_CONVENTION_CODE = MC.MATURITY_CONVENTION_CODE
INNER JOIN GFBioSQL.dbo.FISHING_EVENT FE ON FE.FISHING_EVENT_ID = SM.FISHING_EVENT_ID
LEFT OUTER JOIN GFBioSQL.dbo.TRAWL_SPECS AS TRSP ON FE.FISHING_EVENT_ID = TRSP.FISHING_EVENT_ID
LEFT OUTER JOIN GFBioSQL.dbo.LONGLINE_SPECS AS LLSP ON FE.FISHING_EVENT_ID = LLSP.FISHING_EVENT_ID
WHERE TRIP_SUB_TYPE_CODE NOT IN (2, 3) AND SPECIMEN_SEX_CODE IN (1, 2) AND SM.SAMPLE_SOURCE_CODE = 1 AND (CASE FE.GEAR_CODE WHEN 1 THEN TRSP.USABILITY_CODE WHEN 11 THEN TRSP.USABILITY_CODE WHEN 4 THEN LLSP.USABILITY_CODE WHEN 5 THEN LLSP.USABILITY_CODE
                   ELSE 0 END) IN (0,1,2,6) AND (FE.FE_PARENT_EVENT_ID IS NULL)

