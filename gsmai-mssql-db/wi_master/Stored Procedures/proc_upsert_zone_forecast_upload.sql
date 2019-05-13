
CREATE PROC [dbo].[proc_upsert_zone_forecast_upload]
@zoneDataType dbo.zone_data_type READONLY,
@analystTeamViewId INT,
@secondAnalystTeamViewId INT = 0
AS
BEGIN
DECLARE @zoneDataLinkType dbo.zone_data_links_type;
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
	FROM @zoneDataType tv
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
		AND atbl.archive = tv.archive
	WHERE atbl.id IS NULL
	
	-- Log TVP data count
	--DECLARE @count1 int = ( select count(*) from @zoneDataType )
	--DECLARE @message1 char(110) = '@zoneDataType count ' + CAST(@count1 as char(100))
	--execute [dbo].[collect_data_insert_errors] @query_string = @message1
	-----------------------



	
	-- Collect existing ROWS and the new rows with new ID's
	INSERT INTO @zoneDataLinkType
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
		  ,atbl.[is_spot_price] FROM @zoneDataType tv
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
		AND atbl.archive = tv.archive
	WHERE atbl.id IS NOT NULL

	-- Log TVP insert count
	--DECLARE @count int = ( select count(*) from @zoneDataLinkType )
	--DECLARE @message char(110) = '@zoneDataLinkType count ' + CAST(@count as char(100))
	--execute [dbo].[collect_data_insert_errors] @query_string = @message
	-----------------------
	
	EXEC [dbo].[proc_upsert_zone_data_view_link] @zoneDataLinkType = @zoneDataLinkType, @analystTeamViewId = @analystTeamViewId, @secondAnalystTeamViewId = @secondAnalystTeamViewId

		
	
	

END
