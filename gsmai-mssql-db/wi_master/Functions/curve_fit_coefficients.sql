
CREATE FUNCTION [dbo].[curve_fit_coefficients]
(
	@xy_data xy_data READONLY,
	@type char(8) = 'linear'
)

RETURNS @p TABLE (a float, b float, c float, d float, r2 float)

AS

/*  Accepts @xy_data TABLE(x, y), @type for fit:
 *
 *  @type		Curve fit			Equation
 *  linear		Linear				y = a + b*x
 *  exp			Exponential			y = a*e^(b*x)						(for a > 0)
 *  log			Logarithmic			y = a + b*ln(x)
 *  power		Power				y = a*x^b							(for a > 0)
 *  poly2		Polynomial^2		y = a + b*x + c*x^2
 *  poly3		Polynomial^3		y = a + b*x + c*x^2 + d*x^3
 *  polyn		Polynomial^n		y = a + b*x + c*x^2 + ... + z*x^n	(n > 3 requires additional return columns, not implemented)
 */

BEGIN
	DECLARE	@n float, @x float, @x2 float, @y float, @xy float, @y2 float, @cf float, @a float, @b float, @c float, @d float, @r2 float

	IF LEFT(@type, 4) = 'poly'
	BEGIN
		-- Evaluate polynomial fit
		DECLARE @order int = CAST(REPLACE(@type, 'poly', '') AS int)
		DECLARE @r TABLE (power_x int, coefficient float, r2 float)

		IF @order < 2
			RETURN
		
		INSERT INTO @r
		SELECT * FROM dbo.curve_fit_polynomial_coefficients(@xy_data, @order)

		SELECT	@a	= (SELECT coefficient FROM @r WHERE power_x = 0),
				@b	= (SELECT coefficient FROM @r WHERE power_x = 1),
				@c  = (SELECT coefficient FROM @r WHERE power_x = 2),
				@d  = CASE WHEN @order > 2 THEN (SELECT coefficient FROM @r WHERE power_x = 3) ELSE null END,
				@r2 = (SELECT r2 FROM @r WHERE power_x = 0)
	END
	ELSE
	BEGIN
		-- Evaluate linear or log()~linear fits
		SELECT	@n =	COUNT(*),
				@x =	CASE
							WHEN @type = 'log'		THEN SUM(LOG(x))
							WHEN @type = 'power'	THEN SUM(LOG(x))
							ELSE					SUM(x)
						END,
				@x2 =	CASE
							WHEN @type = 'log'		THEN SUM(LOG(x) * LOG(x))
							WHEN @type = 'power'	THEN SUM(LOG(x) * LOG(x))
							ELSE					SUM(x * x)
						END,
				@y =	CASE
							WHEN @type = 'exp'		THEN SUM(LOG(y))
							WHEN @type = 'log'		THEN SUM(y)
							WHEN @type = 'power'	THEN SUM(LOG(y))
							ELSE					SUM(y)
						END,
				@xy =	CASE
							WHEN @type = 'exp'		THEN SUM(x * LOG(y))
							WHEN @type = 'log'		THEN SUM(LOG(x) * y)
							WHEN @type = 'power'	THEN SUM(LOG(x) * LOG(y))
							ELSE					SUM(x * y)
						END,
				@y2 =	CASE
							WHEN @type = 'exp'		THEN SUM(LOG(y) * LOG(y))
							WHEN @type = 'power'	THEN SUM(LOG(y) * LOG(y))
							ELSE					SUM(y * y)
						END,
				@cf =	@n * @x2 - @x * @x
		FROM	@xy_data

		IF @cf = 0
			RETURN

		SELECT	@a	= (@x2 * @y - @x * @xy) / @cf,
				@b	= (@n * @xy - @x * @y) / @cf,
				@c  = null,
				@d  = null,
				@r2 = (@a * @y + @b * @xy - @y * @y / @n) / (@y2 - @y * @y / @n)
	END

	INSERT	@p
	SELECT	CASE
				WHEN @type = 'exp'		THEN EXP(@a)
				WHEN @type = 'power'	THEN EXP(@a)
				ELSE					@a
			END,
			@b, @c, @d, @r2

	RETURN
END
