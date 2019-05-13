CREATE PROCEDURE [dbo].[proc_upsert_zone_data_view_link]
@zoneDataLinkType dbo.zone_data_links_type READONLY,
@analystTeamViewId INT,
@secondAnalystTeamViewId INT = 0
AS
BEGIN
DECLARE @now datetime = GETDATE()

	BEGIN TRY
		DELETE FROM dbo.zone_data_view_link where fk_zone_data_id IN (
			SELECT od.id
			FROM dbo.zone_data_view_link as link
			LEFT JOIN @zoneDataLinkType AS tlinkCheck ON (tlinkCheck.id=link.fk_zone_data_id and link.fk_data_view_id=@analystTeamViewId)
			LEFT JOIN dbo.zone_data as od ON od.id=link.fk_zone_data_id
			LEFT JOIN @zoneDataLinkType AS tlink ON (
				od.fk_zone_id=tlink.fk_zone_id
				AND od.fk_metric_id=tlink.fk_metric_id
				AND od.fk_attribute_id=tlink.fk_attribute_id
				AND od.[date]=tlink.[date]
				AND od.date_type=tlink.date_type
				AND od.is_spot_price=tlink.is_spot_price
				AND od.fk_currency_id=tlink.fk_currency_id
			)
			where tlink.id IS NOT NULL
			and link.fk_data_view_id=@analystTeamViewId
			and tlinkCheck.id is null
		) AND fk_data_view_id = @analystTeamViewId
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_zone_data_view_link] - DELETE FROM dbo.zone_data_view_link'
	END CATCH

	BEGIN TRY
		INSERT INTO dbo.zone_data_view_link_history
		SELECT tv.id AS "fk_zone_data_id", @analystTeamViewId AS "fk_data_view_id", @now AS "created"
		FROM @zoneDataLinkType as tv
		LEFT JOIN dbo.zone_data_view_link as link ON (tv.id=link.fk_zone_data_id and link.fk_data_view_id=@analystTeamViewId)
		where link.fk_zone_data_id is null
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_zone_data_view_link] - INSERT INTO dbo.zone_data_view_link_history'
	END CATCH

	BEGIN TRY
		-- Insert link data
		INSERT INTO dbo.zone_data_view_link
		SELECT tv.id AS "fk_zone_data_id", @analystTeamViewId AS "fk_data_view_id", @now AS "created", 0 AS "archive"
		FROM @zoneDataLinkType as tv
		LEFT JOIN dbo.zone_data_view_link as link ON (tv.id=link.fk_zone_data_id and link.fk_data_view_id=@analystTeamViewId)
		where link.fk_zone_data_id is null
	END TRY  
	BEGIN CATCH  
		execute [dbo].[collect_data_insert_errors] @query_string = '[dbo].[proc_upsert_zone_data_view_link] - INSERT INTO dbo.zone_data_view_link'
	END CATCH

	
	-- custom double write requested by CV & RP
	/*IF @secondAnalystTeamViewId != 0 BEGIN
		DELETE FROM dbo.zone_data_view_link where fk_zone_data_id IN (
			SELECT od.id
			FROM dbo.zone_data_view_link as link
			LEFT JOIN @zoneDataLinkType AS tlinkCheck ON (tlinkCheck.id=link.fk_zone_data_id and link.fk_data_view_id=@secondAnalystTeamViewId)
			LEFT JOIN dbo.zone_data as od ON od.id=link.fk_zone_data_id
			LEFT JOIN @zoneDataLinkType AS tlink ON (
				od.fk_zone_id=tlink.fk_zone_id
				AND od.fk_metric_id=tlink.fk_metric_id
				AND od.fk_attribute_id=tlink.fk_attribute_id
				AND od.[date]=tlink.[date]
				AND od.date_type=tlink.date_type
				AND od.is_spot_price=tlink.is_spot_price
				AND od.fk_currency_id=tlink.fk_currency_id
			)
			where tlink.id IS NOT NULL
			and link.fk_data_view_id=@secondAnalystTeamViewId
			and tlinkCheck.id is null
		) AND fk_data_view_id = @secondAnalystTeamViewId

		-- Insert link data
		INSERT INTO dbo.zone_data_view_link
		SELECT tv.id AS "fk_zone_data_id", @secondAnalystTeamViewId AS "fk_data_view_id", @now AS "link_date" 
		FROM @zoneDataLinkType as tv
		LEFT JOIN dbo.zone_data_view_link as link ON (tv.id=link.fk_zone_data_id and link.fk_data_view_id=@secondAnalystTeamViewId)
		where link.fk_zone_data_id is null

		INSERT INTO dbo.zone_data_view_link_history
		SELECT tv.id AS "fk_zone_data_id", @secondAnalystTeamViewId AS "fk_data_view_id", @now AS "link_date" 
		FROM @zoneDataLinkType as tv
		LEFT JOIN dbo.zone_data_view_link as link ON (tv.id=link.fk_zone_data_id and link.fk_data_view_id=@secondAnalystTeamViewId)
		where link.fk_zone_data_id is null

	END*/
END
