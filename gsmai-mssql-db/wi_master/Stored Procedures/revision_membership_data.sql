CREATE PROCEDURE [dbo].[revision_membership_data]

(
	@date datetime,
	@date_type char(1) = 'Q'
)

AS

	DECLARE @revision_id int, @revision datetime

	SET @revision 		= GETDATE()
	SET @revision_id	= (SELECT MAX(revision_id) FROM wi_revisions.gsma.ds_membership_data) + 1

	INSERT INTO wi_revisions.gsma.ds_membership_data (revision_id, revision, organisation_id, group_id, date, date_type, connections, connections_source, connections_tier, revenue, revenue_currency, revenue_source, revenue_attribute, revenue_normalised, revenue_tier, tier, votes, votes_adjusted, dues, dues_adjusted, dues_currency, is_member, is_special_case, created_on, created_by, last_update_on, last_update_by)
	SELECT	@revision_id, @revision, organisation_id, group_id, date, date_type, connections, connections_source, connections_tier, revenue, revenue_currency, revenue_source, revenue_attribute, revenue_normalised, revenue_tier, tier, votes, votes_adjusted, dues, dues_adjusted, dues_currency, is_member, is_special_case, created_on, created_by, last_update_on, last_update_by
	FROM	gsma.ds_membership_data
	WHERE	date = @date AND date_type = @date_type

	-- Remove existing data set for this period
	DELETE FROM gsma.ds_membership_data WHERE date = @date