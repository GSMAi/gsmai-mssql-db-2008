
CREATE FUNCTION [dbo].[metric_is_currency_based]

(
	@metric_id int
)

RETURNS bit

AS
BEGIN
	RETURN CASE (SELECT currency_based FROM metrics WHERE id = @metric_id) WHEN 1 THEN 1 ELSE 0 END
END
