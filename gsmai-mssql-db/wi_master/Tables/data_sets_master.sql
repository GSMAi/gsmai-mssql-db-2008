CREATE TABLE [dbo].[data_sets_master] (
    [id]                          INT            IDENTITY (1, 1) NOT NULL,
    [fk_metric_id]                INT            NOT NULL,
    [fk_attribute_id]             INT            NOT NULL,
    [has_organisation_data]       BIT            NOT NULL,
    [has_zone_data]               BIT            NOT NULL,
    [show_on_website]             BIT            NOT NULL,
    [archive]                     BIT            NOT NULL,
    [name]                        VARCHAR (256)  NULL,
    [data_set_description]        VARCHAR (1024) NULL,
    [metric_name]                 VARCHAR (256)  NULL,
    [attribute_name]              VARCHAR (256)  NULL,
    [calculation_description]     VARCHAR (1024) NULL,
    [aggregation_description]     VARCHAR (1024) NULL,
    [data_set_description_source] VARCHAR (256)  DEFAULT ('GSMA Intelligence') NOT NULL,
    [ordering]                    INT            DEFAULT ((1000)) NULL,
    [shortname]                   VARCHAR (256)  NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [fk_atrb_id] FOREIGN KEY ([fk_attribute_id]) REFERENCES [dbo].[attributes] ([id]),
    CONSTRAINT [fk_mtr_id] FOREIGN KEY ([fk_metric_id]) REFERENCES [dbo].[metrics] ([id])
);


GO
CREATE NONCLUSTERED INDEX [PT_data_sets_master_comb]
    ON [dbo].[data_sets_master]([fk_metric_id] ASC, [fk_attribute_id] ASC, [has_organisation_data] ASC, [has_zone_data] ASC, [show_on_website] ASC, [archive] ASC);

