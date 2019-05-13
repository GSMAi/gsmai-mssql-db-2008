
CREATE FUNCTION [dbo].[datetime_to_excel_serial]

(
	@date datetime
)

RETURNS int

AS
BEGIN
	RETURN DATEDIFF(second, {d '1970-01-01'}, @date) / 86400 + 25569	-- To unix timestamp, then serial conversion (TODO: will overflow when @date >~ 2040-01-01)
END