﻿CREATE TYPE [dbo].[group_data_type] AS TABLE (
    [fk_organisation_id] INT             NULL,
    [fk_metric_id]       INT             NULL,
    [fk_attribute_id]    INT             NULL,
    [fk_status_id]       INT             NULL,
    [fk_privacy_id]      INT             NULL,
    [date]               DATETIME        NULL,
    [date_type]          CHAR (1)        NULL,
    [val_sum]            DECIMAL (22, 4) NULL,
    [fk_currency_id]     INT             NULL,
    [fk_source_id]       INT             NULL,
    [fk_confidence_id]   INT             NULL,
    [has_flags]          BIT             NULL,
    [is_calculated]      BIT             NULL,
    [created_on]         DATETIME        NULL,
    [created_by]         INT             NULL,
    [archive]            BIT             NULL,
    [is_forecast_upload] BIT             NULL,
    [file_source]        VARCHAR (128)   NULL,
    [val_proportionate]  DECIMAL (22, 4) NULL,
    [ownership]          DECIMAL (22, 4) NULL);

