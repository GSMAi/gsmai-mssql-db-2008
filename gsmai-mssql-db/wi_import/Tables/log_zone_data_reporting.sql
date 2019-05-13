CREATE TABLE [dbo].[log_zone_data_reporting] (
    [id]             INT      IDENTITY (1, 1) NOT NULL,
    [zone_id]        INT      NOT NULL,
    [metric_id]      INT      NOT NULL,
    [attribute_id]   INT      NOT NULL,
    [date]           DATETIME NOT NULL,
    [date_type]      CHAR (1) NOT NULL,
    [processed]      BIT      CONSTRAINT [DF_log_zone_data_reporting_processed] DEFAULT ((0)) NOT NULL,
    [created_on]     DATETIME CONSTRAINT [DF_log_zone_data_reporting_created_on] DEFAULT (getdate()) NOT NULL,
    [last_update_on] DATETIME NULL,
    CONSTRAINT [PK_log_zone_data_reporting] PRIMARY KEY CLUSTERED ([id] ASC)
);

