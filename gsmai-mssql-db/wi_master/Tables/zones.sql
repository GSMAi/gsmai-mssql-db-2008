CREATE TABLE [dbo].[zones] (
    [id]               INT            IDENTITY (1, 1) NOT NULL,
    [name]             NVARCHAR (512) NOT NULL,
    [status_id]        INT            NOT NULL,
    [type_id]          INT            NOT NULL,
    [fk_type_id]       INT            NOT NULL,
    [economic_type_id] INT            NULL,
    [iso_code]         NVARCHAR (3)   NULL,
    [iso_short_code]   NVARCHAR (2)   NULL,
    [lat]              DECIMAL (7, 4) NULL,
    [lon]              DECIMAL (7, 4) NULL,
    [note]             NVARCHAR (512) NULL,
    [published]        BIT            CONSTRAINT [DF_zones_published] DEFAULT ((0)) NULL,
    [created_on]       DATETIME       CONSTRAINT [DF_zone_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]       INT            CONSTRAINT [DF_zone_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]   DATETIME       CONSTRAINT [DF_zone_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]   INT            CONSTRAINT [DF_zone_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_zones] PRIMARY KEY CLUSTERED ([id] ASC)
);

