---
name: api-versioning
description: API versioning strategies for Node.js backends. Use when implementing versioned APIs.
---

# API Versioning Skill

This skill covers API versioning strategies for maintaining backward compatibility.

## When to Use

Use this skill when:
- Building public APIs
- Planning for API evolution
- Supporting multiple API versions
- Deprecating old endpoints

## Core Principle

**BACKWARD COMPATIBILITY** - Existing clients should continue working. New features require new versions only when breaking changes are necessary.

## Versioning Strategies

### 1. URL Path Versioning (Recommended)

```typescript
// src/routes/index.ts
import { FastifyPluginAsync } from 'fastify';

const routes: FastifyPluginAsync = async (fastify) => {
  // Version 1
  await fastify.register(import('./v1'), { prefix: '/api/v1' });

  // Version 2
  await fastify.register(import('./v2'), { prefix: '/api/v2' });
};

export default routes;
```

```typescript
// src/routes/v1/users.ts
import { FastifyPluginAsync } from 'fastify';

const usersV1: FastifyPluginAsync = async (fastify) => {
  fastify.get('/', async () => {
    // V1 response format
    return fastify.db.user.findMany({
      select: { id: true, name: true, email: true },
    });
  });
};

export default usersV1;
```

```typescript
// src/routes/v2/users.ts
import { FastifyPluginAsync } from 'fastify';

const usersV2: FastifyPluginAsync = async (fastify) => {
  fastify.get('/', async () => {
    // V2 response format with pagination
    return {
      data: await fastify.db.user.findMany(),
      meta: {
        total: await fastify.db.user.count(),
        page: 1,
        perPage: 20,
      },
    };
  });
};

export default usersV2;
```

### 2. Header-Based Versioning

```typescript
// src/plugins/api-version.ts
import { FastifyPluginAsync, FastifyRequest } from 'fastify';
import fp from 'fastify-plugin';

declare module 'fastify' {
  interface FastifyRequest {
    apiVersion: string;
  }
}

const apiVersionPlugin: FastifyPluginAsync = async (fastify) => {
  fastify.decorateRequest('apiVersion', '');

  fastify.addHook('onRequest', async (request) => {
    const version = request.headers['api-version'] as string | undefined;
    request.apiVersion = version ?? '1';
  });
};

export default fp(apiVersionPlugin);
```

```typescript
// src/routes/users.ts
import { FastifyPluginAsync } from 'fastify';

const users: FastifyPluginAsync = async (fastify) => {
  fastify.get('/', async (request) => {
    const users = await fastify.db.user.findMany();

    // Response based on version
    if (request.apiVersion === '2') {
      return {
        data: users,
        meta: { total: users.length },
      };
    }

    // V1 default response
    return users;
  });
};

export default users;
```

### 3. Query Parameter Versioning

```typescript
// src/routes/users.ts
import { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';

const QuerySchema = z.object({
  version: z.enum(['1', '2']).default('1'),
});

const users: FastifyPluginAsync = async (fastify) => {
  fastify.get<{ Querystring: z.infer<typeof QuerySchema> }>('/', async (request) => {
    const { version } = request.query;
    const users = await fastify.db.user.findMany();

    if (version === '2') {
      return { data: users, meta: { total: users.length } };
    }

    return users;
  });
};

export default users;
```

## Version Router Pattern

```typescript
// src/lib/version-router.ts
import { FastifyPluginAsync, FastifyRequest, FastifyReply } from 'fastify';

type VersionHandler<T> = (
  request: FastifyRequest,
  reply: FastifyReply
) => Promise<T>;

interface VersionedHandlers<T> {
  v1: VersionHandler<T>;
  v2?: VersionHandler<T>;
  v3?: VersionHandler<T>;
}

export function createVersionedHandler<T>(
  handlers: VersionedHandlers<T>
): VersionHandler<T> {
  return async (request, reply) => {
    const version = request.apiVersion as keyof VersionedHandlers<T>;
    const handler = handlers[version] ?? handlers.v1;
    return handler(request, reply);
  };
}
```

```typescript
// Usage
import { createVersionedHandler } from '../lib/version-router';

fastify.get('/users', createVersionedHandler({
  v1: async (request) => {
    return fastify.db.user.findMany();
  },
  v2: async (request) => {
    return {
      data: await fastify.db.user.findMany(),
      meta: { version: 2 },
    };
  },
}));
```

## Deprecation Handling

```typescript
// src/plugins/deprecation.ts
import { FastifyPluginAsync } from 'fastify';
import fp from 'fastify-plugin';

interface DeprecatedRoute {
  path: string;
  method: string;
  sunsetDate: string;
  alternative?: string;
}

const deprecatedRoutes: DeprecatedRoute[] = [
  {
    path: '/api/v1/users',
    method: 'GET',
    sunsetDate: '2025-06-01',
    alternative: '/api/v2/users',
  },
];

const deprecationPlugin: FastifyPluginAsync = async (fastify) => {
  fastify.addHook('onSend', async (request, reply) => {
    const deprecated = deprecatedRoutes.find(
      (r) => r.path === request.url && r.method === request.method
    );

    if (deprecated) {
      reply.header('Deprecation', `date="${deprecated.sunsetDate}"`);
      reply.header('Sunset', deprecated.sunsetDate);
      if (deprecated.alternative) {
        reply.header('Link', `<${deprecated.alternative}>; rel="successor-version"`);
      }
    }
  });
};

export default fp(deprecationPlugin);
```

## Response Transformers

```typescript
// src/transformers/user.ts
import { User } from '@prisma/client';

interface UserV1Response {
  id: string;
  name: string;
  email: string;
}

interface UserV2Response {
  id: string;
  fullName: string;
  emailAddress: string;
  createdAt: string;
  updatedAt: string;
}

export function toUserV1(user: User): UserV1Response {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
  };
}

export function toUserV2(user: User): UserV2Response {
  return {
    id: user.id,
    fullName: user.name,
    emailAddress: user.email,
    createdAt: user.createdAt.toISOString(),
    updatedAt: user.updatedAt.toISOString(),
  };
}
```

## Versioned Schemas

```typescript
// src/schemas/user.ts
import { z } from 'zod';

// V1 Schema
export const UserV1Schema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string(),
});

// V2 Schema - Added fields
export const UserV2Schema = z.object({
  id: z.string(),
  fullName: z.string(),
  emailAddress: z.string(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
  profile: z.object({
    avatar: z.string().nullable(),
    bio: z.string().nullable(),
  }).optional(),
});

export type UserV1 = z.infer<typeof UserV1Schema>;
export type UserV2 = z.infer<typeof UserV2Schema>;
```

## Breaking vs Non-Breaking Changes

### Non-Breaking (Add to existing version)
- Adding new endpoints
- Adding optional fields to responses
- Adding optional query parameters
- Loosening validation rules

### Breaking (Requires new version)
- Removing fields from responses
- Renaming fields
- Changing field types
- Tightening validation rules
- Removing endpoints
- Changing endpoint paths

## Best Practices

1. **Default version** - Always have a default version
2. **Document changes** - Maintain changelog per version
3. **Deprecation notices** - Use headers for deprecation warnings
4. **Sunset dates** - Communicate end-of-life dates
5. **Support window** - Support at least 2 versions
6. **Breaking changes** - Only in major version bumps

## Notes

- URL versioning is most explicit and cacheable
- Header versioning keeps URLs clean
- Support minimum 2 versions simultaneously
- Document version differences in API docs
