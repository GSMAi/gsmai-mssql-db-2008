CREATE TABLE [dbo].[zone_data] (
    [id]               BIGINT          IDENTITY (1, 1) NOT NULL,
    [fk_zone_id]       INT             NOT NULL,
    [fk_metric_id]     INT             NOT NULL,
    [fk_attribute_id]  INT             NOT NULL,
    [fk_status_id]     INT             NOT NULL,
    [fk_privacy_id]    INT             NOT NULL,
    [date]             DATETIME        NOT NULL,
    [date_type]        CHAR (1)        NOT NULL,
    [val]              DECIMAL (22, 4) NOT NULL,
    [fk_currency_id]   INT             NOT NULL,
    [fk_source_id]     INT             NOT NULL,
    [fk_confidence_id] INT             NOT NULL,
    [has_flags]        BIT             NOT NULL,
    [is_calculated]    BIT             NOT NULL,
    [archive]          BIT             DEFAULT ((0)) NOT NULL,
    [is_spot_price]    BIT             DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK__zone__fk_at__522955FD] FOREIGN KEY ([fk_attribute_id]) REFERENCES [dbo].[attributes] ([id]) ON UPDATE CASCADE,
    CONSTRAINT [FK__zone__fk_co__56EE0B1A] FOREIGN KEY ([fk_confidence_id]) REFERENCES [dbo].[confidence] ([id]) ON UPDATE CASCADE,
    CONSTRAINT [FK__zone__fk_cu__5505C2A8] FOREIGN KEY ([fk_currency_id]) REFERENCES [dbo].[currencies] ([id]) ON UPDATE CASCADE,
    CONSTRAINT [FK__zone__fk_me__513531C4] FOREIGN KEY ([fk_metric_id]) REFERENCES [dbo].[metrics] ([id]) ON UPDATE CASCADE,
    CONSTRAINT [FK__zone__fk_or__50410D8B] FOREIGN KEY ([fk_zone_id]) REFERENCES [dbo].[zones] ([id]) ON UPDATE CASCADE,
    CONSTRAINT [FK__zone__fk_pr__54119E6F] FOREIGN KEY ([fk_privacy_id]) REFERENCES [dbo].[privacy] ([id]) ON UPDATE CASCADE,
    CONSTRAINT [FK__zone__fk_so__55F9E6E1] FOREIGN KEY ([fk_source_id]) REFERENCES [dbo].[sources] ([id]) ON UPDATE CASCADE,
    CONSTRAINT [FK__zone__fk_st__531D7A36] FOREIGN KEY ([fk_status_id]) REFERENCES [dbo].[status] ([id]) ON UPDATE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [idx_zonedata_row_check]
    ON [dbo].[zone_data]([fk_zone_id] ASC, [fk_metric_id] ASC, [fk_attribute_id] ASC, [fk_status_id] ASC, [date] ASC, [date_type] ASC, [val] ASC, [fk_currency_id] ASC, [fk_confidence_id] ASC, [is_spot_price] ASC, [fk_source_id] ASC, [is_calculated] ASC, [archive] ASC, [has_flags] ASC);


GO
CREATE NONCLUSTERED INDEX [PT_zone_data_comb]
    ON [dbo].[zone_data]([fk_zone_id] ASC, [fk_metric_id] ASC, [fk_attribute_id] ASC, [fk_status_id] ASC, [fk_privacy_id] ASC, [date] ASC, [date_type] ASC, [fk_currency_id] ASC, [fk_source_id] ASC, [fk_confidence_id] ASC, [has_flags] ASC, [is_calculated] ASC, [archive] ASC, [is_spot_price] ASC);

