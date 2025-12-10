---
name: react-19-patterns
description: React 19 features including Server Components, Actions, and use() hook. Use when building modern React applications.
---

# React 19 Patterns Skill

This skill covers React 19 features and patterns for building modern applications.

## When to Use

Use this skill when:
- Building React 19 applications
- Implementing Server Components
- Using Actions for form handling
- Leveraging the use() hook

## Core Principle

**SERVER FIRST** - Default to Server Components, use 'use client' only when needed for interactivity.

## Server Components (Default)

Server Components run on the server and send HTML to the client.

### Basic Server Component

```typescript
// app/users/page.tsx - Server Component (default)
import { getUsers } from '@/lib/api';

export default async function UsersPage(): Promise<React.ReactElement> {
  const users = await getUsers();

  return (
    <ul>
      {users.map((user) => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

### When to Use Server Components

- Data fetching
- Accessing backend resources
- Sensitive information (API keys, tokens)
- Large dependencies (keep on server)
- SEO-critical content

### Server Component Benefits

- Zero client-side JavaScript
- Direct database/API access
- Smaller bundle size
- Better initial load performance

## Client Components

Client Components run in the browser for interactivity.

### Basic Client Component

```typescript
'use client';

import { useState } from 'react';

interface CounterProps {
  initialValue?: number;
}

export function Counter({ initialValue = 0 }: CounterProps): React.ReactElement {
  const [count, setCount] = useState(initialValue);

  return (
    <button type="button" onClick={() => setCount((c) => c + 1)}>
      Count: {count}
    </button>
  );
}
```

### When to Use Client Components

- useState, useEffect, useReducer
- Event listeners (onClick, onChange)
- Browser APIs (localStorage, geolocation)
- Custom hooks with state
- Third-party components requiring state

## Actions (Form Handling)

Actions replace traditional form handlers with server-side processing.

### Server Action

```typescript
// app/actions.ts
'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';

export async function createUser(formData: FormData): Promise<void> {
  const name = formData.get('name') as string;
  const email = formData.get('email') as string;

  await db.user.create({ data: { name, email } });

  revalidatePath('/users');
  redirect('/users');
}
```

### Using Action in Form

```typescript
// app/users/new/page.tsx
import { createUser } from '../actions';

export default function NewUserPage(): React.ReactElement {
  return (
    <form action={createUser}>
      <input type="text" name="name" required />
      <input type="email" name="email" required />
      <button type="submit">Create User</button>
    </form>
  );
}
```

### Action with useActionState

```typescript
'use client';

import { useActionState } from 'react';
import { createUser } from '../actions';

interface FormState {
  message: string;
  success: boolean;
}

export function UserForm(): React.ReactElement {
  const [state, formAction, isPending] = useActionState<FormState, FormData>(
    createUser,
    { message: '', success: false }
  );

  return (
    <form action={formAction}>
      <input type="text" name="name" required disabled={isPending} />
      <input type="email" name="email" required disabled={isPending} />
      <button type="submit" disabled={isPending}>
        {isPending ? 'Creating...' : 'Create User'}
      </button>
      {state.message && <p>{state.message}</p>}
    </form>
  );
}
```

## use() Hook

The use() hook reads values from promises and contexts.

### Reading Promises

```typescript
'use client';

import { use } from 'react';

interface User {
  id: string;
  name: string;
}

function UserProfile({ userPromise }: { userPromise: Promise<User> }): React.ReactElement {
  const user = use(userPromise); // Suspends until resolved

  return <h1>{user.name}</h1>;
}

// Usage with Suspense
function UserPage(): React.ReactElement {
  const userPromise = fetchUser('123');

  return (
    <Suspense fallback={<div>Loading...</div>}>
      <UserProfile userPromise={userPromise} />
    </Suspense>
  );
}
```

### Reading Context Conditionally

```typescript
'use client';

import { use, createContext } from 'react';

const ThemeContext = createContext<'light' | 'dark'>('light');

function Button({ showIcon }: { showIcon: boolean }): React.ReactElement {
  // Can use conditionally (unlike useContext)
  if (showIcon) {
    const theme = use(ThemeContext);
    return <button className={theme}>With Icon</button>;
  }
  return <button>Without Icon</button>;
}
```

## Suspense Boundaries

### Data Loading with Suspense

```typescript
import { Suspense } from 'react';

export default function Dashboard(): React.ReactElement {
  return (
    <div>
      <h1>Dashboard</h1>

      <Suspense fallback={<UserSkeleton />}>
        <UserInfo />
      </Suspense>

      <Suspense fallback={<StatsSkeleton />}>
        <Stats />
      </Suspense>
    </div>
  );
}
```

### Streaming with Suspense

```typescript
// app/page.tsx
import { Suspense } from 'react';

export default function Page(): React.ReactElement {
  return (
    <main>
      {/* Renders immediately */}
      <Header />

      {/* Streams when ready */}
      <Suspense fallback={<Loading />}>
        <SlowComponent />
      </Suspense>

      {/* Renders immediately */}
      <Footer />
    </main>
  );
}
```

## Component Composition Patterns

### Server + Client Components

```typescript
// ServerWrapper.tsx (Server Component)
import { getData } from '@/lib/api';
import { InteractiveList } from './InteractiveList';

export async function ServerWrapper(): Promise<React.ReactElement> {
  const data = await getData();

  return <InteractiveList items={data} />;
}

// InteractiveList.tsx (Client Component)
'use client';

import { useState } from 'react';

interface InteractiveListProps {
  items: Item[];
}

export function InteractiveList({ items }: InteractiveListProps): React.ReactElement {
  const [selected, setSelected] = useState<string | null>(null);

  return (
    <ul>
      {items.map((item) => (
        <li
          key={item.id}
          onClick={() => setSelected(item.id)}
          className={selected === item.id ? 'selected' : ''}
        >
          {item.name}
        </li>
      ))}
    </ul>
  );
}
```

### Passing Server Components as Children

```typescript
// ClientWrapper.tsx
'use client';

import { useState } from 'react';

interface ClientWrapperProps {
  children: React.ReactNode;
}

export function ClientWrapper({ children }: ClientWrapperProps): React.ReactElement {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div>
      <button type="button" onClick={() => setIsOpen(!isOpen)}>
        Toggle
      </button>
      {isOpen && children}
    </div>
  );
}

// Page.tsx (Server Component)
import { ClientWrapper } from './ClientWrapper';
import { ServerContent } from './ServerContent';

export default function Page(): React.ReactElement {
  return (
    <ClientWrapper>
      <ServerContent /> {/* Server Component as child */}
    </ClientWrapper>
  );
}
```

## Best Practices

1. **Default to Server Components** - Only use 'use client' when needed
2. **Lift state up** - Keep interactive boundaries small
3. **Use Suspense** - Provide loading states
4. **Collocate Actions** - Keep actions near their forms
5. **Stream UI** - Use Suspense for progressive rendering

## Migration from React 18

| React 18 | React 19 |
|----------|----------|
| useEffect for data | async Server Component |
| useState + fetch | Server Action |
| Context.Consumer | use(Context) |
| Promise.then() | use(Promise) |

## Notes

- Server Components are the default in Next.js App Router
- Actions must be marked with 'use server'
- use() can only be called during render
- Suspense boundaries catch thrown promises
