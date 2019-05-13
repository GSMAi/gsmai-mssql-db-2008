
CREATE PROCEDURE [dbo].[system_job_status]

(
	@job_id uniqueidentifier
)

AS

DECLARE @is_sysadmin int, @job_owner sysname

CREATE TABLE #jobs
(
	id uniqueidentifier NOT NULL,
	last_run_date int NOT NULL,
	last_run_time int NOT NULL,
	next_run_date int NOT NULL,
	next_run_time int NOT NULL,
	next_run_schedule_id int NOT NULL,
	requested_to_run int NOT NULL, -- BOOL
	request_source int NOT NULL,
	request_source_id sysname NULL,
	running int NOT NULL, -- BOOL
	current_step int NOT NULL,
	current_retry_attempt int NOT NULL,
	status int NOT NULL
)

SELECT @is_sysadmin = ISNULL(IS_SRVROLEMEMBER(N'sysadmin'), 0)
SELECT @job_owner = SUSER_SNAME()

INSERT INTO #jobs
EXECUTE master.dbo.xp_sqlagent_enum_jobs @is_sysadmin, @job_owner

SELECT id, status, running FROM #jobs WHERE id = @job_id

DROP TABLE #jobs
