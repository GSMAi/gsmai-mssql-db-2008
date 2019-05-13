CREATE PROCEDURE [dbo].[data_markets_data_empy]

(
	@zone_id int,
	@date_start datetime,
	@date_end datetime,
	@date_type char(1) = 'Q',
	@currency_id int = 1,
	@spot_historic bit = 1,
	@spot_quarter datetime = null,
	@include_countries bit = 0,
	@include_operators bit = 0
)

AS

SET FMTONLY ON

select * from dc_zone_data where id=0