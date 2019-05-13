CREATE TABLE [dbo].[organisation_events] (
    [id]                    INT      IDENTITY (1, 1) NOT NULL,
    [organisation_id]       INT      NOT NULL,
    [ref_organisation_id]   INT      NULL,
    [ref_organisation_id_2] INT      NULL,
    [status_id]             INT      NOT NULL,
    [date]                  DATETIME NULL,
    [date_type]             CHAR (1) NULL,
    [created_on]            DATETIME CONSTRAINT [DF_organisation_events_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]            INT      CONSTRAINT [DF_organisation_events_created_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_organisation_events] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK_organisation_events_organisations] FOREIGN KEY ([organisation_id]) REFERENCES [dbo].[organisations] ([id]),
    CONSTRAINT [FK_organisation_events_organisations_2] FOREIGN KEY ([ref_organisation_id]) REFERENCES [dbo].[organisations] ([id]),
    CONSTRAINT [FK_organisation_events_status] FOREIGN KEY ([status_id]) REFERENCES [dbo].[status] ([id])
);

