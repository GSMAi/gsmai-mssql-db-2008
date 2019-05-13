CREATE PROCEDURE [dbo].[restore_ds_data_from_wi_backups]

AS

	
SET IDENTITY_INSERT [wi_master].[dbo].[ds_organisation_data] ON
SET IDENTITY_INSERT [wi_master].[dbo].[ds_zone_data] ON
SET IDENTITY_INSERT [wi_master].[dbo].[ds_group_data] ON
SET IDENTITY_INSERT [wi_master].[dbo].[ds_group_ownership] ON
SET IDENTITY_INSERT [wi_master].[dbo].[ds_mvnos] ON
SET IDENTITY_INSERT [wi_master].[dbo].[ds_service_data] ON
SET IDENTITY_INSERT [wi_master].[dbo].[ds_survey_data] ON

-- Restore DS tables
DECLARE @backupOrganisationCount int = (SELECT COUNT(*) FROM [wi_backups].[dbo].[ds_organisation_data])
DECLARE @backupZoneCount int = (SELECT COUNT(*) FROM [wi_backups].[dbo].[ds_zone_data])
DECLARE @backupGroupCount int = (SELECT COUNT(*) FROM [wi_backups].[dbo].[ds_group_data])
DECLARE @backupGroupOwnershipCount int = (SELECT COUNT(*) FROM [wi_backups].[dbo].[ds_group_ownership])
DECLARE @backupMVNOSCount int = (SELECT COUNT(*) FROM [wi_backups].[dbo].[ds_mvnos])
DECLARE @backupServiceCount int = (SELECT COUNT(*) FROM [wi_backups].[dbo].[ds_service_data])
DECLARE @backupSurveyCount int = (SELECT COUNT(*) FROM [wi_backups].[dbo].[ds_survey_data])


	
IF @backupOrganisationCount > 0
BEGIN
	TRUNCATE TABLE [wi_master].[dbo].[ds_organisation_data];
	
	insert into [wi_master].[dbo].[ds_organisation_data]([id], [organisation_id], [metric_id], [attribute_id],[status_id],[privacy_id],[date],[date_type],[val_d],[val_i],[currency_id],[source_id],[confidence_id],[has_flags],[is_calculated],[import_id],[import_merge_hash],[created_on],[created_by],[last_update_on], [last_update_by])
	SELECT [id], [organisation_id], [metric_id], [attribute_id],[status_id],[privacy_id],[date],[date_type],[val_d],[val_i],[currency_id],[source_id],[confidence_id],[has_flags],[is_calculated],[import_id],[import_merge_hash],[created_on],[created_by],[last_update_on], [last_update_by]
	FROM [wi_backups].[dbo].[ds_organisation_data];
END


IF @backupZoneCount > 0
BEGIN
	TRUNCATE TABLE [wi_master].[dbo].[ds_zone_data];
	
	insert into [wi_master].[dbo].[ds_zone_data]([id], [zone_id], [metric_id], [attribute_id], [status_id], [privacy_id], [date], [date_type], [val_d], [val_i], [currency_id], [source_id], [confidence_id], [has_flags], [is_calculated], [is_spot], [import_id], [created_on], [created_by], [last_update_on], [last_update_by])
	SELECT [id], [zone_id], [metric_id], [attribute_id], [status_id], [privacy_id], [date], [date_type], [val_d], [val_i], [currency_id], [source_id], [confidence_id], [has_flags], [is_calculated], [is_spot], [import_id], [created_on], [created_by], [last_update_on], [last_update_by]
	FROM [wi_backups].[dbo].[ds_zone_data];
END


IF @backupGroupCount > 0
BEGIN
	TRUNCATE TABLE [wi_master].[dbo].[ds_group_data];
	
	insert into [wi_master].[dbo].[ds_group_data]([id], [organisation_id], [ownership_threshold], [metric_id], [attribute_id], [status_id], [privacy_id], [date], [date_type], [val_d], [val_i], [currency_id], [source_id], [confidence_id], [has_flags], [is_calculated], [is_proportionate], [is_spot], [import_id], [created_on], [created_by], [last_update_on], [last_update_by])
	SELECT [id], [organisation_id], [ownership_threshold], [metric_id], [attribute_id], [status_id], [privacy_id], [date], [date_type], [val_d], [val_i], [currency_id], [source_id], [confidence_id], [has_flags], [is_calculated], [is_proportionate], [is_spot], [import_id], [created_on], [created_by], [last_update_on], [last_update_by]
	FROM [wi_backups].[dbo].[ds_group_data];
