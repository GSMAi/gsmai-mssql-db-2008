CREATE PROCEDURE [dbo].[recache_dc_tables]

(
	@gsmaiStartDate char(10) = '2000-01-01',
	@beginingOfTimeDate char(10) = '1950-01-01',
	@reportingModel char(10) = '2026-01-01'
)

AS

IF ( SELECT COUNT(*) FROM wi_master.dbo.sp_run_error_log WHERE date >= DATEADD(hour, -5, GETDATE()) ) = 0
BEGIN
	EXEC wi_master.dbo.process_recache_organisation_data @gsmaiStartDate, @reportingModel
	EXEC wi_master.dbo.process_recache_zone_data @beginingOfTimeDate, @reportingModel
	EXEC wi_master.dbo.process_recache_group_data @gsmaiStartDate, @reportingModel
	EXEC wi_master.dbo.process_recache_dashboard_data
	
	-- Removing CAPEX data - Business requirement came from Kavi
	DELETE FROM wi_master.dbo.dc_organisation_data WHERE metric_id=333 and attribute_id=0 and source_id IN (3,22)
	
	-- Clear up backup tables
	execute [dbo].[clear_backup_ds_tables];
END ELSE BEGIN
	
	-- Restore DS from backup
	--execute [dbo].[restore_ds_data_from_wi_backups];
	--execute [dbo].[clear_backup_ds_tables];

	execute wi_master.dbo.[collect_errors] @query_string = "Recache Failed"
END
