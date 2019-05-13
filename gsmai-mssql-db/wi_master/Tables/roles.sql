CREATE TABLE [dbo].[roles] (
    [id]   INT            IDENTITY (1, 1) NOT NULL,
    [name] NVARCHAR (512) NOT NULL,
    CONSTRAINT [PK_roles] PRIMARY KEY CLUSTERED ([id] ASC)
);

