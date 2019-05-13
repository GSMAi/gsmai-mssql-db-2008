CREATE TABLE [dbo].[organisation_location_link] (
    [id]              INT            IDENTITY (1, 1) NOT NULL,
    [organisation_id] INT            NOT NULL,
    [folder]          NVARCHAR (512) NOT NULL,
    [parent]          NVARCHAR (512) NULL,
    [cleaned]         BIT            CONSTRAINT [DF_organisation_location_link_cleaned] DEFAULT ((0)) NOT NULL,
    [created_on]      DATETIME       CONSTRAINT [DF_organisation_location_link_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]      INT            CONSTRAINT [DF_organisation_location_link_created_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_organisation_location_link] PRIMARY KEY CLUSTERED ([id] ASC)
);

