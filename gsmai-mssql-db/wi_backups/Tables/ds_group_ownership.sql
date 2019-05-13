CREATE TABLE [dbo].[ds_group_ownership] (
    [id]               BIGINT         NOT NULL,
    [group_id]         INT            NOT NULL,
    [organisation_id]  INT            NOT NULL,
    [metric_id]        INT            NOT NULL,
    [attribute_id]     INT            NOT NULL,
    [date]             DATETIME       NOT NULL,
    [date_type]        CHAR (1)       NOT NULL,
    [value]            DECIMAL (6, 4) NOT NULL,
    [is_compound]      BIT            NOT NULL,
    [is_consolidated]  BIT            NOT NULL,
    [is_group]         BIT            NOT NULL,
    [is_joint_venture] BIT            NOT NULL,
    [source_id]        INT            NOT NULL,
    [confidence_id]    INT            NOT NULL,
    [definition_id]    INT            NULL,
    [note]             NVARCHAR (MAX) NULL,
    [created_on]       DATETIME       NOT NULL,
    [created_by]       INT            NOT NULL,
    [last_update_on]   DATETIME       NOT NULL,
    [last_update_by]   INT            NOT NULL,
    [inserted_on]      DATETIME       NOT NULL
);

