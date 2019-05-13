﻿CREATE TABLE [dbo].[users] (
    [id]                   INT            IDENTITY (1, 1) NOT NULL,
    [role_id]              INT            CONSTRAINT [DF_users_role_id] DEFAULT ((3)) NOT NULL,
    [login]                NVARCHAR (128) NOT NULL,
    [name]                 NVARCHAR (512) NOT NULL,
    [email]                NVARCHAR (512) NULL,
    [job_title]            NVARCHAR (512) NULL,
    [hash]                 VARCHAR (64)   NULL,
    [salt]                 VARCHAR (10)   NOT NULL,
    [archived]             BIT            CONSTRAINT [DF_users_archived] DEFAULT ((0)) NOT NULL,
    [suspended]            BIT            CONSTRAINT [DF_users_suspended] DEFAULT ((0)) NOT NULL,
    [sso]                  BIT            CONSTRAINT [DF_users_sso] DEFAULT ((0)) NOT NULL,
    [is_verified]          BIT            CONSTRAINT [DF_users_is_verified] DEFAULT ((0)) NOT NULL,
    [verified_on]          DATETIME       NULL,
    [has_set_own_password] BIT            CONSTRAINT [DF_users_has_set_own_password] DEFAULT ((0)) NOT NULL,
    [expiry]               DATETIME       NULL,
    [last_session]         DATETIME       NULL,
    [note]                 NVARCHAR (MAX) NULL,
    [created_by]           INT            CONSTRAINT [DF_users_created_by] DEFAULT ((0)) NOT NULL,
    [created_on]           DATETIME       CONSTRAINT [DF_users_created_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]       NVARCHAR (128) CONSTRAINT [DF_users_last_update_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]       DATETIME       CONSTRAINT [DF_users_last_update_on] DEFAULT (getdate()) NOT NULL,
    [revalidated_on]       DATETIME       DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_users] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK_users_roles] FOREIGN KEY ([role_id]) REFERENCES [dbo].[roles] ([id])
);
