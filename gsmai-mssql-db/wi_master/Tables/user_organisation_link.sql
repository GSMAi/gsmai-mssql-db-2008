CREATE TABLE [dbo].[user_organisation_link] (
    [user_id]         INT NOT NULL,
    [organisation_id] INT NOT NULL,
    CONSTRAINT [PK_user_organisation_link] PRIMARY KEY CLUSTERED ([user_id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_user_organisation_link]
    ON [dbo].[user_organisation_link]([organisation_id] ASC);

