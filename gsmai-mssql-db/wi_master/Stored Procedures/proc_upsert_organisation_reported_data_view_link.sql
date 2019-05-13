CREATE PROCEDURE [dbo].[proc_upsert_organisation_reported_data_view_link]
@organisationReportedDataLinkType dbo.organisation_reported_data_links_type READONLY,
@analystTeamViewId INT
AS
BEGIN

DECLARE @now datetime = GETUTCDATE()
	
	BEGIN TRY
		DELETE FROM dbo.organisation_data_metadata where fk_organisation_data_id IN (
			SELECT od.id FROM @organisationReportedDataLinkType as od
		)

		DELETE FROM dbo.organisation_data_flags_link where fk_organisation_data_id IN (
			SELECT od.id FROM @organisationReportedDataLinkType as od
		)
		
		DELETE FROM dbo.organisation_data_view_link where fk_organisation_data_id IN (
			SELECT od.id
			FROM dbo.organisation_data_view_link as link
			LEFT JOIN @organisationReportedDataLinkType AS tlinkCheck ON tlinkCheck.id=link.fk_organisation_data_id
			LEFT JOIN dbo.organisation_data as od ON od.id=link.fk_organisation_data_id
			LEFT JOIN @organisationReportedDataLinkType AS tlink ON (
				od.fk_organisation_id=tlink.fk_organisation_id
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
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_organisation_reported_data_view_link] - DELETE FROM dbo.organisation_data_view_link'
	END CATCH


	BEGIN TRY
		INSERT INTO dbo.organisation_data_view_link_history
		SELECT tv.id AS "fk_organisation_data_id", @analystTeamViewId AS "fk_data_view_id", @now AS "link_date" 
		FROM @organisationReportedDataLinkType as tv
		LEFT JOIN dbo.organisation_data_view_link as link ON (tv.id=link.fk_organisation_data_id and link.fk_data_view_id=@analystTeamViewId)
		where link.fk_organisation_data_id is null
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_organisation_reported_data_view_link] - INSERT INTO dbo.organisation_data_view_link_history'
	END CATCH


	-- Insert link data
	BEGIN TRY
		INSERT INTO dbo.organisation_data_view_link
		SELECT tv.id AS "fk_organisation_data_id", @analystTeamViewId AS "fk_data_view_id", @now AS "link_date", 0 AS "archive"
		FROM @organisationReportedDataLinkType as tv
		LEFT JOIN dbo.organisation_data_view_link as link ON (tv.id=link.fk_organisation_data_id and link.fk_data_view_id=@analystTeamViewId)
		where link.fk_organisation_data_id is null
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_organisation_reported_data_view_link] - INSERT INTO dbo.organisation_data_view_link'
	END CATCH
	

	BEGIN TRY
		INSERT INTO dbo.organisation_data_metadata (fk_organisation_data_id, location, location_cleaned, definition, notes)
		SELECT od.id, od.location, od.location_cleaned, od.definition, od.notes
		FROM @organisationReportedDataLinkType as od
		LEFT JOIN dbo.organisation_data_metadata as link ON (od.id=link.fk_organisation_data_id)
		where link.fk_organisation_data_id is null
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_organisation_reported_data_view_link] - INSERT INTO dbo.organisation_data_metadata'
	END CATCH


	BEGIN TRY
		INSERT INTO dbo.organisation_data_flags_link (fk_organisation_data_id, fk_flag_id)
		SELECT od.id, od.fk_flag_id
		FROM @organisationReportedDataLinkType as od 
		LEFT JOIN dbo.organisation_data_flags_link as link ON (od.id=link.fk_organisation_data_id)
		where od.fk_flag_id is not null AND link.fk_organisation_data_id is null
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_organisation_reported_data_view_link] - INSERT INTO dbo.organisation_data_flags_link'
	END CATCH

END


