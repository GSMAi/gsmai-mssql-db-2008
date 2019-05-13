CREATE TABLE [dbo].[types] (
    [id]                          INT            IDENTITY (1, 1) NOT NULL,
    [name]                        NVARCHAR (512) NOT NULL,
    [display_name]                NVARCHAR (512) NULL,
    [term]                        NVARCHAR (MAX) NULL,
    [scheme]                      NVARCHAR (MAX) NULL,
    [created_on]                  DATETIME       CONSTRAINT [DF_types_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]                  INT            CONSTRAINT [DF_types_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]              DATETIME       CONSTRAINT [DF_types_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]              INT            CONSTRAINT [DF_types_last_update_by] DEFAULT ((0)) NOT NULL,
    [source_organisation_link_id] INT            CONSTRAINT [DF__types__source_or__3383DA5A] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_types] PRIMARY KEY CLUSTERED ([id] ASC)
);

