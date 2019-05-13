CREATE TABLE [gsma].[ic_organisation_link] (
    [id]                      INT            NOT NULL,
    [finance_code]            NVARCHAR (64)  NULL,
    [name]                    NVARCHAR (512) NULL,
    [type]                    NVARCHAR (512) NULL,
    [organisation_id]         INT            NOT NULL,
    [ref_organisation_id]     INT            NULL,
    [mapped_organisation_id]  INT            NOT NULL,
    [ref_rel_organisation_id] INT            NULL,
    [is_member]               BIT            CONSTRAINT [DF_ic_organisation_link_is_member] DEFAULT ((0)) NOT NULL,
    [is_special_case]         BIT            CONSTRAINT [DF_ic_organisation_link_is_special_case] DEFAULT ((0)) NOT NULL,
    [is_orphaned]             BIT            CONSTRAINT [DF__ic_organi__is_or__380D5C5F] DEFAULT ((0)) NOT NULL,
    [created_by]              INT            CONSTRAINT [DF__ic_organi__creat__39018098] DEFAULT ((0)) NOT NULL,
    [created_on]              DATETIME       CONSTRAINT [DF__ic_organi__creat__39F5A4D1] DEFAULT (getdate()) NOT NULL,
    [last_update_by]          INT            NULL,
    [last_update_on]          DATETIME       NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_ic_organisation_link]
    ON [gsma].[ic_organisation_link]([id] ASC, [organisation_id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_ic_organisation_link_organisation_id]
    ON [gsma].[ic_organisation_link]([organisation_id] ASC, [id] ASC);

