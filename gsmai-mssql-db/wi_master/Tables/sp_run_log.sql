CREATE TABLE [dbo].[sp_run_log] (
    [name] VARCHAR (1) NULL,
    [date] DATETIME    DEFAULT (getdate()) NOT NULL
);

