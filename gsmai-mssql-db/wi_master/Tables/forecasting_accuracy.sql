CREATE TABLE [dbo].[forecasting_accuracy] (
    [id]                 BIGINT      IDENTITY (1, 1) NOT NULL,
    [fk_organisation_id] INT         NOT NULL,
    [date_type]          VARCHAR (1) NOT NULL,
    [date]               DATE        NOT NULL,
    [fk_group_id]        INT         NOT NULL,
    [reported_value]     BIGINT      NOT NULL,
    [prev_3_months]      BIGINT      NULL,
    [prev_6_months]      BIGINT      NULL,
    [prev_12_months]     BIGINT      NULL,
    [is_outlier]         VARCHAR (8) NOT NULL
);

