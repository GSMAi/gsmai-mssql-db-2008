
CREATE PROCEDURE [dbo].[process_remerge_data_since]

(
	@date_since datetime,
	@organisation_data bit = 1,
	@organisation_forecast_data bit = 1,
	@zone_data bit = 1,
	@zone_forecast_data bit = 1,
	@debug bit = 1
)

AS

DECLARE @last_update_on datetime = GETDATE()

IF @debug = 1
BEGIN
	SELECT 'Data will be remerged if @debug = 0 from:'
	
	IF @organisation_data = 1
	BEGIN
		SELECT 'ds_organisatsion_data'
		SELECT * FROM wi_import.dbo.ds_organisation_data WHERE approved = 1 AND approval_hash IS NOT null AND last_update_on >= @date_since
	END
	
	IF @organisation_forecast_data = 1
	BEGIN
		SELECT 'ds_organisatsion_forecast_data'
		SELECT * FROM wi_import.dbo.ds_organisation_forecast_data WHERE approved = 1 AND approval_hash IS NOT null AND last_update_on >= @date_since
	END
	
	IF @zone_data = 1
	BEGIN
		SELECT 'ds_zone_data'
		SELECT * FROM wi_import.dbo.ds_zone_data WHERE approved = 1 AND approval_hash IS NOT null AND last_update_on >= @date_since
	END
	
	IF @zone_forecast_data = 1
	BEGIN
		SELECT 'ds_zone_forecast_data'
		SELECT * FROM wi_import.dbo.ds_zone_forecast_data WHERE approved = 1 AND approval_hash IS NOT null AND last_update_on >= @date_since
	END
END

IF @debug = 0
BEGIN
	IF @organisation_data = 1
	BEGIN
		UPDATE wi_import.dbo.ds_organisation_data SET last_update_on = @last_update_on WHERE approved = 1 AND approval_hash IS NOT null AND last_update_on >= @date_since
	END
	
	IF @organisation_forecast_data = 1
	BEGIN
		UPDATE wi_import.dbo.ds_organisation_forecast_data SET last_update_on = @last_update_on WHERE approved = 1 AND approval_hash IS NOT null AND last_update_on >= @date_since
	END
	
	IF @zone_data = 1
	BEGIN
		UPDATE wi_import.dbo.ds_zone_data SET last_update_on = @last_update_on WHERE approved = 1 AND approval_hash IS NOT null AND last_update_on >= @date_since
	END
	
	IF @zone_forecast_data = 1
	BEGIN
		UPDATE wi_import.dbo.ds_zone_forecast_data SET last_update_on = @last_update_on WHERE approved = 1 AND approval_hash IS NOT null AND last_update_on >= @date_since
	END
END
