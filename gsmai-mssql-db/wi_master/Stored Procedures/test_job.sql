CREATE PROCEDURE [dbo].[test_job]

(
	@debug bit = 1
)

AS

IF @debug = 0
BEGIN
	SELECT * FROM NonexistentTable;
END
