CREATE PROCEDURE [dbo].[proc_upsert_group_data_view_link]
@groupDataLinkType dbo.group_data_links_type READONLY,
@batchDate DATETIME,
@analystTeamViewId INT,
@secondAnalystTeamViewId INT = 0
AS
BEGIN
DECLARE @now datetime = GETUTCDATE()

	DELETE FROM dbo.group_data_view_link where fk_group_data_id IN (
		SELECT od.id
		FROM dbo.group_data_view_link as link
		LEFT JOIN @groupDataLinkType AS tlinkCheck ON (tlinkCheck.id=link.fk_group_data_id and link.fk_data_view_id=@analystTeamViewId)
		LEFT JOIN dbo.group_data as od ON od.id=link.fk_group_data_id
		LEFT JOIN @groupDataLinkType AS tlink ON (
			od.fk_organisation_id=tlink.fk_organisation_id
			AND od.fk_metric_id=tlink.fk_metric_id
			AND od.fk_attribute_id=tlink.fk_attribute_id
			AND od.[date]=tlink.[date]
			AND od.date_type=tlink.date_type
			AND od.ownership = tlink.ownership
		)
		where tlink.id IS NOT NULL
		and link.fk_data_view_id=@analystTeamViewId
		and tlinkCheck.id is null
		--and link.link_date<@batchDate
	) AND fk_data_view_id = @analystTeamViewId

	BEGIN TRY
		INSERT INTO dbo.group_data_view_link_history
		SELECT tv.id AS "fk_group_data_id", @analystTeamViewId AS "fk_data_view_id", @now AS "link_date" 
		FROM @groupDataLinkType as tv
		LEFT JOIN dbo.group_data_view_link as link ON (tv.id=link.fk_group_data_id and link.fk_data_view_id=@analystTeamViewId)
		where link.fk_group_data_id is null
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_group_data_view_link] - INSERT INTO dbo.group_data_view_link_history'
	END CATCH

	BEGIN TRY
		-- Insert link data
		INSERT INTO dbo.group_data_view_link
		SELECT tv.id AS "fk_group_data_id", @analystTeamViewId AS "fk_data_view_id", @now AS "link_date", 0 AS "archive" 
		FROM @groupDataLinkType as tv
		LEFT JOIN dbo.group_data_view_link as link ON (tv.id=link.fk_group_data_id and link.fk_data_view_id=@analystTeamViewId)
		where link.fk_group_data_id is null
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_group_data_view_link] - INSERT INTO dbo.group_data_view_link'
	END CATCH

	
	-- custom double write requested by CV & RP
	/*IF @secondAnalystTeamViewId != 0 BEGIN
		DELETE FROM dbo.group_data_view_link where fk_group_data_id IN (
			SELECT od.id
			FROM dbo.group_data_view_link as link
			LEFT JOIN @groupDataLinkType AS tlinkCheck ON (tlinkCheck.id=link.fk_group_data_id and link.fk_data_view_id=@secondAnalystTeamViewId)
			LEFT JOIN dbo.group_data as od ON od.id=link.fk_group_data_id
			LEFT JOIN @groupDataLinkType AS tlink ON (
				od.fk_organisation_id=tlink.fk_organisation_id
				AND od.fk_metric_id=tlink.fk_metric_id
				AND od.fk_attribute_id=tlink.fk_attribute_id
				AND od.[date]=tlink.[date]
				AND od.date_type=tlink.date_type
			)
			where tlink.id IS NOT NULL
			and link.fk_data_view_id=@secondAnalystTeamViewId
			and tlinkCheck.id is null
			and link.link_date<@batchDate
		) AND fk_data_view_id = @secondAnalystTeamViewId

		-- Insert link data
		INSERT INTO dbo.group_data_view_link
		SELECT tv.id AS "fk_group_data_id", @secondAnalystTeamViewId AS "fk_data_view_id", @now AS "link_date" 
		FROM @groupDataLinkType as tv
		LEFT JOIN dbo.group_data_view_link as link ON (tv.id=link.fk_group_data_id and link.fk_data_view_id=@secondAnalystTeamViewId)
		where link.fk_group_data_id is null

		INSERT INTO dbo.group_data_view_link_history
		SELECT tv.id AS "fk_group_data_id", @secondAnalystTeamViewId AS "fk_data_view_id", @now AS "link_date" 
		FROM @groupDataLinkType as tv
		LEFT JOIN dbo.group_data_view_link as link ON (tv.id=link.fk_group_data_id and link.fk_data_view_id=@secondAnalystTeamViewId)
		where link.fk_group_data_id is null
	END*/
	
END


