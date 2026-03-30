const express = require("express");
const sql = require("mssql");
const path = require("path");
const { Users, Posts, Comments } = require("./schemas");

const app = express();
const port = Number(process.env.PORT || 3000);

const dbConfig = {
  server: process.env.DB_SERVER || "localhost",
  port: Number(process.env.DB_PORT || 1433),
  user: process.env.DB_USER || "sa",
  password: process.env.DB_PASSWORD || process.env.MSSQL_SA_PASSWORD || "Str0ng!Passw0rd",
  database: process.env.DB_DATABASE || "ExampleDB",
  options: {
    encrypt: true,
    trustServerCertificate: true
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  }
};

let poolPromise;

function getPool() {
  if (!poolPromise) {
    poolPromise = sql.connect(dbConfig);
  }
  return poolPromise;
}

async function loadFeed() {
  const pool = await getPool();

  const usersSql = Users.select({
    columns: ["PrimKey AS id", "Username", "Email"],
    orderBy: ["Username"]
  }).sql;

  const postsSql = Posts.select({
    alias: "p",
    columns: [
      "p.PrimKey AS id",
      "p.Author_ID AS authorId",
      "p.Title",
      "p.Body",
      "u.Username AS authorUsername"
    ],
    joins: ["INNER JOIN atbl_Example_Users u ON u.PrimKey = p.Author_ID"],
    orderBy: ["p.Created", "p.PrimKey"]
  }).sql;

  const commentsSql = Comments.select({
    alias: "c",
    columns: [
      "c.PrimKey AS id",
      "c.Post_ID AS postId",
      "c.Author_ID AS authorId",
      "c.Body",
      "u.Username AS authorUsername"
    ],
    joins: ["INNER JOIN atbl_Example_Users u ON u.PrimKey = c.Author_ID"],
    orderBy: ["c.Created", "c.PrimKey"]
  }).sql;

  const usersResult = await pool.request().query(usersSql);
  const postsResult = await pool.request().query(postsSql);
  const commentsResult = await pool.request().query(commentsSql);

  const users = usersResult.recordset.map((row) => ({
    id: row.id,
    username: row.Username,
    email: row.Email
  }));

  const posts = postsResult.recordset.map((row) => ({
    id: row.id,
    authorId: row.authorId,
    authorUsername: row.authorUsername,
    title: row.Title,
    body: row.Body
  }));

  const comments = commentsResult.recordset.map((row) => ({
    id: row.id,
    postId: row.postId,
    authorId: row.authorId,
    authorUsername: row.authorUsername,
    body: row.Body
  }));

  return { users, posts, comments };
}

app.get("/api/feed", async (req, res) => {
  try {
    const feed = await loadFeed();
    res.json(feed);
  } catch (error) {
    res.status(500).json({
      error: "Failed to load data from SQL Server.",
      details: error.message
    });
  }
});

app.use(express.static(path.join(__dirname)));

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "index.html"));
});

app.listen(port, () => {
  console.log(`Web app listening at http://localhost:${port}`);
});
