CREATE TABLE [dbo].[user_email_verification] (
    [id]         INT            IDENTITY (1, 1) NOT NULL,
    [user_id]    INT            NOT NULL,
    [hash]       VARCHAR (64)   NOT NULL,
    [return_url] NVARCHAR (MAX) NULL,
    [status]     BIT            CONSTRAINT [DF_user_email_verification_status] DEFAULT ((0)) NOT NULL,
    [created_on] DATETIME       CONSTRAINT [DF_user_email_verification_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by] INT            CONSTRAINT [DF_user_email_verification_created_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_user_email_verification] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_user_email_verification]
    ON [dbo].[user_email_verification]([user_id] ASC);

