
CREATE PROC [dbo].[proc_upsert_group_forecast_upload]
@groupDataType dbo.group_data_type READONLY,
@batchDate DATETIME,
@analystTeamViewId INT,
@secondAnalystTeamViewId INT = 0

AS
BEGIN

DECLARE @groupDataLinkType dbo.group_data_links_type;

	-- INSERT NEW ROW
	INSERT INTO dbo.group_data (
		[fk_organisation_id]
	      ,[fk_metric_id]
	      ,[fk_attribute_id]
	      ,[fk_status_id]
	      ,[fk_privacy_id]
	      ,[date]
	      ,[date_type]
	      ,[val_sum]
	      ,[fk_currency_id]
	      ,[fk_source_id]
	      ,[fk_confidence_id]
	      ,[has_flags]
	      ,[is_calculated]
	      ,[created_on]
	      ,[created_by]
	      ,[archive]
	      ,[is_forecast_upload]
	      ,[file_source]
		  ,[val_proportionate]
		  ,[ownership])
	SELECT tv.[fk_organisation_id]
	      ,tv.[fk_metric_id]
	      ,tv.[fk_attribute_id]
	      ,tv.[fk_status_id]
	      ,tv.[fk_privacy_id]
	      ,tv.[date]
	      ,tv.[date_type]
	      ,tv.[val_sum]
	      ,tv.[fk_currency_id]
	      ,tv.[fk_source_id]
	      ,tv.[fk_confidence_id]
	      ,tv.[has_flags]
	      ,tv.[is_calculated]
	      ,tv.[created_on]
	      ,tv.[created_by]
	      ,tv.[archive]
	      ,tv.[is_forecast_upload] 
	      ,tv.[file_source]
	      ,tv.[val_proportionate]
	      ,tv.[ownership]
	FROM @groupDataType tv
	LEFT JOIN dbo.group_data AS atbl 
		ON  atbl.fk_organisation_id = tv.fk_organisation_id
		AND atbl.fk_metric_id = tv.fk_metric_id
		AND atbl.fk_attribute_id = tv.fk_attribute_id
		AND atbl.fk_status_id = tv.fk_status_id
		AND atbl.fk_privacy_id = tv.fk_privacy_id
		AND atbl.[date] = tv.[date]
		AND atbl.date_type = tv.date_type
		AND atbl.val_sum = tv.val_sum
		AND atbl.val_proportionate = tv.val_proportionate
		AND atbl.has_flags = tv.has_flags
		AND atbl.ownership = tv.ownership
		AND atbl.fk_currency_id = tv.fk_currency_id
		AND atbl.fk_source_id = tv.fk_source_id
		AND atbl.fk_confidence_id = tv.fk_confidence_id
		AND atbl.archive = tv.archive
	WHERE atbl.id IS NULL

	-- Collect existing ROWS and the new rows with new ID's
	INSERT INTO @groupDataLinkType
	SELECT atbl.[id],
		atbl.[fk_organisation_id]
	      ,atbl.[fk_metric_id]
	      ,atbl.[fk_attribute_id]
	      ,atbl.[fk_status_id]
	      ,atbl.[fk_privacy_id]
	      ,atbl.[date]
	      ,atbl.[date_type]
	      ,atbl.[val_sum]
	      ,atbl.[fk_currency_id]
	      ,atbl.[fk_source_id]
	      ,atbl.[fk_confidence_id]
	      ,atbl.[has_flags]
	      ,atbl.[is_calculated]
	      ,atbl.[created_on]
	      ,atbl.[created_by]
	      ,atbl.[archive]
	      ,atbl.[is_forecast_upload]
	      ,atbl.[file_source]
	      ,atbl.[val_proportionate]  
		  ,atbl.[ownership]
	FROM @groupDataType tv
	LEFT JOIN dbo.group_data AS atbl 
		ON  atbl.fk_organisation_id = tv.fk_organisation_id
		AND atbl.fk_metric_id = tv.fk_metric_id
		AND atbl.fk_attribute_id = tv.fk_attribute_id
		AND atbl.fk_status_id = tv.fk_status_id
		AND atbl.fk_privacy_id = tv.fk_privacy_id
		AND atbl.[date] = tv.[date]
		AND atbl.date_type = tv.date_type
		AND atbl.val_sum = tv.val_sum
		AND atbl.val_proportionate = tv.val_proportionate
		AND atbl.has_flags = tv.has_flags
		AND atbl.ownership = tv.ownership
		AND atbl.fk_currency_id = tv.fk_currency_id
		AND atbl.fk_source_id = tv.fk_source_id
		AND atbl.fk_confidence_id = tv.fk_confidence_id
		AND atbl.archive = tv.archive
	WHERE atbl.id IS NOT NULL

	
	EXEC [dbo].[proc_upsert_group_data_view_link] @groupDataLinkType = @groupDataLinkType, @batchDate = @batchDate, @analystTeamViewId = @analystTeamViewId, @secondAnalystTeamViewId = @secondAnalystTeamViewId

END


