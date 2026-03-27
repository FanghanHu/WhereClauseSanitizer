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
        Author_ID UNIQUEIDENTIFIER NOT NULL,
        Title     NVARCHAR(500)    NOT NULL,
        Body      NVARCHAR(MAX)    NULL,
        Created   DATETIME2        NOT NULL CONSTRAINT DF_atbl_Example_Posts_Created   DEFAULT SYSDATETIME(),
        Updated   DATETIME2        NULL,
        CONSTRAINT PK_atbl_Example_Posts            PRIMARY KEY (PrimKey),
        CONSTRAINT FK_atbl_Example_Posts_Author     FOREIGN KEY (Author_ID)
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
        Post_ID   UNIQUEIDENTIFIER NOT NULL,
        Author_ID UNIQUEIDENTIFIER NOT NULL,
        Body      NVARCHAR(MAX)    NOT NULL,
        Created   DATETIME2        NOT NULL CONSTRAINT DF_atbl_Example_Comments_Created   DEFAULT SYSDATETIME(),
        Updated   DATETIME2        NULL,
        CONSTRAINT PK_atbl_Example_Comments            PRIMARY KEY (PrimKey),
        CONSTRAINT FK_atbl_Example_Comments_Post        FOREIGN KEY (Post_ID)
            REFERENCES atbl_Example_Posts (PrimKey),
        CONSTRAINT FK_atbl_Example_Comments_Author      FOREIGN KEY (Author_ID)
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

-- ============================================================
-- Seed data: 3 users, 5 posts, 15 comments
-- Idempotent inserts keyed by fixed PrimKey values.
-- ============================================================