END


IF @backupGroupOwnershipCount > 0
BEGIN
	TRUNCATE TABLE [wi_master].[dbo].[ds_group_ownership];
	
	insert into [wi_master].[dbo].[ds_group_ownership]([id], [group_id], [organisation_id], [metric_id], [attribute_id], [date], [date_type], [value], [is_compound], [is_consolidated], [is_group], [is_joint_venture], [source_id], [confidence_id], [definition_id], [note], [created_on], [created_by], [last_update_on], [last_update_by])
	SELECT [id], [group_id], [organisation_id], [metric_id], [attribute_id], [date], [date_type], [value], [is_compound], [is_consolidated], [is_group], [is_joint_venture], [source_id], [confidence_id], [definition_id], [note], [created_on], [created_by], [last_update_on], [last_update_by]
	FROM [wi_backups].[dbo].[ds_group_ownership];
END

IF @backupMVNOSCount > 0
BEGIN
	TRUNCATE TABLE [wi_master].[dbo].[ds_mvnos];
	
	insert into [wi_master].[dbo].[ds_mvnos]([id], [mvno_id], [category_id], [tariff_type_id], [launch_date], [url], [is_brand], [is_data_only], [has_data], [has_group_data], [created_on], [created_by], [last_update_on], [last_update_by], [is_branded_reseller], [full_mvno], [note], [secondary_category_id])
	SELECT [id], [mvno_id], [category_id], [tariff_type_id], [launch_date], [url], [is_brand], [is_data_only], [has_data], [has_group_data], [created_on], [created_by], [last_update_on], [last_update_by], [is_branded_reseller], [full_mvno], [note], [secondary_category_id]
	FROM [wi_backups].[dbo].[ds_mvnos];
END

IF @backupServiceCount > 0
BEGIN
	TRUNCATE TABLE [wi_master].[dbo].[ds_service_data];
	
	insert into [wi_master].[dbo].[ds_service_data]([id], [service_id], [metric_id], [attribute_id], [status_id], [privacy_id], [date], [date_type], [val_d], [val_i], [currency_id], [source_id], [confidence_id], [has_flags], [is_calculated], [import_id], [import_merge_hash], [created_on], [created_by], [last_update_on], [last_update_by])
	SELECT [id], [service_id], [metric_id], [attribute_id], [status_id], [privacy_id], [date], [date_type], [val_d], [val_i], [currency_id], [source_id], [confidence_id], [has_flags], [is_calculated], [import_id], [import_merge_hash], [created_on], [created_by], [last_update_on], [last_update_by]
	FROM [wi_backups].[dbo].[ds_service_data];
END

IF @backupSurveyCount > 0
BEGIN
	TRUNCATE TABLE [wi_master].[dbo].[ds_survey_data];
	
	insert into [wi_master].[dbo].[ds_survey_data]([id], [survey_id], [zone_id], [respondent_id], [acquisition_type_id], [question_number_major], [question_number_minor], [val_i], [val_t])
	SELECT [id], [survey_id], [zone_id], [respondent_id], [acquisition_type_id], [question_number_major], [question_number_minor], [val_i], [val_t]
	FROM [wi_backups].[dbo].[ds_survey_data];
	
END

	
SET IDENTITY_INSERT [wi_master].[dbo].[ds_organisation_data] OFF
SET IDENTITY_INSERT [wi_master].[dbo].[ds_zone_data] OFF
SET IDENTITY_INSERT [wi_master].[dbo].[ds_group_data] OFF
SET IDENTITY_INSERT [wi_master].[dbo].[ds_group_ownership] OFF
SET IDENTITY_INSERT [wi_master].[dbo].[ds_mvnos] OFF
SET IDENTITY_INSERT [wi_master].[dbo].[ds_service_data] OFF
SET IDENTITY_INSERT [wi_master].[dbo].[ds_survey_data] OFF
