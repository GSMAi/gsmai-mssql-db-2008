CREATE TABLE [dbo].[ds_group_ownership] (
    [id]               BIGINT         IDENTITY (1, 1) NOT NULL,
    [group_id]         INT            NOT NULL,
    [organisation_id]  INT            NOT NULL,
    [metric_id]        INT            NOT NULL,
    [attribute_id]     INT            NOT NULL,
    [date]             DATETIME       NOT NULL,
    [date_type]        CHAR (1)       NOT NULL,
    [value]            DECIMAL (6, 4) NOT NULL,
    [is_compound]      BIT            CONSTRAINT [DF_group_ownership_compound] DEFAULT ((0)) NOT NULL,
    [is_consolidated]  BIT            CONSTRAINT [DF_group_ownership_is_consolidated] DEFAULT ((0)) NOT NULL,
    [is_group]         BIT            CONSTRAINT [DF_ds_group_ownership_is_group] DEFAULT ((0)) NOT NULL,
    [is_joint_venture] BIT            CONSTRAINT [DF_group_ownership_is_joint_venture] DEFAULT ((0)) NOT NULL,
    [source_id]        INT            NOT NULL,
    [confidence_id]    INT            NOT NULL,
    [definition_id]    INT            NULL,
    [note]             NVARCHAR (MAX) NULL,
    [created_on]       DATETIME       CONSTRAINT [DF_group_ownership_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]       INT            CONSTRAINT [DF_group_ownership_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on]   DATETIME       CONSTRAINT [DF_group_ownership_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by]   INT            CONSTRAINT [DF_group_ownership_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_group_ownership] PRIMARY KEY CLUSTERED ([id] ASC)
);

