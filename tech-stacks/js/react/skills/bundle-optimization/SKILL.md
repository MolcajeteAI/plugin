---
name: bundle-optimization
description: Bundle size optimization including tree shaking, code splitting, and dependency analysis. Use when reducing bundle size.
---

# Bundle Optimization Skill

This skill covers techniques for optimizing JavaScript bundle size.

## When to Use

Use this skill when:
- Reducing initial load time
- Analyzing bundle contents
- Implementing code splitting
- Replacing heavy dependencies

## Core Principle

**SHIP LESS JAVASCRIPT** - Every kilobyte counts. Remove what you don't need, defer what you don't need immediately.

## Bundle Analysis

### Vite Bundle Analyzer

```bash
npm install -D rollup-plugin-visualizer
```

```typescript
// vite.config.ts
import { visualizer } from 'rollup-plugin-visualizer';

export default defineConfig({
  plugins: [
    react(),
    visualizer({
      filename: 'stats.html',
      open: true,
      gzipSize: true,
      brotliSize: true,
    }),
  ],
});
```

### Next.js Bundle Analyzer

```bash
npm install -D @next/bundle-analyzer
```

```typescript
// next.config.ts
import bundleAnalyzer from '@next/bundle-analyzer';

const withBundleAnalyzer = bundleAnalyzer({
  enabled: process.env.ANALYZE === 'true',
});

export default withBundleAnalyzer(config);
```

```bash
ANALYZE=true npm run build
```

### Source Map Explorer

```bash
npx source-map-explorer dist/**/*.js
```

## Code Splitting

### Route-Based Splitting

```typescript
import { lazy, Suspense } from 'react';

const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));

function App(): React.ReactElement {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

### Component-Level Splitting

```typescript
const HeavyChart = lazy(() => import('./components/HeavyChart'));

function Dashboard(): React.ReactElement {
  const [showChart, setShowChart] = useState(false);

  return (
    <div>
      <button onClick={() => setShowChart(true)}>Show Chart</button>
      {showChart && (
        <Suspense fallback={<ChartSkeleton />}>
          <HeavyChart />
        </Suspense>
      )}
    </div>
  );
}
```

### Manual Chunks (Vite)

```typescript
// vite.config.ts
build: {
  rollupOptions: {
    output: {
      manualChunks: {
        'vendor-react': ['react', 'react-dom', 'react-router-dom'],
        'vendor-ui': ['@radix-ui/react-dialog', '@radix-ui/react-dropdown-menu'],
        'vendor-charts': ['recharts'],
      },
    },
  },
},
```

## Tree Shaking

### Import Specific Functions

```typescript
// ❌ Imports entire library
import _ from 'lodash';
_.debounce(fn, 300);

// ✅ Imports only what's needed
import debounce from 'lodash/debounce';
debounce(fn, 300);

// ✅ Or use lodash-es for better tree shaking
import { debounce } from 'lodash-es';
```

### Icon Libraries

```typescript
// ❌ Imports all icons
import * as Icons from 'lucide-react';

// ✅ Imports specific icons
import { Home, Settings, User } from 'lucide-react';
```

### Date Libraries

```typescript
// ❌ moment.js (330KB)
import moment from 'moment';

// ✅ date-fns (tree-shakeable)
import { format, parseISO } from 'date-fns';

// ✅ dayjs (2KB)
import dayjs from 'dayjs';
```

## Heavy Dependency Alternatives

| Heavy Library | Size | Alternative | Size |
|--------------|------|-------------|------|
| moment.js | 330KB | date-fns | ~20KB |
| lodash | 530KB | lodash-es (specific) | ~5KB |
| axios | 40KB | fetch (native) | 0KB |
| uuid | 18KB | crypto.randomUUID() | 0KB |
| classnames | 1.8KB | clsx | 0.3KB |

## Dynamic Imports

### Conditional Loading

```typescript
async function loadPolyfill(): Promise<void> {
  if (!('IntersectionObserver' in window)) {
    await import('intersection-observer');
  }
}

async function loadAnalytics(): Promise<void> {
  if (process.env.NODE_ENV === 'production') {
    const { initAnalytics } = await import('./analytics');
    initAnalytics();
  }
}
```

### Feature-Based Loading

```typescript
const PDFViewer = lazy(() => import('./PDFViewer'));
const VideoPlayer = lazy(() => import('./VideoPlayer'));

function MediaViewer({ type, src }: MediaViewerProps): React.ReactElement {
  if (type === 'pdf') {
    return (
      <Suspense fallback={<Loading />}>
        <PDFViewer src={src} />
      </Suspense>
    );
  }

  if (type === 'video') {
    return (
      <Suspense fallback={<Loading />}>
        <VideoPlayer src={src} />
      </Suspense>
    );
  }

  return <img src={src} alt="" />;
}
```

## Prefetching

### Link Prefetching

```typescript
// React Router
import { Link } from 'react-router-dom';

function Nav(): React.ReactElement {
  const prefetchDashboard = (): void => {
    import('./pages/Dashboard');
  };

  return (
    <Link to="/dashboard" onMouseEnter={prefetchDashboard}>
      Dashboard
    </Link>
  );
}
```

### Next.js Prefetching

```typescript
import Link from 'next/link';

// Automatic prefetching (default)
<Link href="/dashboard">Dashboard</Link>

// Disable prefetching
<Link href="/dashboard" prefetch={false}>Dashboard</Link>
```

## CSS Optimization

### Tailwind CSS Purging

```typescript
// tailwind.config.ts
export default {
  content: ['./src/**/*.{js,ts,jsx,tsx}'],
  // Tailwind automatically purges unused styles in production
};
```

### CSS-in-JS Extraction

Use build-time extraction for CSS-in-JS:

```typescript
// Use vanilla-extract for zero-runtime CSS
import { style } from '@vanilla-extract/css';

export const button = style({
  backgroundColor: 'blue',
  color: 'white',
});
```

## Image Optimization

```typescript
// Use next/image for automatic optimization
import Image from 'next/image';

<Image
  src="/hero.jpg"
  alt="Hero"
  width={1200}
  height={600}
  priority // For LCP images
  placeholder="blur"
  blurDataURL="..."
/>

// Or use vite-imagetools
import heroImage from './hero.jpg?w=1200&format=webp';
```

## Monitoring Bundle Size

### Size Limits

```bash
npm install -D size-limit @size-limit/preset-app
```

```json
// package.json
{
  "size-limit": [
    {
      "path": "dist/**/*.js",
      "limit": "200 KB"
    }
  ],
  "scripts": {
    "size": "size-limit",
    "size-check": "size-limit --ci"
  }
}
```

### CI Integration

```yaml
# .github/workflows/size.yml
- name: Check bundle size
  run: npm run size-check
```

## Bundle Size Targets

| Metric | Target | Good | Critical |
|--------|--------|------|----------|
| Initial JS | < 100KB | < 150KB | > 200KB |
| Per-route JS | < 50KB | < 100KB | > 150KB |
| Total JS | < 500KB | < 750KB | > 1MB |

## Optimization Checklist

- [ ] Analyze bundle with visualizer
- [ ] Implement route-based code splitting
- [ ] Import specific functions (tree shaking)
- [ ] Replace heavy dependencies
- [ ] Lazy load heavy components
- [ ] Optimize images
- [ ] Set up size limits in CI
- [ ] Monitor bundle size over time

## Notes

- Always analyze before optimizing
- Focus on initial load first
- Use lazy loading for below-the-fold content
- Consider server components (Next.js) to reduce client JS
