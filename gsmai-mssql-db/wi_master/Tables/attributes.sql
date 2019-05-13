CREATE TABLE [dbo].[attributes] (
    [id]             INT            IDENTITY (1, 1) NOT NULL,
    [name]           NVARCHAR (512) NOT NULL,
    [term]           NVARCHAR (MAX) NULL,
    [type_id]        INT            NULL,
    [order]          INT            NULL,
    [published]      BIT            CONSTRAINT [DF_attributes_published] DEFAULT ((0)) NOT NULL,
    [deleted]        BIT            CONSTRAINT [DF_attributes_deleted] DEFAULT ((0)) NOT NULL,
    [created_on]     DATETIME       CONSTRAINT [DF_attributes_created_on] DEFAULT (getdate()) NOT NULL,
    [created_by]     INT            CONSTRAINT [DF_attributes_created_by] DEFAULT ((0)) NOT NULL,
    [last_update_on] DATETIME       CONSTRAINT [DF_attributes_last_update_on] DEFAULT (getdate()) NOT NULL,
    [last_update_by] INT            CONSTRAINT [DF_attributes_last_update_by] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_attributes] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [PT_attributes_comb]
    ON [dbo].[attributes]([type_id] ASC, [order] ASC, [published] ASC, [deleted] ASC);

