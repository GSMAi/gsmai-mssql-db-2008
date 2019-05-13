CREATE TABLE [dbo].[jobs] (
    [id]                   INT            IDENTITY (1, 1) NOT NULL,
    [name]                 NVARCHAR (512) NOT NULL,
    [file]                 NVARCHAR (512) NULL,
    [schedule]             NVARCHAR (64)  NULL,
    [type]                 NVARCHAR (4)   NOT NULL,
    [order]                INT            NULL,
    [is_enabled]           BIT            CONSTRAINT [DF_jobs_is_enabled] DEFAULT ((1)) NOT NULL,
    [is_running]           BIT            CONSTRAINT [DF_jobs_is_running] DEFAULT ((0)) NOT NULL,
    [last_exit_was_error]  BIT            CONSTRAINT [DF_jobs_last_exit_with_error] DEFAULT ((0)) NOT NULL,
    [created_on]           DATETIME       CONSTRAINT [DF_jobs_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]           INT            CONSTRAINT [DF_jobs_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]       DATETIME       CONSTRAINT [DF_jobs_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]       INT            CONSTRAINT [DF_jobs_last_update_by] DEFAULT ((0)) NOT NULL,
    [last_run_started_on]  DATETIME       NULL,
    [last_run_finished_on] DATETIME       NULL,
    [last_run_by]          INT            NULL,
    CONSTRAINT [PK_jobs] PRIMARY KEY CLUSTERED ([id] ASC)
);

