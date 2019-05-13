CREATE TABLE [dbo].[report_tracking] (
    [id]         BIGINT         IDENTITY (1, 1) NOT NULL,
    [report_id]  INT            NOT NULL,
    [user_id]    INT            NOT NULL,
    [type]       VARCHAR (16)   NOT NULL,
    [serialized] NVARCHAR (MAX) NULL,
    [created_on] DATETIME       CONSTRAINT [DF_report_tracking_created_on] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_report_tracking] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_report_tracking_created_on]
    ON [dbo].[report_tracking]([created_on] DESC);


GO
CREATE NONCLUSTERED INDEX [IX_report_tracking_report_id]
    ON [dbo].[report_tracking]([report_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_report_tracking_user_id]
    ON [dbo].[report_tracking]([user_id] ASC);

