CREATE TABLE [dbo].[sp_run_tracker] (
    [job_name] VARCHAR (40)  NOT NULL,
    [date]     DATETIME      DEFAULT (getdate()) NOT NULL,
    [data]     VARCHAR (200) NULL
);

