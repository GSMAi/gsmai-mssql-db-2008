CREATE TABLE [dbo].[registrations] (
    [id]              INT            IDENTITY (1, 1) NOT NULL,
    [name]            NVARCHAR (512) NOT NULL,
    [email]           NVARCHAR (512) NOT NULL,
    [job_title]       NVARCHAR (512) NULL,
    [telephone]       NVARCHAR (128) NULL,
    [ref]             NVARCHAR (512) NULL,
    [campaign]        NVARCHAR (512) NULL,
    [organisation_id] INT            NULL,
    [organisation]    NVARCHAR (512) NULL,
    [country_id]      INT            NOT NULL,
    [approved]        BIT            CONSTRAINT [DF_registrations_approved] DEFAULT ((0)) NOT NULL,
    [user_id]         INT            NULL,
    [created_on]      DATETIME       CONSTRAINT [DF_registrations_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]      INT            CONSTRAINT [DF_registrations_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]  DATETIME       CONSTRAINT [DF_registrations_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]  INT            CONSTRAINT [DF_registrations_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_registrations] PRIMARY KEY CLUSTERED ([id] ASC)
);

