CREATE TABLE [dbo].[organisations] (
    [id]                          INT             IDENTITY (1, 1) NOT NULL,
    [name]                        NVARCHAR (512)  NOT NULL,
    [status_id]                   INT             NULL,
    [type_id]                     INT             NOT NULL,
    [source_organisation_link_id] INT             CONSTRAINT [DF_source_organisation_link_id] DEFAULT ((1)) NOT NULL,
    [url]                         NVARCHAR (1024) NULL,
    [tadig_codes]                 NVARCHAR (MAX)  NULL,
    [stock_symbol]                NVARCHAR (20)   NULL,
    [note]                        NVARCHAR (512)  NULL,
    [in_use]                      BIT             CONSTRAINT [DF_organisations_in_use] DEFAULT ((0)) NOT NULL,
    [published]                   BIT             CONSTRAINT [DF_organisations_published] DEFAULT ((0)) NULL,
    [created_on]                  DATETIME        CONSTRAINT [DF_organisation_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]                  INT             CONSTRAINT [DF_organisation_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]              DATETIME        CONSTRAINT [DF_organisation_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]              INT             CONSTRAINT [DF_organisation_last_update_by] DEFAULT ((0)) NOT NULL,
    [includes_m2m]                BIT             DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_organisations] PRIMARY KEY CLUSTERED ([id] ASC)
);

