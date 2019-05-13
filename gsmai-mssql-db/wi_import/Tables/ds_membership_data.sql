CREATE TABLE [gsma].[ds_membership_data] (
    [id]                 INT             IDENTITY (1, 1) NOT NULL,
    [organisation_id]    INT             NOT NULL,
    [date]               DATETIME        NOT NULL,
    [date_type]          CHAR (1)        NOT NULL,
    [connections]        DECIMAL (22, 4) NULL,
    [connections_source] INT             NULL,
    [revenue]            DECIMAL (22, 4) NULL,
    [revenue_currency]   INT             NULL,
    [revenue_source]     INT             NULL,
    [revenue_attribute]  INT             NULL,
    [revenue_normalised] DECIMAL (22, 4) NULL,
    [note]               NTEXT           NULL,
    [created_on]         DATETIME        CONSTRAINT [DF_ds_membership_fees_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]         INT             CONSTRAINT [DF_ds_membership_data_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]     DATETIME        CONSTRAINT [DF_ds_membership_fees_last_updated_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]     INT             CONSTRAINT [DF_ds_membership_data_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ds_membership_data] PRIMARY KEY CLUSTERED ([id] ASC)
);

