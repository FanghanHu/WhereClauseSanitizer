'use strict';

/**
 * Columns automatically added to every table schema.
 * Define once here, inherited everywhere — no more copy-pasting Created/Updated.
 */
const BASE_COLUMNS = {
  Created: 'DATETIME2 NOT NULL DEFAULT SYSDATETIME()',
  Updated: 'DATETIME2 NULL'
};

/**
 * Lightweight schema-driven query builder.
 *
 * Defines a table once (columns, PK, UQ, FK) and exposes helper methods
 * that return parameterised SQL + the matching mssql `request.input` list.
 * No ORM — the caller still owns the mssql connection and executes the query.
 *
 * @example
 * const Users = new TableSchema({
 *   tableName: 'atbl_Example_Users',
 *   columns: { PrimKey: 'UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID()', Username: 'NVARCHAR(100) NOT NULL' },
 *   primaryKey: 'PrimKey',
 *   uniqueConstraints: [['Username']]
 * });
 *
 * const { sql } = Users.select({ columns: ['PrimKey AS id', 'Username'], orderBy: ['Username'] });
 * const { sql, inputs } = Users.insert({ Username: 'alice' });
 */
class TableSchema {
  /**
   * @param {Object}   options
   * @param {string}   options.tableName            - SQL table name
   * @param {Object}   options.columns              - Table-specific column definitions { name: 'SQL definition' }
   * @param {string}   [options.primaryKey]         - Primary key column name
   * @param {string[][]} [options.uniqueConstraints] - Arrays of column names for UNIQUE constraints
   * @param {Array<{column: string, references: string}>} [options.foreignKeys] - Foreign key definitions
   */
  constructor({ tableName, columns, primaryKey, uniqueConstraints = [], foreignKeys = [] }) {
    this.tableName = tableName;
    // Table-specific columns come first; common timestamp columns are appended.
    this.columns = { ...columns, ...BASE_COLUMNS };
    this.primaryKey = primaryKey;
    this.uniqueConstraints = uniqueConstraints;
    this.foreignKeys = foreignKeys;
  }

  /**
   * Generates a CREATE TABLE SQL statement for this schema.
   * Idempotent guard (IF NOT EXISTS) is left to the caller / migration runner.
   *
   * @returns {string}
   */
  createTable() {
    const columnDefs = Object.entries(this.columns)
      .map(([name, def]) => `  ${name} ${def}`)
      .join(',\n');

    const constraintLines = [];

    if (this.primaryKey) {
      constraintLines.push(
        `  CONSTRAINT PK_${this.tableName} PRIMARY KEY (${this.primaryKey})`
      );
    }

    for (const cols of this.uniqueConstraints) {
      const colArray = Array.isArray(cols) ? cols : [cols];
      constraintLines.push(
        `  CONSTRAINT UQ_${this.tableName}_${colArray.join('_')} UNIQUE (${colArray.join(', ')})`
      );
    }

    for (const fk of this.foreignKeys) {
      constraintLines.push(
        `  CONSTRAINT FK_${this.tableName}_${fk.column} FOREIGN KEY (${fk.column}) REFERENCES ${fk.references}`
      );
    }

    const body =
      constraintLines.length > 0
        ? `${columnDefs},\n${constraintLines.join(',\n')}`
        : columnDefs;

    return `CREATE TABLE ${this.tableName} (\n${body}\n);`;
  }

  /**
   * Generates a CREATE OR ALTER TRIGGER statement that automatically sets the
   * `Updated` column to SYSDATETIME() whenever a row is modified.
   * This mirrors the standard Updated-column trigger shared by every table.
   *
   * Requires `primaryKey` to be set on the schema.
   *
   * @returns {string}
   */
  createUpdateTrigger() {
    if (!this.primaryKey) {
      throw new Error(
        `TableSchema(${this.tableName}): createUpdateTrigger() requires a primaryKey to be defined.`
      );
    }
    const triggerName = `trg_${this.tableName}_Updated`;
    return (
      `CREATE OR ALTER TRIGGER ${triggerName}\n` +
      `ON ${this.tableName}\n` +
      `AFTER UPDATE\n` +
      `AS\n` +
      `BEGIN\n` +
      `    SET NOCOUNT ON;\n` +
      `    UPDATE ${this.tableName}\n` +
      `    SET    Updated = SYSDATETIME()\n` +
      `    FROM   ${this.tableName} t\n` +
      `    INNER JOIN inserted i ON t.${this.primaryKey} = i.${this.primaryKey};\n` +
      `END`
    );
  }

  /**
   * Builds a SELECT query.
   *
   * @param {Object}         [options]
   * @param {string|string[]} [options.columns=['*']]  - Column expressions to select
   * @param {string}          [options.alias]          - Table alias used in FROM / WHERE / ORDER BY
   * @param {string[]}        [options.joins=[]]       - Full JOIN clauses
   * @param {Object}          [options.where={}]       - Equality filters: { 'columnExpr': value }
   * @param {string[]}        [options.orderBy=[]]     - ORDER BY expressions
   * @returns {{ sql: string, inputs: Array<{name: string, value: *}> }}
   */
  select({ columns = ['*'], alias, joins = [], where = {}, orderBy = [] } = {}) {
    const colList = Array.isArray(columns) ? columns.join(', ') : columns;
    const fromClause = alias ? `${this.tableName} ${alias}` : this.tableName;

    let sql = `SELECT ${colList}\nFROM ${fromClause}`;

    for (const join of joins) {
      sql += `\n${join}`;
    }

    const inputs = [];
    const whereClauses = Object.entries(where).map(([expr, value], idx) => {
      const paramName = `w${idx}`;
      inputs.push({ name: paramName, value });
      return `${expr} = @${paramName}`;
    });

    if (whereClauses.length > 0) {
      sql += `\nWHERE ${whereClauses.join(' AND ')}`;
    }

    if (orderBy.length > 0) {
      sql += `\nORDER BY ${orderBy.join(', ')}`;
    }

    return { sql, inputs };
  }

  /**
   * Builds a parameterised INSERT query.
   *
   * @param {Object} data - { columnName: value } pairs to insert
   * @returns {{ sql: string, inputs: Array<{name: string, value: *}> }}
   */
  insert(data) {
    const cols = Object.keys(data);
    const sql =
      `INSERT INTO ${this.tableName} (${cols.join(', ')})\n` +
      `VALUES (${cols.map((c) => `@${c}`).join(', ')});`;
    const inputs = cols.map((col) => ({ name: col, value: data[col] }));
    return { sql, inputs };
  }

  /**
   * Builds a parameterised UPDATE query.
   * Parameter names are prefixed with `set_` (data) and `where_` (filter) to
   * avoid collisions when the same column appears in both.
   *
   * @param {Object} data  - Columns to update: { columnName: newValue }
   * @param {Object} where - Equality filter:   { columnName: value }
   * @returns {{ sql: string, inputs: Array<{name: string, value: *}> }}
   */
  update(data, where) {
    const setClauses = Object.keys(data).map((col) => `${col} = @set_${col}`);
    const whereClauses = Object.keys(where).map((col) => `${col} = @where_${col}`);

    const sql =
      `UPDATE ${this.tableName}\n` +
      `SET ${setClauses.join(', ')}\n` +
      `WHERE ${whereClauses.join(' AND ')};`;

    const inputs = [
      ...Object.entries(data).map(([col, value]) => ({ name: `set_${col}`, value })),
      ...Object.entries(where).map(([col, value]) => ({ name: `where_${col}`, value }))
    ];

    return { sql, inputs };
  }
}

module.exports = { TableSchema, BASE_COLUMNS };
