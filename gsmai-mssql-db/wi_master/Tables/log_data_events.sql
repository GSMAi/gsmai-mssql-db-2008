CREATE TABLE [dbo].[log_data_events] (
    [id]              INT             IDENTITY (1, 1) NOT NULL,
    [event]           NVARCHAR (MAX)  NOT NULL,
    [organisation_id] INT             NOT NULL,
    [metric_id]       INT             NOT NULL,
    [attribute_id]    INT             NOT NULL,
    [date]            DATETIME        NOT NULL,
    [date_type]       CHAR (1)        NOT NULL,
    [status_id]       INT             CONSTRAINT [DF_log_data_events_status_id] DEFAULT ((5)) NOT NULL,
    [severity]        INT             CONSTRAINT [DF_log_data_events_severity] DEFAULT ((0)) NOT NULL,
    [value_input]     DECIMAL (22, 8) NULL,
    [value_input_2]   DECIMAL (22, 8) NULL,
    [value_output]    DECIMAL (22, 8) NOT NULL,
    [created_on]      DATETIME        CONSTRAINT [DF_log_data_events_created_on] DEFAULT (getdate()) NOT NULL,
    [completed_on]    DATETIME        NULL,
    CONSTRAINT [PK_log_data_events] PRIMARY KEY CLUSTERED ([id] ASC)
);

