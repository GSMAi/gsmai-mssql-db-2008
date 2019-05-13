CREATE TABLE [dbo].[organisation_data_tmp] (
    [id]                 BIGINT          NOT NULL,
    [fk_organisation_id] INT             NOT NULL,
    [fk_metric_id]       INT             NOT NULL,
    [fk_attribute_id]    INT             NOT NULL,
    [fk_status_id]       INT             NOT NULL,
    [fk_privacy_id]      INT             NOT NULL,
    [date]               DATETIME        NOT NULL,
    [date_type]          CHAR (1)        NOT NULL,
    [val]                DECIMAL (22, 4) NOT NULL,
    [fk_currency_id]     INT             NOT NULL,
    [fk_source_id]       INT             NOT NULL,
    [fk_confidence_id]   INT             NOT NULL,
    [has_flags]          BIT             NOT NULL,
    [is_calculated]      BIT             NOT NULL,
    [created_on]         DATETIME        NOT NULL,
    [created_by]         INT             NOT NULL,
    [archive]            BIT             DEFAULT ((0)) NOT NULL,
    [is_forecast_upload] BIT             NOT NULL,
    [file_source]        VARCHAR (128)   NOT NULL
);

