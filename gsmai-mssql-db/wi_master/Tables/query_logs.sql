CREATE TABLE [dbo].[query_logs] (
    [id]         INT          IDENTITY (1, 1) NOT NULL,
    [domain]     VARCHAR (50) NULL,
    [query]      NCHAR (2096) NULL,
    [created_on] DATETIME     DEFAULT (getdate()) NOT NULL
);

