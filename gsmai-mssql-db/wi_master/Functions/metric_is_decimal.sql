
CREATE FUNCTION [dbo].[metric_is_decimal]

(
	@metric_id int
)

RETURNS bit

AS
BEGIN
	RETURN CASE (SELECT type_id FROM metrics WHERE id = @metric_id) WHEN 856 THEN 1 ELSE 0 END
END
