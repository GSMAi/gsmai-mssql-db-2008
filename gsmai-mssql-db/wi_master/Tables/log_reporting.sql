CREATE TABLE [dbo].[log_reporting] (
    [id]                         INT        IDENTITY (1, 1) NOT NULL,
    [metric_id]                  INT        NOT NULL,
    [attribute_id]               INT        NOT NULL,
    [date]                       DATETIME   NOT NULL,
    [date_type]                  CHAR (1)   NOT NULL,
    [organisations_count]        INT        NULL,
    [organisations_market_share] FLOAT (53) NULL,
    [created_on]                 DATETIME   CONSTRAINT [DF_log_reporting_created_on_1] DEFAULT (getdate()) NOT NULL,
    [created_by]                 INT        CONSTRAINT [DF_log_reporting_created_by_1] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_log_reporting_1] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_log_reporting]
    ON [dbo].[log_reporting]([metric_id] ASC, [attribute_id] ASC);

