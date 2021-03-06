﻿CREATE TYPE [dbo].[zone_data_type] AS TABLE (
    [fk_zone_id]       INT             NULL,
    [fk_metric_id]     INT             NULL,
    [fk_attribute_id]  INT             NULL,
    [fk_status_id]     INT             NULL,
    [fk_privacy_id]    INT             NULL,
    [date]             DATETIME        NULL,
    [date_type]        CHAR (1)        NULL,
    [val]              DECIMAL (22, 4) NULL,
    [fk_currency_id]   INT             NULL,
    [fk_source_id]     INT             NULL,
    [fk_confidence_id] INT             NULL,
    [has_flags]        BIT             NULL,
    [is_calculated]    BIT             NULL,
    [archive]          BIT             NULL,
    [is_spot_price]    BIT             NULL);

