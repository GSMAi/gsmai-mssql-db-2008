CREATE PROCEDURE [dbo].[clear_backup_ds_tables]

AS

-- Clear up backup tables
TRUNCATE TABLE [wi_backups].[dbo].[ds_organisation_data];
TRUNCATE TABLE [wi_backups].[dbo].[ds_zone_data];
TRUNCATE TABLE [wi_backups].[dbo].[ds_group_data];
TRUNCATE TABLE [wi_backups].[dbo].[ds_group_ownership];
TRUNCATE TABLE [wi_backups].[dbo].[ds_mvnos];
TRUNCATE TABLE [wi_backups].[dbo].[ds_service_data];
TRUNCATE TABLE [wi_backups].[dbo].[ds_survey_data];

