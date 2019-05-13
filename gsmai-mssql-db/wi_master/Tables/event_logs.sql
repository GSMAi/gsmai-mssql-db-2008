CREATE TABLE [dbo].[event_logs] (
    [id]         INT            IDENTITY (1, 1) NOT NULL,
    [event_date] DATETIME       DEFAULT (getdate()) NOT NULL,
    [event_data] VARCHAR (4096) NULL,
    [user_data]  VARCHAR (1024) NULL,
    [event_type] VARCHAR (1024) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

