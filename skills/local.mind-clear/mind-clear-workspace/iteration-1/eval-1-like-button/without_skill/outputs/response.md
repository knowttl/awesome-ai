A simple version is:

1. Add a `likes_count` column to `posts`
2. Create an endpoint like `POST /posts/:id/like`
3. When clicked, run an atomic DB update:

```sql
UPDATE posts
SET likes_count = likes_count + 1
WHERE id = ?;
```

Then return the new count to the client.

A minimal server flow:

```js
app.post('/posts/:id/like', async (req, res) => {
  const { id } = req.params;

  await db.query(
    'UPDATE posts SET likes_count = likes_count + 1 WHERE id = ?',
    [id]
  );

  const [post] = await db.query(
    'SELECT likes_count FROM posts WHERE id = ?',
    [id]
  );

  res.json({ likesCount: post.likes_count });
});
```

On the frontend, call that endpoint on button click and update the displayed count.

One important note: if users should only be able to like once, you’ll also need a `post_likes` join table (user_id, post_id) instead of only incrementing a counter, otherwise the same user can spam likes.
