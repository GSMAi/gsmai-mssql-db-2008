CREATE TABLE [dbo].[invitations] (
    [user_id] INT NOT NULL,
    [status]  BIT CONSTRAINT [DF_invitations_status] DEFAULT ((1)) NOT NULL
);

