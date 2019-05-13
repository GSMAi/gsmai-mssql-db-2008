CREATE TABLE [dbo].[log_forecasting] (
    [id]                   INT            IDENTITY (1, 1) NOT NULL,
    [organisation_id]      INT            NOT NULL,
    [date]                 DATETIME       NULL,
    [connections_start]    BIGINT         NULL,
    [connections_end]      BIGINT         NULL,
    [connections_previous] BIGINT         NULL,
    [delta]                FLOAT (53)     NULL,
    [priority]             BIT            NULL,
    [status]               BIT            CONSTRAINT [DF_log_reporting_status] DEFAULT ((0)) NOT NULL,
    [note]                 NVARCHAR (MAX) NULL,
    [reviewed]             BIT            CONSTRAINT [DF_log_reporting_collected] DEFAULT ((0)) NOT NULL,
    [review]               NVARCHAR (MAX) NULL,
    [log_id]               INT            NULL,
    [log]                  NVARCHAR (MAX) NULL,
    [category_id]          INT            NULL,
    [created_on]           DATETIME       CONSTRAINT [DF_log_reporting_created_on] DEFAULT (getdate()) NULL,
    [created_by]           INT            CONSTRAINT [DF_log_reporting_created_by] DEFAULT ((0)) NULL,
    [last_update_on]       DATETIME       CONSTRAINT [DF_log_reporting_last_update_on] DEFAULT (getdate()) NULL,
    [last_update_by]       INT            CONSTRAINT [DF_log_reporting_last_update_by] DEFAULT ((0)) NULL,
    [claimed_by]           INT            NULL,
    CONSTRAINT [PK_log_reporting] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_log_reporting_created_on]
    ON [dbo].[log_forecasting]([created_on] DESC);


GO
CREATE NONCLUSTERED INDEX [IX_log_reporting_organisation_id]
    ON [dbo].[log_forecasting]([organisation_id] ASC, [date] DESC);

