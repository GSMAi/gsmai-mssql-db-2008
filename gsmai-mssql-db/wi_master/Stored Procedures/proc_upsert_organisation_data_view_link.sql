CREATE PROCEDURE [dbo].[proc_upsert_organisation_data_view_link]
@organisationDataLinkType dbo.organisation_data_links_type READONLY,
@analystTeamViewId INT,
@secondAnalystTeamViewId INT = 0
AS
BEGIN
DECLARE @now datetime = GETDATE()
	
	BEGIN TRY
		DELETE FROM dbo.organisation_data_view_link where fk_organisation_data_id IN (
			SELECT od.id
			FROM dbo.organisation_data_view_link as link
			LEFT JOIN @organisationDataLinkType AS tlinkCheck ON (tlinkCheck.id=link.fk_organisation_data_id and link.fk_data_view_id=@analystTeamViewId)
			LEFT JOIN dbo.organisation_data as od ON od.id=link.fk_organisation_data_id
			LEFT JOIN @organisationDataLinkType AS tlink ON (
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


		/*UPDATE dbo.organisation_data_view_link SET archive=1
		WHERE fk_organisation_data_id IN (
			SELECT od.id
			FROM dbo.organisation_data_view_link as link
			LEFT JOIN @organisationDataLinkType AS tlinkCheck ON (tlinkCheck.id=link.fk_organisation_data_id and link.fk_data_view_id=@analystTeamViewId)
			LEFT JOIN dbo.organisation_data as od ON od.id=link.fk_organisation_data_id
			LEFT JOIN @organisationDataLinkType AS tlink ON (
				od.fk_organisation_id=tlink.fk_organisation_id
				AND od.fk_metric_id=tlink.fk_metric_id
				AND od.fk_attribute_id=tlink.fk_attribute_id
				AND od.[date]=tlink.[date]
				AND od.date_type=tlink.date_type
			)
			where tlink.id IS NOT NULL
			and link.fk_data_view_id=@analystTeamViewId
			and link.archive=0
			and tlinkCheck.id is null
		) AND fk_data_view_id = @analystTeamViewId and archive=0*/
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_organisation_data_view_link] - DELETE FROM dbo.organisation_data_view_link'
	END CATCH


	-- Log TVP count
	/*DECLARE @orgcount int
	set @orgcount = (select count(*) from @organisationDataLinkType)
	declare @message char(20)
	set @message = cast(@orgcount AS char(20)) 
	execute [dbo].[collect_data_insert_errors] @query_string = @message*/
	------------------------------------------------------------------

	-- Log TVP count
	/*DECLARE @orgcount4 int
	set @orgcount4 = (SELECT count(tv.id) 
		FROM @organisationDataLinkType as tv
		LEFT JOIN dbo.organisation_data_view_link as link ON (tv.id=link.fk_organisation_data_id and link.fk_data_view_id=@analystTeamViewId)
		where link.fk_organisation_data_id is null)
	declare @message4 char(20)
	set @message4 = cast(@orgcount4 AS char(20)) 
	execute [dbo].[collect_data_insert_errors] @query_string = @message4*/
	------------------------------------------------------------------

	BEGIN TRY
		INSERT INTO dbo.organisation_data_view_link_history
		SELECT tv.id AS "fk_organisation_data_id", @analystTeamViewId AS "fk_data_view_id", @now AS "link_date" 
		FROM @organisationDataLinkType as tv
		LEFT JOIN dbo.organisation_data_view_link as link ON (tv.id=link.fk_organisation_data_id and link.fk_data_view_id=@analystTeamViewId)
		where link.fk_organisation_data_id is null

		-- Log TVP count after history insert
		/*DECLARE @orgcount3 int
		set @orgcount3 = (select count(*) from @organisationDataLinkType)
		declare @message3 char(20)
		set @message3 = cast(@orgcount3 AS char(20)) 
		execute [dbo].[collect_data_insert_errors] @query_string = @message3*/
		------------------------------------------------------------------
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[organisation_data_view_link_history] - INSERT INTO dbo.organisation_data_view_link_history'
	END CATCH

	BEGIN TRY
		-- Insert link data
		INSERT INTO dbo.organisation_data_view_link
		SELECT tv.id AS "fk_organisation_data_id", @analystTeamViewId AS "fk_data_view_id", @now AS "link_date", 0 AS "archive"
		FROM @organisationDataLinkType as tv
		LEFT JOIN dbo.organisation_data_view_link as link ON (tv.id=link.fk_organisation_data_id and link.fk_data_view_id=@analystTeamViewId)
		where link.fk_organisation_data_id is null
	END TRY  
	BEGIN CATCH  


		/*INSERT INTO dbo.organisation_data_tmp
		SELECT [id],
			[fk_organisation_id]
		      ,[fk_metric_id]
		      ,[fk_attribute_id]
		      ,[fk_status_id]
		      ,[fk_privacy_id]
		      ,[date]
		      ,[date_type]
		      ,[val]
		      ,[fk_currency_id]
		      ,[fk_source_id]
		      ,[fk_confidence_id]
		      ,[has_flags]
		      ,[is_calculated]
		      ,[created_on]
		      ,[created_by]
		      ,[archive]
		      ,[is_forecast_upload]
		      ,[file_source]  FROM @organisationDataLinkType*/


		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_organisation_data_view_link] - INSERT INTO dbo.organisation_data_view_link'
	END CATCH

	-- Log TVP count after insert
	/*DECLARE @orgcount2 int
	set @orgcount2 = (select count(*) from @organisationDataLinkType)
	declare @message2 char(20)
	set @message2 = cast(@orgcount2 AS char(20)) 
	execute [dbo].[collect_data_insert_errors] @query_string = @message2*/
	------------------------------------------------------------------
	

	/*BEGIN TRY
		-- custom double write requested by CV & RP
		IF @secondAnalystTeamViewId != 0 BEGIN
			DELETE FROM dbo.organisation_data_view_link where fk_organisation_data_id IN (
				SELECT od.id
				FROM dbo.organisation_data_view_link as link
				LEFT JOIN @organisationDataLinkType AS tlinkCheck ON (tlinkCheck.id=link.fk_organisation_data_id and link.fk_data_view_id=@secondAnalystTeamViewId)
				LEFT JOIN dbo.organisation_data as od ON od.id=link.fk_organisation_data_id
				LEFT JOIN @organisationDataLinkType AS tlink ON (
					od.fk_organisation_id=tlink.fk_organisation_id
					AND od.fk_metric_id=tlink.fk_metric_id
					AND od.fk_attribute_id=tlink.fk_attribute_id
					AND od.[date]=tlink.[date]
					AND od.date_type=tlink.date_type
				)
				where tlink.id IS NOT NULL
				and link.fk_data_view_id=@secondAnalystTeamViewId
				and tlinkCheck.id is null
			) AND fk_data_view_id = @secondAnalystTeamViewId

			-- Insert link data
			INSERT INTO dbo.organisation_data_view_link
			SELECT tv.id AS "fk_organisation_data_id", @secondAnalystTeamViewId AS "fk_data_view_id", @now AS "link_date" 
			FROM @organisationDataLinkType as tv
			LEFT JOIN dbo.organisation_data_view_link as link ON (tv.id=link.fk_organisation_data_id and link.fk_data_view_id=@secondAnalystTeamViewId)
			where link.fk_organisation_data_id is null

			INSERT INTO dbo.organisation_data_view_link_history
			SELECT tv.id AS "fk_organisation_data_id", @secondAnalystTeamViewId AS "fk_data_view_id", @now AS "link_date" 
			FROM @organisationDataLinkType as tv
			LEFT JOIN dbo.organisation_data_view_link as link ON (tv.id=link.fk_organisation_data_id and link.fk_data_view_id=@secondAnalystTeamViewId)
			where link.fk_organisation_data_id is null
		END
	
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_organisation_data_view_link] secondAnalystTeamViewId'
	END CATCH*/

	
END
