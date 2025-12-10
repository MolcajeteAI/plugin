---
name: performance-patterns
description: React performance optimization including memoization, code splitting, and lazy loading. Use when optimizing React applications.
---

# React Performance Patterns Skill

This skill covers performance optimization techniques for React applications.

## When to Use

Use this skill when:
- Optimizing render performance
- Reducing bundle size
- Implementing lazy loading
- Fixing performance bottlenecks

## Core Principle

**MEASURE FIRST** - Profile before optimizing. Premature optimization leads to complexity without benefit.

## Memoization

### React.memo

Prevent re-renders when props haven't changed.

```typescript
import { memo } from 'react';

interface ListItemProps {
  item: Item;
  onSelect: (id: string) => void;
}

// ✅ Memoize when:
// - Component renders often with same props
// - Component is expensive to render
// - Parent re-renders frequently
const ListItem = memo(function ListItem({
  item,
  onSelect,
}: ListItemProps): React.ReactElement {
  return (
    <li onClick={() => onSelect(item.id)}>
      {item.name}
    </li>
  );
});

// With custom comparison
const ListItem = memo(
  function ListItem({ item }: ListItemProps): React.ReactElement {
    return <li>{item.name}</li>;
  },
  (prevProps, nextProps) => {
    return prevProps.item.id === nextProps.item.id;
  }
);
```

### useMemo

Cache expensive computations.

```typescript
import { useMemo } from 'react';

function UserList({ users, filter }: UserListProps): React.ReactElement {
  // ✅ Use for expensive computations
  const filteredUsers = useMemo(() => {
    return users
      .filter((user) => user.name.includes(filter))
      .sort((a, b) => a.name.localeCompare(b.name));
  }, [users, filter]);

  // ❌ Don't use for simple operations
  // const fullName = useMemo(() => `${first} ${last}`, [first, last]);
  // Just use: const fullName = `${first} ${last}`;

  return (
    <ul>
      {filteredUsers.map((user) => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

### useCallback

Keep function references stable.

```typescript
import { useCallback, memo } from 'react';

function Parent(): React.ReactElement {
  const [count, setCount] = useState(0);

  // ✅ Stable callback for memoized children
  const handleClick = useCallback((id: string) => {
    console.log(`Clicked: ${id}`);
  }, []);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount((c) => c + 1)}>Increment</button>
      <MemoizedList onItemClick={handleClick} />
    </div>
  );
}

const MemoizedList = memo(function MemoizedList({
  onItemClick,
}: {
  onItemClick: (id: string) => void;
}): React.ReactElement {
  console.log('List rendered'); // Only logs once!
  return <ul>...</ul>;
});
```

## Code Splitting

### React.lazy

```typescript
import { lazy, Suspense } from 'react';

// Lazy load route components
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));
const Profile = lazy(() => import('./pages/Profile'));

function App(): React.ReactElement {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/profile" element={<Profile />} />
      </Routes>
    </Suspense>
  );
}
```

### Named Exports with lazy

```typescript
// For named exports, create intermediate module
// Dashboard.lazy.ts
export { Dashboard as default } from './Dashboard';

// App.tsx
const Dashboard = lazy(() => import('./Dashboard.lazy'));
```

### Prefetching

```typescript
function NavLink({ to, children }: NavLinkProps): React.ReactElement {
  const prefetch = (): void => {
    if (to === '/dashboard') {
      import('./pages/Dashboard');
    } else if (to === '/settings') {
      import('./pages/Settings');
    }
  };

  return (
    <Link to={to} onMouseEnter={prefetch} onFocus={prefetch}>
      {children}
    </Link>
  );
}
```

## Virtualization

For long lists, render only visible items.

```typescript
import { useVirtualizer } from '@tanstack/react-virtual';
import { useRef } from 'react';

