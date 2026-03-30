'use strict';

const { TableSchema } = require('./queryBuilder');

/**
 * Central place to define every table schema.
 * Each schema inherits Created / Updated columns automatically via TableSchema.
 * Add new tables here — the common columns come for free.
 */

const Users = new TableSchema({
  tableName: 'atbl_Example_Users',
  columns: {
    PrimKey:  'UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID()',
    Username: 'NVARCHAR(100) NOT NULL',
    Email:    'NVARCHAR(255) NOT NULL'
  },
  primaryKey: 'PrimKey',
  uniqueConstraints: [['Username']]
});

const Posts = new TableSchema({
  tableName: 'atbl_Example_Posts',
  columns: {
    PrimKey:   'UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID()',
    Author_ID: 'UNIQUEIDENTIFIER NOT NULL',
    Title:     'NVARCHAR(500) NOT NULL',
    Body:      'NVARCHAR(MAX) NULL'
  },
  primaryKey: 'PrimKey',
  foreignKeys: [
    { column: 'Author_ID', references: 'atbl_Example_Users (PrimKey)' }
  ]
});

const Comments = new TableSchema({
  tableName: 'atbl_Example_Comments',
  columns: {
    PrimKey:   'UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID()',
    Post_ID:   'UNIQUEIDENTIFIER NOT NULL',
    Author_ID: 'UNIQUEIDENTIFIER NOT NULL',
    Body:      'NVARCHAR(MAX) NOT NULL'
  },
  primaryKey: 'PrimKey',
  foreignKeys: [
    { column: 'Post_ID',   references: 'atbl_Example_Posts (PrimKey)' },
    { column: 'Author_ID', references: 'atbl_Example_Users (PrimKey)' }
  ]
});

module.exports = { Users, Posts, Comments };
