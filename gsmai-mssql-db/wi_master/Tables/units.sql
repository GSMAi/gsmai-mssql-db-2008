CREATE TABLE [dbo].[units] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [name]           NVARCHAR (512) NOT NULL,
    [term]           NVARCHAR (MAX) NOT NULL,
    [symbol]         NVARCHAR (16)  NOT NULL,
    [quantity]       NVARCHAR (512) NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_units_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_units_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME       CONSTRAINT [DF_units_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT            CONSTRAINT [DF_units_last_update_by] DEFAULT ((0)) NOT NULL,
    [multiplication] INT            DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_units] PRIMARY KEY CLUSTERED ([id] ASC)
);

