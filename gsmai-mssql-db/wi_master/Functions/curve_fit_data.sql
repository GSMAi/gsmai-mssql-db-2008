
CREATE FUNCTION [dbo].[curve_fit_data]
(
	@xy_data xy_data READONLY,
	@xy_coefficients xy_coefficients READONLY,
	@type char(8) = 'linear'
)

RETURNS @ds TABLE (type char(8), x float, y float)

AS

/*  Accepts @xy_data TABLE(x, y), @type for fit:
 *
 *  @type		Curve fit			Equation
 *  linear		Linear				y = a + b*x
 *  exp			Exponential			y = a*e^(b*x)						(for a > 0)
 *  log			Logarithmic			y = a + b*log(x)
 *  power		Power				y = a*x^b							(for a > 0)
 *  poly2		Polynomial^2		y = a + b*x + c*x^2
 *  poly3		Polynomial^3		y = a + b*x + c*x^2 + d*x^3
 *  polyn		Polynomial^n		y = a + b*x + c*x^2 + ... + z*x^n	(n > 3 requires additional return columns, not implemented)
 */

BEGIN
	DECLARE @a float, @b float, @c float, @d float

	SELECT @a = (SELECT a FROM @xy_coefficients)
	SELECT @b = (SELECT b FROM @xy_coefficients)
	SELECT @c = (SELECT c FROM @xy_coefficients)
	SELECT @d = (SELECT d FROM @xy_coefficients)

	INSERT INTO @ds
	SELECT	@type,
			x,
			CASE	WHEN @type = 'linear'	THEN @a + @b * x
					WHEN @type = 'exp'		THEN @a * EXP(@b * x)
					WHEN @type = 'log'		THEN @a + @b * LOG(x)
					WHEN @type = 'power'	THEN @a * POWER(x, @b)
					WHEN @type = 'poly2'	THEN @a + @b * x + @c * POWER(x, 2)
					WHEN @type = 'poly3'	THEN @a + @b * x + @c * POWER(x, 2) + @d * POWER(x, 3)	-- Poly n would need to use the logic from @curve_fit_polynomial_coefficients if ever implemented using TABLE(coefficient, power)
					ELSE					null
			END

	FROM	@xy_data

	ORDER BY x

	RETURN
END
