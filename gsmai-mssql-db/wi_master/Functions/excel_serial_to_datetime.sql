
CREATE FUNCTION [dbo].[excel_serial_to_datetime]

(
	@serial int
)

RETURNS datetime

AS
BEGIN
	RETURN DATEADD(second, (@serial - 25569) * 86400, {d '1970-01-01'})	-- To unix timestamp, then datetime conversion
END