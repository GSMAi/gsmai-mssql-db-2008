CREATE TABLE [dbo].[sessions] (
    [id]             INT              IDENTITY (1, 1) NOT NULL,
    [user_id]        INT              NOT NULL,
    [series]         UNIQUEIDENTIFIER NOT NULL,
    [identifier]     VARCHAR (64)     NULL,
    [hash]           VARCHAR (64)     NOT NULL,
    [active]         BIT              CONSTRAINT [DF_sessions_active] DEFAULT ((1)) NOT NULL,
    [user_agent]     NVARCHAR (MAX)   NULL,
    [created_by]     INT              CONSTRAINT [DF_sessions_created_by] DEFAULT ((0)) NOT NULL,
    [created_on]     DATETIME         CONSTRAINT [DF_sessions_created_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT              CONSTRAINT [DF_sessions_last_update_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME         CONSTRAINT [DF_sessions_last_update_on] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_sessions] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK_sessions_users] FOREIGN KEY ([user_id]) REFERENCES [dbo].[users] ([id])
);


GO
CREATE NONCLUSTERED INDEX [IX_sessions]
    ON [dbo].[sessions]([user_id] ASC, [series] ASC);