function VirtualList({ items }: { items: Item[] }): React.ReactElement {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50,
    overscan: 5,
  });

  return (
    <div ref={parentRef} className="h-[500px] overflow-auto">
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          width: '100%',
          position: 'relative',
        }}
      >
        {virtualizer.getVirtualItems().map((virtualItem) => (
          <div
            key={virtualItem.key}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: `${virtualItem.size}px`,
              transform: `translateY(${virtualItem.start}px)`,
            }}
          >
            {items[virtualItem.index]?.name}
          </div>
        ))}
      </div>
    </div>
  );
}
```

## State Management Optimization

### Split State

```typescript
// ❌ Single state object causes full re-render
const [state, setState] = useState({
  user: null,
  theme: 'light',
  notifications: [],
});

// ✅ Split state - components only re-render for their state
const [user, setUser] = useState<User | null>(null);
const [theme, setTheme] = useState<'light' | 'dark'>('light');
const [notifications, setNotifications] = useState<Notification[]>([]);
```

### Zustand Selectors

```typescript
import { create } from 'zustand';

interface Store {
  user: User | null;
  theme: 'light' | 'dark';
  setUser: (user: User) => void;
  setTheme: (theme: 'light' | 'dark') => void;
}

const useStore = create<Store>((set) => ({
  user: null,
  theme: 'light',
  setUser: (user) => set({ user }),
  setTheme: (theme) => set({ theme }),
}));

// ✅ Subscribe only to what you need
function UserName(): React.ReactElement {
  const userName = useStore((state) => state.user?.name);
  return <span>{userName}</span>;
}

function ThemeToggle(): React.ReactElement {
  const theme = useStore((state) => state.theme);
  const setTheme = useStore((state) => state.setTheme);
  return <button onClick={() => setTheme(theme === 'light' ? 'dark' : 'light')}>Toggle</button>;
}
```

## Image Optimization

### Lazy Loading Images

```typescript
function LazyImage({ src, alt }: { src: string; alt: string }): React.ReactElement {
  return (
    <img
      src={src}
      alt={alt}
      loading="lazy"
      decoding="async"
    />
  );
}
```

### Next.js Image

```typescript
import Image from 'next/image';

function OptimizedImage(): React.ReactElement {
  return (
    <Image
      src="/hero.jpg"
      alt="Hero"
      width={1200}
      height={600}
      priority // For LCP images
      placeholder="blur"
      blurDataURL="data:image/jpeg;base64,..."
    />
  );
}
```

## Avoiding Common Pitfalls

### Object/Array in Dependencies

```typescript
// ❌ New object each render
function Component({ filters }: { filters: { page: number; limit: number } }): React.ReactElement {
  useEffect(() => {
    fetchData(filters);
  }, [filters]); // Infinite loop!
}

// ✅ Extract primitive values
function Component({ filters }: { filters: { page: number; limit: number } }): React.ReactElement {
  const { page, limit } = filters;
  useEffect(() => {
    fetchData({ page, limit });
  }, [page, limit]);
}
```

### Inline Object Props

```typescript
// ❌ New object each render
<Child style={{ color: 'red' }} />

// ✅ Stable reference
const style = useMemo(() => ({ color: 'red' }), []);
<Child style={style} />

// Or define outside component
const redStyle = { color: 'red' };
<Child style={redStyle} />
```

## Profiling Tools

### React DevTools Profiler

1. Install React DevTools browser extension
2. Open DevTools > Profiler tab
3. Click Record, interact with app, stop
4. Analyze flame graph for slow renders

### Why Did You Render

```typescript
// In development only
import whyDidYouRender from '@welldone-software/why-did-you-render';

if (process.env.NODE_ENV === 'development') {
  whyDidYouRender(React, {
    trackAllPureComponents: true,
  });
}
```

## Performance Checklist

- [ ] Profile before optimizing
- [ ] Use React.memo for expensive components
- [ ] Implement code splitting for routes
- [ ] Virtualize long lists (100+ items)
- [ ] Use stable references (useCallback, useMemo)
- [ ] Optimize images (lazy loading, proper sizing)
- [ ] Use Zustand selectors or split state
- [ ] Avoid inline objects/arrays as props

## Notes

- Don't optimize prematurely
- memo() is free for simple components
- useCallback/useMemo have overhead - use wisely
- Virtualization significantly helps long lists
