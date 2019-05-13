CREATE TABLE [dbo].[user_logs] (
    [user_id] INT            NOT NULL,
    [action]  VARCHAR (30)   NOT NULL,
    [date]    DATETIME       DEFAULT (getdate()) NOT NULL,
    [note]    VARCHAR (1048) NULL
);

