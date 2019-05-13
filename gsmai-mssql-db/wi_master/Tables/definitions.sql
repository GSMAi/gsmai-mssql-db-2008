CREATE TABLE [dbo].[definitions] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [metric_id]      INT            NOT NULL,
    [attribute_id]   INT            NULL,
    [type_id]        INT            NULL,
    [definition]     NVARCHAR (MAX) NOT NULL,
    [calculation]    NVARCHAR (MAX) NULL,
    [aggregation]    NVARCHAR (MAX) NULL,
    [source]         NVARCHAR (MAX) NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_definitions_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_definitions_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME       CONSTRAINT [DF_definitions_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT            CONSTRAINT [DF_definitions_last_update_by] DEFAULT ((0)) NOT NULL
);

