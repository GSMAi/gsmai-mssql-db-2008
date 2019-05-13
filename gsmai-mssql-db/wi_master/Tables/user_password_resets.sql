CREATE TABLE [dbo].[user_password_resets] (
    [id]         INT          IDENTITY (1, 1) NOT NULL,
    [user_id]    INT          NOT NULL,
    [hash]       VARCHAR (64) NOT NULL,
    [status]     BIT          CONSTRAINT [DF_user_password_resets_is_claimed] DEFAULT ((0)) NOT NULL,
    [created_on] DATETIME     CONSTRAINT [DF_user_password_resets_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by] INT          CONSTRAINT [DF_user_password_resets_created_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_user_password_resets] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_user_password_resets]
    ON [dbo].[user_password_resets]([hash] ASC);