INSERT INTO atbl_Example_Users (PrimKey, Username, Email)
SELECT CAST('11111111-1111-1111-1111-111111111111' AS UNIQUEIDENTIFIER), N'alice',   N'alice@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Users
    WHERE PrimKey = CAST('11111111-1111-1111-1111-111111111111' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Users (PrimKey, Username, Email)
SELECT CAST('22222222-2222-2222-2222-222222222222' AS UNIQUEIDENTIFIER), N'bob',     N'bob@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Users
    WHERE PrimKey = CAST('22222222-2222-2222-2222-222222222222' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Users (PrimKey, Username, Email)
SELECT CAST('33333333-3333-3333-3333-333333333333' AS UNIQUEIDENTIFIER), N'charlie', N'charlie@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Users
    WHERE PrimKey = CAST('33333333-3333-3333-3333-333333333333' AS UNIQUEIDENTIFIER)
);
GO

INSERT INTO atbl_Example_Posts (PrimKey, Author_ID, Title, Body)
SELECT
    CAST('aaaaaaaa-0000-0000-0000-000000000001' AS UNIQUEIDENTIFIER),
    CAST('11111111-1111-1111-1111-111111111111' AS UNIQUEIDENTIFIER),
    N'Getting Started With Where Clause Sanitization',
    N'This post introduces why sanitizing dynamic WHERE clauses matters.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Posts
    WHERE PrimKey = CAST('aaaaaaaa-0000-0000-0000-000000000001' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Posts (PrimKey, Author_ID, Title, Body)
SELECT
    CAST('aaaaaaaa-0000-0000-0000-000000000002' AS UNIQUEIDENTIFIER),
    CAST('22222222-2222-2222-2222-222222222222' AS UNIQUEIDENTIFIER),
    N'Common SQL Injection Pitfalls',
    N'Examples of unsafe string concatenation and safer alternatives.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Posts
    WHERE PrimKey = CAST('aaaaaaaa-0000-0000-0000-000000000002' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Posts (PrimKey, Author_ID, Title, Body)
SELECT
    CAST('aaaaaaaa-0000-0000-0000-000000000003' AS UNIQUEIDENTIFIER),
    CAST('33333333-3333-3333-3333-333333333333' AS UNIQUEIDENTIFIER),
    N'Parameterization Patterns in T-SQL',
    N'A quick walkthrough of parameterized query approaches in SQL Server.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Posts
    WHERE PrimKey = CAST('aaaaaaaa-0000-0000-0000-000000000003' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Posts (PrimKey, Author_ID, Title, Body)
SELECT
    CAST('aaaaaaaa-0000-0000-0000-000000000004' AS UNIQUEIDENTIFIER),
    CAST('11111111-1111-1111-1111-111111111111' AS UNIQUEIDENTIFIER),
    N'Building a Reusable Filter Builder',
    N'How to centralize validation and generate reliable filter clauses.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Posts
    WHERE PrimKey = CAST('aaaaaaaa-0000-0000-0000-000000000004' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Posts (PrimKey, Author_ID, Title, Body)
SELECT
    CAST('aaaaaaaa-0000-0000-0000-000000000005' AS UNIQUEIDENTIFIER),
    CAST('22222222-2222-2222-2222-222222222222' AS UNIQUEIDENTIFIER),
    N'Testing Sanitizer Edge Cases',
    N'Test ideas for malformed operators, null checks, and nested conditions.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Posts
    WHERE PrimKey = CAST('aaaaaaaa-0000-0000-0000-000000000005' AS UNIQUEIDENTIFIER)
);
GO

INSERT INTO atbl_Example_Comments (PrimKey, Post_ID, Author_ID, Body)
SELECT
    CAST('bbbbbbbb-0000-0000-0000-000000000001' AS UNIQUEIDENTIFIER),
    CAST('aaaaaaaa-0000-0000-0000-000000000001' AS UNIQUEIDENTIFIER),
    CAST('22222222-2222-2222-2222-222222222222' AS UNIQUEIDENTIFIER),
    N'Great primer. The examples are easy to follow.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Comments
    WHERE PrimKey = CAST('bbbbbbbb-0000-0000-0000-000000000001' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Comments (PrimKey, Post_ID, Author_ID, Body)
SELECT
    CAST('bbbbbbbb-0000-0000-0000-000000000002' AS UNIQUEIDENTIFIER),
    CAST('aaaaaaaa-0000-0000-0000-000000000001' AS UNIQUEIDENTIFIER),
    CAST('33333333-3333-3333-3333-333333333333' AS UNIQUEIDENTIFIER),
    N'Could you add an example with multiple optional filters?'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Comments
    WHERE PrimKey = CAST('bbbbbbbb-0000-0000-0000-000000000002' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Comments (PrimKey, Post_ID, Author_ID, Body)
SELECT
    CAST('bbbbbbbb-0000-0000-0000-000000000003' AS UNIQUEIDENTIFIER),
    CAST('aaaaaaaa-0000-0000-0000-000000000001' AS UNIQUEIDENTIFIER),
    CAST('11111111-1111-1111-1111-111111111111' AS UNIQUEIDENTIFIER),
    N'Thanks! I will add a follow-up with advanced filters.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Comments
    WHERE PrimKey = CAST('bbbbbbbb-0000-0000-0000-000000000003' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Comments (PrimKey, Post_ID, Author_ID, Body)
SELECT
    CAST('bbbbbbbb-0000-0000-0000-000000000004' AS UNIQUEIDENTIFIER),
    CAST('aaaaaaaa-0000-0000-0000-000000000002' AS UNIQUEIDENTIFIER),
    CAST('11111111-1111-1111-1111-111111111111' AS UNIQUEIDENTIFIER),
    N'This section on wildcards is especially useful.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Comments
    WHERE PrimKey = CAST('bbbbbbbb-0000-0000-0000-000000000004' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Comments (PrimKey, Post_ID, Author_ID, Body)
SELECT
    CAST('bbbbbbbb-0000-0000-0000-000000000005' AS UNIQUEIDENTIFIER),
    CAST('aaaaaaaa-0000-0000-0000-000000000002' AS UNIQUEIDENTIFIER),
    CAST('33333333-3333-3333-3333-333333333333' AS UNIQUEIDENTIFIER),
    N'I have seen this mistake in old codebases a lot.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Comments
    WHERE PrimKey = CAST('bbbbbbbb-0000-0000-0000-000000000005' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Comments (PrimKey, Post_ID, Author_ID, Body)
SELECT
    CAST('bbbbbbbb-0000-0000-0000-000000000006' AS UNIQUEIDENTIFIER),
    CAST('aaaaaaaa-0000-0000-0000-000000000002' AS UNIQUEIDENTIFIER),
    CAST('22222222-2222-2222-2222-222222222222' AS UNIQUEIDENTIFIER),
    N'Glad it helped. Parameterization should be the default approach.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Comments
    WHERE PrimKey = CAST('bbbbbbbb-0000-0000-0000-000000000006' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Comments (PrimKey, Post_ID, Author_ID, Body)
SELECT
    CAST('bbbbbbbb-0000-0000-0000-000000000007' AS UNIQUEIDENTIFIER),
    CAST('aaaaaaaa-0000-0000-0000-000000000003' AS UNIQUEIDENTIFIER),
    CAST('11111111-1111-1111-1111-111111111111' AS UNIQUEIDENTIFIER),
    N'Nice breakdown. It makes dynamic SQL feel less scary.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Comments
    WHERE PrimKey = CAST('bbbbbbbb-0000-0000-0000-000000000007' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Comments (PrimKey, Post_ID, Author_ID, Body)
SELECT
    CAST('bbbbbbbb-0000-0000-0000-000000000008' AS UNIQUEIDENTIFIER),
    CAST('aaaaaaaa-0000-0000-0000-000000000003' AS UNIQUEIDENTIFIER),
    CAST('22222222-2222-2222-2222-222222222222' AS UNIQUEIDENTIFIER),
    N'Would love a benchmark comparison in a future post.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Comments
    WHERE PrimKey = CAST('bbbbbbbb-0000-0000-0000-000000000008' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Comments (PrimKey, Post_ID, Author_ID, Body)
SELECT
    CAST('bbbbbbbb-0000-0000-0000-000000000009' AS UNIQUEIDENTIFIER),
    CAST('aaaaaaaa-0000-0000-0000-000000000003' AS UNIQUEIDENTIFIER),
    CAST('33333333-3333-3333-3333-333333333333' AS UNIQUEIDENTIFIER),
    N'Thanks, I can add timings with larger datasets.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Comments
    WHERE PrimKey = CAST('bbbbbbbb-0000-0000-0000-000000000009' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Comments (PrimKey, Post_ID, Author_ID, Body)
SELECT
    CAST('bbbbbbbb-0000-0000-0000-000000000010' AS UNIQUEIDENTIFIER),
    CAST('aaaaaaaa-0000-0000-0000-000000000004' AS UNIQUEIDENTIFIER),
    CAST('22222222-2222-2222-2222-222222222222' AS UNIQUEIDENTIFIER),
    N'The reusable validation layer idea is solid.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Comments
    WHERE PrimKey = CAST('bbbbbbbb-0000-0000-0000-000000000010' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Comments (PrimKey, Post_ID, Author_ID, Body)
SELECT
    CAST('bbbbbbbb-0000-0000-0000-000000000011' AS UNIQUEIDENTIFIER),
    CAST('aaaaaaaa-0000-0000-0000-000000000004' AS UNIQUEIDENTIFIER),
    CAST('33333333-3333-3333-3333-333333333333' AS UNIQUEIDENTIFIER),
    N'Can this be adapted for API query params too?'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Comments
    WHERE PrimKey = CAST('bbbbbbbb-0000-0000-0000-000000000011' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Comments (PrimKey, Post_ID, Author_ID, Body)
SELECT
    CAST('bbbbbbbb-0000-0000-0000-000000000012' AS UNIQUEIDENTIFIER),
    CAST('aaaaaaaa-0000-0000-0000-000000000004' AS UNIQUEIDENTIFIER),
    CAST('11111111-1111-1111-1111-111111111111' AS UNIQUEIDENTIFIER),
    N'Yes, the same validation model maps well to API filters.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Comments
    WHERE PrimKey = CAST('bbbbbbbb-0000-0000-0000-000000000012' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Comments (PrimKey, Post_ID, Author_ID, Body)
SELECT
    CAST('bbbbbbbb-0000-0000-0000-000000000013' AS UNIQUEIDENTIFIER),
    CAST('aaaaaaaa-0000-0000-0000-000000000005' AS UNIQUEIDENTIFIER),
    CAST('11111111-1111-1111-1111-111111111111' AS UNIQUEIDENTIFIER),
    N'Edge-case tests caught several regressions for us.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Comments
    WHERE PrimKey = CAST('bbbbbbbb-0000-0000-0000-000000000013' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Comments (PrimKey, Post_ID, Author_ID, Body)
SELECT
    CAST('bbbbbbbb-0000-0000-0000-000000000014' AS UNIQUEIDENTIFIER),
    CAST('aaaaaaaa-0000-0000-0000-000000000005' AS UNIQUEIDENTIFIER),
    CAST('22222222-2222-2222-2222-222222222222' AS UNIQUEIDENTIFIER),
    N'Same here. Null comparison logic is often overlooked.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Comments
    WHERE PrimKey = CAST('bbbbbbbb-0000-0000-0000-000000000014' AS UNIQUEIDENTIFIER)
);

INSERT INTO atbl_Example_Comments (PrimKey, Post_ID, Author_ID, Body)
SELECT
    CAST('bbbbbbbb-0000-0000-0000-000000000015' AS UNIQUEIDENTIFIER),
    CAST('aaaaaaaa-0000-0000-0000-000000000005' AS UNIQUEIDENTIFIER),
    CAST('33333333-3333-3333-3333-333333333333' AS UNIQUEIDENTIFIER),
    N'Please share your test matrix template if possible.'
WHERE NOT EXISTS (
    SELECT 1 FROM atbl_Example_Comments
    WHERE PrimKey = CAST('bbbbbbbb-0000-0000-0000-000000000015' AS UNIQUEIDENTIFIER)
);
GO
