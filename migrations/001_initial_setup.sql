-- ============================================================
-- Migration: 001_initial_setup
-- Creates the example database and the three core tables with
-- PrimKey (UNIQUEIDENTIFIER), Created (DATETIME2), Updated
-- (DATETIME2 auto-maintained by trigger), and FK relationships.
-- ============================================================

-- Create database if it does not already exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'ExampleDB')
BEGIN
    CREATE DATABASE ExampleDB;
END
GO

USE ExampleDB;
GO

-- ============================================================
-- Table: atbl_Example_Users
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'atbl_Example_Users' AND xtype = 'U')
BEGIN
    CREATE TABLE atbl_Example_Users (
        PrimKey   UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_atbl_Example_Users_PrimKey   DEFAULT NEWID(),
        Username  NVARCHAR(100)    NOT NULL,
        Email     NVARCHAR(255)    NOT NULL,
        Created   DATETIME2        NOT NULL CONSTRAINT DF_atbl_Example_Users_Created   DEFAULT SYSDATETIME(),
        Updated   DATETIME2        NULL,
        CONSTRAINT PK_atbl_Example_Users PRIMARY KEY (PrimKey)
    );
END
GO

CREATE OR ALTER TRIGGER trg_atbl_Example_Users_Updated
ON atbl_Example_Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE atbl_Example_Users
    SET    Updated = SYSDATETIME()
    FROM   atbl_Example_Users u
    INNER JOIN inserted i ON u.PrimKey = i.PrimKey;
END
GO

-- ============================================================
-- Table: atbl_Example_Posts
-- Each post has an author (FK → atbl_Example_Users)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'atbl_Example_Posts' AND xtype = 'U')
BEGIN
    CREATE TABLE atbl_Example_Posts (
        PrimKey   UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_atbl_Example_Posts_PrimKey   DEFAULT NEWID(),
        AuthorKey UNIQUEIDENTIFIER NOT NULL,
        Title     NVARCHAR(500)    NOT NULL,
        Body      NVARCHAR(MAX)    NULL,
        Created   DATETIME2        NOT NULL CONSTRAINT DF_atbl_Example_Posts_Created   DEFAULT SYSDATETIME(),
        Updated   DATETIME2        NULL,
        CONSTRAINT PK_atbl_Example_Posts            PRIMARY KEY (PrimKey),
        CONSTRAINT FK_atbl_Example_Posts_Author     FOREIGN KEY (AuthorKey)
            REFERENCES atbl_Example_Users (PrimKey)
    );
END
GO

CREATE OR ALTER TRIGGER trg_atbl_Example_Posts_Updated
ON atbl_Example_Posts
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE atbl_Example_Posts
    SET    Updated = SYSDATETIME()
    FROM   atbl_Example_Posts p
    INNER JOIN inserted i ON p.PrimKey = i.PrimKey;
END
GO

-- ============================================================
-- Table: atbl_Example_Comments
-- Each comment belongs to a post (FK → atbl_Example_Posts)
-- and has an author (FK → atbl_Example_Users)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'atbl_Example_Comments' AND xtype = 'U')
BEGIN
    CREATE TABLE atbl_Example_Comments (
        PrimKey   UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_atbl_Example_Comments_PrimKey   DEFAULT NEWID(),
        PostKey   UNIQUEIDENTIFIER NOT NULL,
        AuthorKey UNIQUEIDENTIFIER NOT NULL,
        Body      NVARCHAR(MAX)    NOT NULL,
        Created   DATETIME2        NOT NULL CONSTRAINT DF_atbl_Example_Comments_Created   DEFAULT SYSDATETIME(),
        Updated   DATETIME2        NULL,
        CONSTRAINT PK_atbl_Example_Comments            PRIMARY KEY (PrimKey),
        CONSTRAINT FK_atbl_Example_Comments_Post        FOREIGN KEY (PostKey)
            REFERENCES atbl_Example_Posts (PrimKey),
        CONSTRAINT FK_atbl_Example_Comments_Author      FOREIGN KEY (AuthorKey)
            REFERENCES atbl_Example_Users (PrimKey)
    );
END
GO

CREATE OR ALTER TRIGGER trg_atbl_Example_Comments_Updated
ON atbl_Example_Comments
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE atbl_Example_Comments
    SET    Updated = SYSDATETIME()
    FROM   atbl_Example_Comments c
    INNER JOIN inserted i ON c.PrimKey = i.PrimKey;
END
GO
