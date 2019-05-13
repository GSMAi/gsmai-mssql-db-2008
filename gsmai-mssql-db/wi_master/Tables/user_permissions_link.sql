CREATE TABLE [dbo].[user_permissions_link] (
    [user_id]       INT      NOT NULL,
    [permission_id] INT      NOT NULL,
    [created_on]    DATETIME CONSTRAINT [DF_user_permissions_link_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]    INT      CONSTRAINT [DF_user_permissions_link_created_by] DEFAULT ((0)) NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_user_permissions_link]
    ON [dbo].[user_permissions_link]([user_id] ASC, [permission_id] ASC);

