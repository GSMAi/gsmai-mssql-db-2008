


CREATE PROCEDURE [dbo].[proc_upsert_zone_reported_upload]
@zoneReportedDataType dbo.zone_reported_data_type READONLY,
@analystTeamViewId INT

AS
BEGIN

DECLARE @zoneReportedDataLinkType dbo.zone_reported_data_links_type;
DECLARE @linkDate DATETIME = GETDATE();

	-- INSERT NEW ROW
	INSERT INTO dbo.zone_data (
		[fk_zone_id]
	      ,[fk_metric_id]
	      ,[fk_attribute_id]
	      ,[fk_status_id]
	      ,[fk_privacy_id]
	      ,[date]
	      ,[date_type]
	      ,[val]
	      ,[fk_currency_id]
	      ,[fk_source_id]
	      ,[fk_confidence_id]
	      ,[has_flags]
	      ,[is_calculated]
	      ,[archive]
	      ,[is_spot_price])
	SELECT tv.[fk_zone_id]
	      ,tv.[fk_metric_id]
	      ,tv.[fk_attribute_id]
	      ,tv.[fk_status_id]
	      ,tv.[fk_privacy_id]
	      ,tv.[date]
	      ,tv.[date_type]
	      ,tv.[val]
	      ,tv.[fk_currency_id]
	      ,tv.[fk_source_id]
	      ,tv.[fk_confidence_id]
	      ,tv.[has_flags]
	      ,tv.[is_calculated]
	      ,tv.[archive]
	      ,tv.[is_spot_price]
	FROM @zoneReportedDataType tv
	LEFT JOIN dbo.zone_data AS atbl 
		ON  atbl.fk_zone_id = tv.fk_zone_id
		AND atbl.fk_metric_id = tv.fk_metric_id
		AND atbl.fk_attribute_id = tv.fk_attribute_id
		AND atbl.fk_status_id = tv.fk_status_id
		AND atbl.[date] = tv.[date]
		AND atbl.date_type = tv.date_type
		AND atbl.val = tv.val
		AND atbl.has_flags = tv.has_flags
		AND atbl.fk_currency_id = tv.fk_currency_id
		AND atbl.fk_source_id = tv.fk_source_id
		AND atbl.fk_confidence_id = tv.fk_confidence_id
		AND atbl.is_spot_price = tv.is_spot_price
		AND atbl.is_calculated = tv.is_calculated
	WHERE atbl.id IS NULL



	-- Collect existing ROWS and the new rows with new ID's
	INSERT INTO @zoneReportedDataLinkType (
		  [id]
		  ,[fk_zone_id]
	      ,[fk_metric_id]
	      ,[fk_attribute_id]
	      ,[fk_status_id]
	      ,[fk_privacy_id]
	      ,[date]
	      ,[date_type]
	      ,[val]
	      ,[fk_currency_id]
	      ,[fk_source_id]
	      ,[fk_confidence_id]
	      ,[has_flags]
	      ,[is_calculated]
	      ,[archive]
	      ,[is_spot_price]
		,[location], [location_cleaned], [definition], [notes], [fk_flag_id]  )
	SELECT atbl.[id],
		atbl.[fk_zone_id]
	      ,atbl.[fk_metric_id]
	      ,atbl.[fk_attribute_id]
	      ,atbl.[fk_status_id]
	      ,atbl.[fk_privacy_id]
	      ,atbl.[date]
	      ,atbl.[date_type]
	      ,atbl.[val]
	      ,atbl.[fk_currency_id]
	      ,atbl.[fk_source_id]
	      ,atbl.[fk_confidence_id]
	      ,atbl.[has_flags]
	      ,atbl.[is_calculated]
	      ,atbl.[archive]
	      ,atbl.[is_spot_price],
		CASE WHEN tv.location IS NOT NULL THEN tv.location ELSE odm.location END AS "location", 
		CASE WHEN tv.location_cleaned IS NOT NULL THEN tv.location_cleaned ELSE odm.location_cleaned END AS "location_cleaned", 
		CASE WHEN tv.definition IS NOT NULL THEN tv.definition ELSE odm.definition END AS "definition", 
		CASE WHEN tv.notes IS NOT NULL THEN tv.notes ELSE odm.notes END AS "notes" ,
		CASE WHEN tv.fk_flag_id  IS NOT NULL THEN tv.fk_flag_id ELSE ofl.fk_flag_id END AS "fk_flag_id" 
	FROM @zoneReportedDataType tv
	LEFT JOIN dbo.zone_data AS atbl 
		ON  atbl.fk_zone_id = tv.fk_zone_id
		AND atbl.fk_metric_id = tv.fk_metric_id
		AND atbl.fk_attribute_id = tv.fk_attribute_id
		AND atbl.fk_status_id = tv.fk_status_id
		AND atbl.[date] = tv.[date]
		AND atbl.date_type = tv.date_type
		AND atbl.val = tv.val
		AND atbl.has_flags = tv.has_flags
		AND atbl.fk_currency_id = tv.fk_currency_id
		AND atbl.fk_source_id = tv.fk_source_id
		AND atbl.fk_confidence_id = tv.fk_confidence_id
		AND atbl.is_spot_price = tv.is_spot_price
		AND atbl.is_calculated = tv.is_calculated
	LEFT JOIN dbo.zone_data_metadata as odm ON odm.fk_zone_data_id=atbl.id
	LEFT JOIN dbo.zone_data_flags_link as ofl ON ofl.fk_zone_data_id=atbl.id
	WHERE atbl.id IS NOT NULL 

	EXEC [dbo].[proc_upsert_zone_reported_data_view_link] @zoneReportedDataLinkType = @zoneReportedDataLinkType, @analystTeamViewId = @analystTeamViewId

	
END


