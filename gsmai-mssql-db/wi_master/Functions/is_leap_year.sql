
CREATE FUNCTION [dbo].[is_leap_year]

(
	@year int
)

RETURNS bit

AS
BEGIN
	RETURN CASE WHEN (@year % 4 = 0 AND @year % 100 <> 0) OR @year % 400 = 0 THEN 1 ELSE 0 END
END
