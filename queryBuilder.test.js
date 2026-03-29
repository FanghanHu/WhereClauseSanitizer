'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { TableSchema, BASE_COLUMNS } = require('./queryBuilder');
const { Users, Posts, Comments } = require('./schemas');

// ---------------------------------------------------------------------------
// BASE_COLUMNS
// ---------------------------------------------------------------------------
describe('BASE_COLUMNS', () => {
  it('includes Created and Updated', () => {
    assert.ok('Created' in BASE_COLUMNS);
    assert.ok('Updated' in BASE_COLUMNS);
  });
});

// ---------------------------------------------------------------------------
// TableSchema — createTable()
// ---------------------------------------------------------------------------
describe('TableSchema.createTable()', () => {
  it('inherits Created and Updated from base columns', () => {
    const sql = Users.createTable();
    assert.match(sql, /Created\s+DATETIME2/);
    assert.match(sql, /Updated\s+DATETIME2/);
  });

  it('emits PRIMARY KEY constraint', () => {
    const sql = Users.createTable();
    assert.match(sql, /CONSTRAINT PK_atbl_Example_Users PRIMARY KEY \(PrimKey\)/);
  });

  it('emits UNIQUE constraint', () => {
    const sql = Users.createTable();
    assert.match(sql, /CONSTRAINT UQ_atbl_Example_Users_Username UNIQUE \(Username\)/);
  });

  it('emits FOREIGN KEY constraint for Posts', () => {
    const sql = Posts.createTable();
    assert.match(sql, /CONSTRAINT FK_atbl_Example_Posts_Author_ID FOREIGN KEY \(Author_ID\)/);
    assert.match(sql, /REFERENCES atbl_Example_Users \(PrimKey\)/);
  });

  it('emits both FOREIGN KEY constraints for Comments', () => {
    const sql = Comments.createTable();
    assert.match(sql, /CONSTRAINT FK_atbl_Example_Comments_Post_ID/);
    assert.match(sql, /CONSTRAINT FK_atbl_Example_Comments_Author_ID/);
  });

  it('creates a table with no constraints when none are provided', () => {
    const schema = new TableSchema({
      tableName: 'atbl_Example_Bare',
      columns: { Note: 'NVARCHAR(255) NULL' }
    });
    const sql = schema.createTable();
    assert.match(sql, /CREATE TABLE atbl_Example_Bare/);
    assert.doesNotMatch(sql, /CONSTRAINT/);
  });
});

// ---------------------------------------------------------------------------
// TableSchema — select()
// ---------------------------------------------------------------------------
describe('TableSchema.select()', () => {
  it('generates a simple SELECT without options', () => {
    const { sql, inputs } = Users.select();
    assert.match(sql, /SELECT \*/);
    assert.match(sql, /FROM atbl_Example_Users/);
    assert.equal(inputs.length, 0);
  });

  it('includes specified columns', () => {
    const { sql } = Users.select({ columns: ['PrimKey AS id', 'Username', 'Email'] });
    assert.match(sql, /SELECT PrimKey AS id, Username, Email/);
  });

  it('uses alias in FROM clause', () => {
    const { sql } = Posts.select({ alias: 'p', columns: ['p.PrimKey AS id'] });
    assert.match(sql, /FROM atbl_Example_Posts p/);
  });

  it('appends JOIN clauses', () => {
    const join = 'INNER JOIN atbl_Example_Users u ON u.PrimKey = p.Author_ID';
    const { sql } = Posts.select({ alias: 'p', columns: ['p.Title'], joins: [join] });
    assert.match(sql, /INNER JOIN atbl_Example_Users u ON u\.PrimKey = p\.Author_ID/);
  });

  it('appends ORDER BY clause', () => {
    const { sql } = Users.select({ columns: ['Username'], orderBy: ['Username'] });
    assert.match(sql, /ORDER BY Username/);
  });

  it('builds WHERE clause and returns inputs', () => {
    const { sql, inputs } = Users.select({
      columns: ['Username'],
      where: { 'u.PrimKey': 'abc-123' }
    });
    assert.match(sql, /WHERE u\.PrimKey = @w0/);
    assert.equal(inputs.length, 1);
    assert.equal(inputs[0].name, 'w0');
    assert.equal(inputs[0].value, 'abc-123');
  });

  it('accepts a plain string for columns', () => {
    const { sql } = Users.select({ columns: 'COUNT(*) AS total' });
    assert.match(sql, /SELECT COUNT\(\*\) AS total/);
  });
});

// ---------------------------------------------------------------------------
// TableSchema — insert()
// ---------------------------------------------------------------------------
describe('TableSchema.insert()', () => {
  it('generates INSERT SQL with column list and VALUES', () => {
    const { sql } = Users.insert({ Username: 'alice', Email: 'alice@example.com' });
    assert.match(sql, /INSERT INTO atbl_Example_Users \(Username, Email\)/);
    assert.match(sql, /VALUES \(@Username, @Email\)/);
  });

  it('returns the correct inputs array', () => {
    const { inputs } = Users.insert({ Username: 'alice', Email: 'alice@example.com' });
    assert.equal(inputs.length, 2);
    assert.deepEqual(inputs[0], { name: 'Username', value: 'alice' });
    assert.deepEqual(inputs[1], { name: 'Email', value: 'alice@example.com' });
  });
});

// ---------------------------------------------------------------------------
// TableSchema — update()
// ---------------------------------------------------------------------------
describe('TableSchema.update()', () => {
  it('generates UPDATE SQL with SET and WHERE', () => {
    const { sql } = Users.update({ Email: 'new@example.com' }, { PrimKey: 'abc-123' });
    assert.match(sql, /UPDATE atbl_Example_Users/);
    assert.match(sql, /SET Email = @set_Email/);
    assert.match(sql, /WHERE PrimKey = @where_PrimKey/);
  });

  it('returns data inputs prefixed with set_ and where inputs prefixed with where_', () => {
    const { inputs } = Users.update({ Email: 'new@example.com' }, { PrimKey: 'abc-123' });
    assert.equal(inputs.length, 2);
    assert.deepEqual(inputs[0], { name: 'set_Email', value: 'new@example.com' });
    assert.deepEqual(inputs[1], { name: 'where_PrimKey', value: 'abc-123' });
  });

  it('supports multiple SET and WHERE columns', () => {
    const { sql, inputs } = Users.update(
      { Username: 'bob', Email: 'bob@example.com' },
      { PrimKey: 'abc-123' }
    );
    assert.match(sql, /SET Username = @set_Username, Email = @set_Email/);
    assert.equal(inputs.length, 3);
  });
});

// ---------------------------------------------------------------------------
// Schemas — columns are inherited correctly
// ---------------------------------------------------------------------------
describe('Schemas column inheritance', () => {
  it('Users schema has Created and Updated columns', () => {
    assert.ok('Created' in Users.columns);
    assert.ok('Updated' in Users.columns);
  });

  it('Posts schema has Created and Updated columns', () => {
    assert.ok('Created' in Posts.columns);
    assert.ok('Updated' in Posts.columns);
  });

  it('Comments schema has Created and Updated columns', () => {
    assert.ok('Created' in Comments.columns);
    assert.ok('Updated' in Comments.columns);
  });

  it('table-specific columns appear before the base columns', () => {
    const keys = Object.keys(Users.columns);
    const createdIdx = keys.indexOf('Created');
    const primKeyIdx = keys.indexOf('PrimKey');
    assert.ok(primKeyIdx < createdIdx, 'PrimKey should come before Created');
  });
});
