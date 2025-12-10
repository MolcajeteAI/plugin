---
name: query-optimization
description: Database query optimization strategies. Use when improving query performance.
---

# Query Optimization Skill

This skill covers database query optimization for Node.js applications.

## When to Use

Use this skill when:
- Queries are slow
- Database CPU is high
- Optimizing N+1 queries
- Adding indexes strategically

## Core Principle

**MEASURE FIRST, OPTIMIZE SECOND** - Profile before optimizing. The bottleneck is often not where you expect.

## N+1 Query Prevention

### The Problem

```typescript
// BAD: N+1 queries
const posts = await prisma.post.findMany();

for (const post of posts) {
  // This runs a query for each post!
  const author = await prisma.user.findUnique({
    where: { id: post.authorId },
  });
  console.log(`${post.title} by ${author?.name}`);
}
```

### The Solution

```typescript
// GOOD: Single query with include
const posts = await prisma.post.findMany({
  include: {
    author: {
      select: { id: true, name: true },
    },
  },
});

for (const post of posts) {
  console.log(`${post.title} by ${post.author.name}`);
}
```

### DataLoader Pattern

```typescript
// src/lib/dataloader.ts
import DataLoader from 'dataloader';
import { PrismaClient } from '@prisma/client';

export function createUserLoader(prisma: PrismaClient) {
  return new DataLoader<string, User | null>(async (ids) => {
    const users = await prisma.user.findMany({
      where: { id: { in: [...ids] } },
    });

    const userMap = new Map(users.map((u) => [u.id, u]));
    return ids.map((id) => userMap.get(id) ?? null);
  });
}

// Usage
const userLoader = createUserLoader(prisma);
const posts = await prisma.post.findMany();

// Batches all user lookups into single query
const postsWithAuthors = await Promise.all(
  posts.map(async (post) => ({
    ...post,
    author: await userLoader.load(post.authorId),
  }))
);
```

## Index Strategies

### When to Add Indexes

```sql
-- Columns in WHERE clauses
CREATE INDEX posts_author_id_idx ON posts(author_id);

-- Columns in JOIN conditions
CREATE INDEX comments_post_id_idx ON comments(post_id);

-- Columns in ORDER BY
CREATE INDEX posts_created_at_idx ON posts(created_at DESC);

-- Compound indexes for combined queries
CREATE INDEX posts_published_created_idx ON posts(published, created_at DESC);
```

### Prisma Index Definition

```prisma
model Post {
  id        String   @id
  authorId  String
  published Boolean
  createdAt DateTime

  @@index([authorId])
  @@index([published, createdAt(sort: Desc)])
}
```

### Drizzle Index Definition

```typescript
export const posts = pgTable('posts', {
  id: text('id').primaryKey(),
  authorId: text('author_id'),
  published: boolean('published'),
  createdAt: timestamp('created_at'),
}, (table) => ({
  authorIdx: index('posts_author_idx').on(table.authorId),
  publishedCreatedIdx: index('posts_published_created_idx')
    .on(table.published, desc(table.createdAt)),
}));
```

## Query Analysis

### Explain Analyze

```typescript
// Prisma
const result = await prisma.$queryRaw`
  EXPLAIN ANALYZE
  SELECT * FROM posts WHERE author_id = ${userId}
`;
console.log(result);

// Drizzle
const result = await db.execute(sql`
  EXPLAIN ANALYZE
  SELECT * FROM posts WHERE author_id = ${userId}
`);
```

### Query Logging

```typescript
// Prisma with query logging
const prisma = new PrismaClient({
  log: [
    {
      emit: 'event',
      level: 'query',
    },
  ],
});

prisma.$on('query', (e) => {
  if (e.duration > 100) { // Log slow queries (>100ms)
    console.warn('Slow query:', {
      query: e.query,
      duration: `${e.duration}ms`,
    });
  }
});
```

## Pagination Optimization

### Offset Pagination (Simple but Slow)

```typescript
// Gets slower as offset increases
const posts = await prisma.post.findMany({
  skip: (page - 1) * perPage,
  take: perPage,
  orderBy: { createdAt: 'desc' },
});
```

### Cursor Pagination (Fast)

```typescript
// Constant performance regardless of page
async function getPosts(cursor?: string, limit = 20) {
  const posts = await prisma.post.findMany({
    take: limit + 1, // Fetch one extra to check if more exist
    cursor: cursor ? { id: cursor } : undefined,
    orderBy: { createdAt: 'desc' },
  });

  const hasMore = posts.length > limit;
  const items = hasMore ? posts.slice(0, -1) : posts;
  const nextCursor = hasMore ? items[items.length - 1]?.id : null;

  return { items, nextCursor, hasMore };
}
```

## Select Only What You Need

```typescript
// BAD: Fetching all columns
const users = await prisma.user.findMany();

// GOOD: Select specific columns
const users = await prisma.user.findMany({
  select: {
    id: true,
    name: true,
    email: true,
  },
});

// Drizzle equivalent
const users = await db
  .select({
    id: users.id,
    name: users.name,
    email: users.email,
  })
  .from(users);
```

## Batch Operations

```typescript
// BAD: Individual inserts
for (const item of items) {
  await prisma.item.create({ data: item });
}

// GOOD: Batch insert
await prisma.item.createMany({
  data: items,
});

// Drizzle batch insert
await db.insert(items).values(itemsData);
```

## Connection Pooling

```typescript
// Prisma connection pool
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL,
    },
  },
});

// For serverless, use external pooler (PgBouncer, Supabase Pooler)
// DATABASE_URL=postgres://...?pgbouncer=true
```

## Caching Strategies

```typescript
// In-memory cache for frequently accessed data
import { LRUCache } from 'lru-cache';

const userCache = new LRUCache<string, User>({
  max: 500,
  ttl: 1000 * 60 * 5, // 5 minutes
});

async function getUserById(id: string): Promise<User | null> {
  const cached = userCache.get(id);
  if (cached) return cached;

  const user = await prisma.user.findUnique({ where: { id } });
  if (user) userCache.set(id, user);
  return user;
}

// Invalidate on update
async function updateUser(id: string, data: UserUpdate): Promise<User> {
  const user = await prisma.user.update({ where: { id }, data });
  userCache.set(id, user);
  return user;
}
```

## Query Optimization Checklist

1. **Check indexes** - Ensure WHERE/JOIN columns are indexed
2. **Avoid SELECT *** - Select only needed columns
3. **Use includes** - Prevent N+1 queries
4. **Cursor pagination** - For large datasets
5. **Batch operations** - Group inserts/updates
6. **Connection pooling** - Especially for serverless
7. **Query caching** - For read-heavy data

## Monitoring Queries

```typescript
// Prisma metrics
import { Prisma } from '@prisma/client';

const prisma = new PrismaClient().$extends({
  query: {
    $allOperations({ operation, model, args, query }) {
      const start = performance.now();
      return query(args).finally(() => {
        const duration = performance.now() - start;
        if (duration > 100) {
          console.warn(`Slow ${model}.${operation}: ${duration.toFixed(2)}ms`);
        }
      });
    },
  },
});
```

## Best Practices

1. **Profile first** - Measure before optimizing
2. **Index strategically** - Not every column needs an index
3. **Monitor slow queries** - Set up alerts
4. **Use EXPLAIN ANALYZE** - Understand query plans
5. **Test with production data** - Performance varies with data size
6. **Review regularly** - Queries that were fast may become slow

## Notes

- Indexes speed up reads but slow down writes
- Composite indexes order matters
- Cursor pagination is preferred for APIs
- Cache invalidation is harder than caching
