CREATE TABLE [dbo].[permissions] (
    [id]   INT            IDENTITY (1, 1) NOT NULL,
    [name] NVARCHAR (512) NOT NULL,
    CONSTRAINT [PK_permissions] PRIMARY KEY CLUSTERED ([id] ASC)
);

