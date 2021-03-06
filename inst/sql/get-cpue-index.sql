SELECT BEST_DATE,
	VESSEL_NAME,
	VESSEL_REGISTRATION_NUMBER,
	FISHERY_SECTOR,
	TRIP_ID,
	FISHING_EVENT_ID,
	FE_START_DATE,
	FE_END_DATE,
	SPECIES_CODE,
	GEAR,
	BEST_DEPTH,
	MAJOR_STAT_AREA_CODE,
	MINOR_STAT_AREA_CODE,
	LOCALITY_CODE,
	LATITUDE,
	LONGITUDE,
	ISNULL(LANDED_KG, 0) AS LANDED_KG,
	ISNULL(DISCARDED_KG, 0) AS DISCARDED_KG
FROM GFFOS.dbo.GF_MERGED_CATCH C
	WHERE FE_END_DATE > FE_START_DATE AND 
	YEAR(FE_START_DATE) = YEAR(FE_END_DATE) AND
	FE_START_DATE IS NOT NULL AND
-- insert filters here
	FE_END_DATE IS NOT NULL

