CREATE PROCEDURE [dbo].[backup_ds_tables]

(
	@dateObject datetime
)

AS

-- Clear up backup tables
execute [dbo].[clear_backup_ds_tables];


-- Backup DS tables
insert into [wi_backups].[dbo].[ds_organisation_data]
SELECT od.*, @dateObject
FROM [wi_master].[dbo].[ds_organisation_data] as od;


insert into [wi_backups].[dbo].[ds_zone_data]
SELECT zd.*, @dateObject
FROM [wi_master].[dbo].[ds_zone_data] as zd;


insert into [wi_backups].[dbo].[ds_group_data]
SELECT gd.*, @dateObject
FROM [wi_master].[dbo].[ds_group_data] as gd;


insert into [wi_backups].[dbo].[ds_group_ownership]
SELECT go.*, @dateObject
FROM [wi_master].[dbo].[ds_group_ownership] as go;


insert into [wi_backups].[dbo].[ds_mvnos]
SELECT mvn.*, @dateObject
FROM [wi_master].[dbo].[ds_mvnos] as mvn;


insert into [wi_backups].[dbo].[ds_service_data]
SELECT sd.*, @dateObject
FROM [wi_master].[dbo].[ds_service_data] as sd;


insert into [wi_backups].[dbo].[ds_survey_data]
SELECT sd.*, @dateObject
FROM [wi_master].[dbo].[ds_survey_data] as sd;

