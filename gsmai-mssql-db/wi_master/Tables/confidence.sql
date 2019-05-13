CREATE TABLE [dbo].[confidence] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [name]           NVARCHAR (512) NOT NULL,
    [term]           NVARCHAR (MAX) NULL,
    [excel_term]     NVARCHAR (MAX) NULL,
    [published]      BIT            CONSTRAINT [DF_confidence_published] DEFAULT ((0)) NOT NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_confidence_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_confidence_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME       CONSTRAINT [DF_confidence_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT            CONSTRAINT [DF_confidence_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_confidence] PRIMARY KEY CLUSTERED ([id] ASC)
);

