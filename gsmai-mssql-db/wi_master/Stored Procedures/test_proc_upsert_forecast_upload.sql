
CREATE PROC [dbo].[test_proc_upsert_forecast_upload]
AS
BEGIN
DECLARE @organisationDataType dbo.organisation_data_type;

INSERT INTO @organisationDataType ( 
	fk_organisation_id, 
	fk_metric_id, 
	fk_attribute_id, 
	fk_status_id, 
	fk_privacy_id, 
	[date], 
	date_type, 
	val, 
	fk_currency_id, 
	fk_confidence_id,
	has_flags,
	is_calculated,
	created_on,
	created_by,
	archive,
	is_forecast_upload )
select top 1 
	od.fk_organisation_id, 
	od.fk_metric_id, 
	od.fk_attribute_id, 
	od.fk_status_id, 
	od.fk_privacy_id, 
	od.[date], 
	od.date_type, 
	od.val, 
	od.fk_currency_id, 
	od.fk_confidence_id,
	od.has_flags,
	od.is_calculated,
	od.created_on,
	od.created_by,
	od.archive,
	od.is_forecast_upload
from organisation_data as od

exec [dbo].[proc_upsert_forecast_upload] @organisationDataType, @analystTeamViewId = 1
END
