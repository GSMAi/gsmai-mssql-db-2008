CREATE TABLE [dbo].[organisations_copy] (
    [id]             INT             IDENTITY (1, 1) NOT NULL,
    [name]           NVARCHAR (512)  NOT NULL,
    [status_id]      INT             NULL,
    [type_id]        INT             NOT NULL,
    [url]            NVARCHAR (1024) NULL,
    [pmn_code]       NVARCHAR (10)   NULL,
    [stock_symbol]   NVARCHAR (20)   NULL,
    [note]           NVARCHAR (512)  NULL,
    [in_use]         BIT             DEFAULT ((0)) NOT NULL,
    [published]      BIT             DEFAULT ((0)) NULL,
    [created_on]     DATETIME        DEFAULT (getdate()) NOT NULL,
    [created_by]     INT             DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME        DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT             DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

