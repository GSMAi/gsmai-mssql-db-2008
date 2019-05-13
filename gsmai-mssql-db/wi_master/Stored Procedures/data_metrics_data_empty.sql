CREATE PROCEDURE [dbo].[data_metrics_data_empty]

(
	@show tinyint,
	@zone_id int,
	@metric_id int,
	@attribute_id int,
	@type_id int,
	@date_start datetime,
	@date_end datetime,
	@date_type char(1) = 'Q',
	@currency_id int = 1,
	@spot_historic bit = 1,
	@spot_quarter datetime = null
)

AS

SET FMTONLY ON

select * from dc_zone_data where id=0