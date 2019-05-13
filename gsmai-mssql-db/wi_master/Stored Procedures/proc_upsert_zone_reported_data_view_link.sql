﻿CREATE PROCEDURE [dbo].[proc_upsert_zone_reported_data_view_link]
@zoneReportedDataLinkType dbo.zone_reported_data_links_type READONLY,
@analystTeamViewId INT
AS
BEGIN

DECLARE @now datetime = GETDATE()
	
	BEGIN TRY
		DELETE FROM dbo.zone_data_metadata where fk_zone_data_id IN (
			SELECT od.id FROM @zoneReportedDataLinkType as od
		)

		DELETE FROM dbo.zone_data_flags_link where fk_zone_data_id IN (
			SELECT od.id FROM @zoneReportedDataLinkType as od
		)
		
		DELETE FROM dbo.zone_data_view_link where fk_zone_data_id IN (
			SELECT od.id
			FROM dbo.zone_data_view_link as link
			LEFT JOIN @zoneReportedDataLinkType AS tlinkCheck ON (tlinkCheck.id=link.fk_zone_data_id and link.fk_data_view_id=@analystTeamViewId)
			LEFT JOIN dbo.zone_data as od ON od.id=link.fk_zone_data_id
			LEFT JOIN @zoneReportedDataLinkType AS tlink ON (
				od.fk_zone_id=tlink.fk_zone_id
				AND od.fk_metric_id=tlink.fk_metric_id
				AND od.fk_attribute_id=tlink.fk_attribute_id
				AND od.[date]=tlink.[date]
				AND od.date_type=tlink.date_type
			)
			where tlink.id IS NOT NULL
			and link.fk_data_view_id=@analystTeamViewId
			and tlinkCheck.id is null
		) AND fk_data_view_id = @analystTeamViewId
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_zone_reported_data_view_link] - DELETE FROM dbo.zone_data_view_link'
	END CATCH

	
	BEGIN TRY
		INSERT INTO dbo.zone_data_view_link_history
		SELECT tv.id AS "fk_zone_data_id", @analystTeamViewId AS "fk_data_view_id", @now AS "link_date" 
		FROM @zoneReportedDataLinkType as tv
		LEFT JOIN dbo.zone_data_view_link as link ON (tv.id=link.fk_zone_data_id and link.fk_data_view_id=@analystTeamViewId)
		where link.fk_zone_data_id is null
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_zone_reported_data_view_link] - INSERT INTO dbo.zone_data_view_link_history'
	END CATCH


	-- Insert link data
	BEGIN TRY
		INSERT INTO dbo.zone_data_view_link
		SELECT tv.id AS "fk_zone_data_id", @analystTeamViewId AS "fk_data_view_id", @now AS "link_date", 0 AS "archive"
		FROM @zoneReportedDataLinkType as tv
		LEFT JOIN dbo.zone_data_view_link as link ON (tv.id=link.fk_zone_data_id and link.fk_data_view_id=@analystTeamViewId)
		where link.fk_zone_data_id is null
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_zone_reported_data_view_link] - INSERT INTO dbo.zone_data_view_link'
	END CATCH

	
	BEGIN TRY
		INSERT INTO dbo.zone_data_metadata (fk_zone_data_id, location, location_cleaned, definition, notes)
		SELECT od.id, od.location, od.location_cleaned, od.definition, od.notes
		FROM @zoneReportedDataLinkType as od
		LEFT JOIN dbo.zone_data_metadata as link ON (od.id=link.fk_zone_data_id)
		where link.fk_zone_data_id is null
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_zone_reported_data_view_link] - INSERT INTO dbo.zone_data_metadata'
	END CATCH


	BEGIN TRY
		INSERT INTO dbo.zone_data_flags_link (fk_zone_data_id, fk_flag_id)
		SELECT od.id, od.fk_flag_id
		FROM @zoneReportedDataLinkType as od
		LEFT JOIN dbo.zone_data_flags_link as link ON (od.id=link.fk_zone_data_id)
		where link.fk_zone_data_id is null
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_zone_reported_data_view_link] - INSERT INTO dbo.zone_data_flags_link'
	END CATCH

END


