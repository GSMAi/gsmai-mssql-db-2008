CREATE TABLE [dbo].[sp_run_error_log] (
    [errorNumber]    INT            NULL,
    [errorSeverity]  INT            NULL,
    [errorState]     INT            NULL,
    [errorProcedure] VARCHAR (250)  NULL,
    [errorLine]      INT            NULL,
    [errorMessage]   VARCHAR (2048) NULL,
    [date]           DATETIME       CONSTRAINT [DF__sp_run_err__date__189B078F] DEFAULT (getdate()) NULL,
    [queryString]    VARCHAR (2048) NULL
);

