CREATE TABLE [dbo].[user_registrations] (
    [id]         INT          IDENTITY (1, 1) NOT NULL,
    [user_id]    INT          NOT NULL,
    [hash]       VARCHAR (64) NOT NULL,
    [status]     BIT          CONSTRAINT [DF_user_registration_tokens_status] DEFAULT ((0)) NOT NULL,
    [created_on] DATETIME     CONSTRAINT [DF_user_registration_tokens_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by] INT          CONSTRAINT [DF_user_registration_tokens_created_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_user_registration_tokens] PRIMARY KEY CLUSTERED ([id] ASC)
);

