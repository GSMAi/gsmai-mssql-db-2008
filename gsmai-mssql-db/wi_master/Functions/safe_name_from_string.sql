
CREATE FUNCTION [dbo].[safe_name_from_string] (@string varchar(max))
RETURNS varchar(max)

AS

BEGIN
	DECLARE @safe_characters varchar(max) = '%[^-a-z0-9]%'
	
	SET @string = REPLACE(REPLACE(REPLACE(REPLACE(RTRIM(LTRIM(@string)), '> ', ''), ' ', '-'), '/', '-'), '\', '-')
	
	WHILE PATINDEX(@safe_characters, @string) > 0
	BEGIN
		SET @string = STUFF(@string, PATINDEX(@safe_characters, @string), 1, '')
	END

	RETURN REPLACE(LOWER(@string), ' ', '-')
End
