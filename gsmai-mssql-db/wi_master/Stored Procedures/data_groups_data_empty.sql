CREATE PROCEDURE [dbo].[data_groups_data_empty]

(
	@organisation_id int,
	@date_start datetime,
	@date_end datetime,
	@date_type char(1) = 'Q',
	@ownership_threshold decimal(6,4) = 0.0,
	@is_proportionate bit = 0,
	@currency_id int = 1,
	@spot_historic bit = 1,
	@spot_quarter datetime = null
)

AS

SET FMTONLY ON

select * from dc_zone_data where id=0