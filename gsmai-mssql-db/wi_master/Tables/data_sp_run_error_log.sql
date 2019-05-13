CREATE TABLE [dbo].[data_sp_run_error_log] (
    [errorNumber]    INT            NULL,
    [errorSeverity]  INT            NULL,
    [errorState]     INT            NULL,
    [errorProcedure] VARCHAR (250)  NULL,
    [errorLine]      INT            NULL,
    [errorMessage]   VARCHAR (2048) NULL,
    [date]           DATETIME       DEFAULT (getdate()) NULL,
    [queryString]    VARCHAR (2048) NULL
);

