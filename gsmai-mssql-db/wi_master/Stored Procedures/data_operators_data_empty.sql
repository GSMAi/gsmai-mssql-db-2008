CREATE PROCEDURE [dbo].[data_operators_data_empty]

(
	@organisation_id int,
	@date_start datetime,
	@date_end datetime,
	@date_type char(1) = 'Q',
	@currency_id int = 0,
	@spot_historic bit = 0,
	@spot_quarter datetime = null
)

AS

SET FMTONLY ON

select * from dc_zone_data where id=0