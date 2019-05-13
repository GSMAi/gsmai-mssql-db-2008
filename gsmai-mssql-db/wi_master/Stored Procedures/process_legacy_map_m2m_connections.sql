CREATE PROCEDURE [dbo].[process_legacy_map_m2m_connections] 

(
	@debug bit = 1
)

AS

IF @debug = 0
BEGIN
	-- Switch the metric_id for M2M connections imports from "excluding M2M" to "including M2M"
	-- TODO: remove when updating the import format/data set

	UPDATE wi_import.dbo.ds_organisation_data SET metric_id = 190 WHERE metric_id = 3 AND attribute_id IN (1251,1546,1547,1548,1549,1550)
	
	UPDATE wi_import.dbo.ds_organisation_forecast_data SET metric_id = 190 WHERE metric_id = 3 AND attribute_id IN (1251,1546,1547,1548,1549,1550)
	UPDATE wi_import.dbo.ds_organisation_forecast_data SET metric_id = 312 WHERE metric_id = 53 AND attribute_id IN (1251,1546,1547,1548,1549,1550)
END
