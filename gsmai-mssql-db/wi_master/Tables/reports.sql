CREATE TABLE [dbo].[reports] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [name]           NVARCHAR (512) NULL,
    [sp]             NVARCHAR (128) NOT NULL,
    [url]            NVARCHAR (128) NOT NULL,
    [hash]           VARCHAR (32)   NOT NULL,
    [uniqid]         VARCHAR (32)   NOT NULL,
    [serialized]     NVARCHAR (MAX) NULL,
    [metadata]       NVARCHAR (MAX) NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_reports_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_reports_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME       CONSTRAINT [DF_reports_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT            CONSTRAINT [DF_reports_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_reports] PRIMARY KEY CLUSTERED ([id] ASC)
);

