---
name: component-patterns
description: React component composition patterns including compound components and render props. Use when designing reusable components.
---

# React Component Patterns Skill

This skill covers component composition patterns for building reusable, flexible components.

## When to Use

Use this skill when:
- Building component libraries
- Creating flexible, reusable components
- Designing component APIs
- Implementing complex UI patterns

## Core Principle

**COMPOSITION OVER CONFIGURATION** - Build flexible components through composition rather than prop overload.

## Basic Component Pattern

### Props Interface

```typescript
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  loading?: boolean;
  onClick?: () => void;
  children: React.ReactNode;
}

export function Button({
  variant = 'primary',
  size = 'md',
  disabled = false,
  loading = false,
  onClick,
  children,
}: ButtonProps): React.ReactElement {
  return (
    <button
      type="button"
      className={cn(buttonVariants({ variant, size }))}
      disabled={disabled || loading}
      onClick={onClick}
    >
      {loading && <Spinner className="mr-2" />}
      {children}
    </button>
  );
}
```

## Compound Components

Components that work together to form a cohesive unit.

### Context-Based Compound Components

```typescript
import { createContext, useContext, useState } from 'react';

interface TabsContextValue {
  activeTab: string;
  setActiveTab: (tab: string) => void;
}

const TabsContext = createContext<TabsContextValue | null>(null);

function useTabsContext(): TabsContextValue {
  const context = useContext(TabsContext);
  if (!context) {
    throw new Error('Tabs components must be used within Tabs');
  }
  return context;
}

// Root Component
interface TabsProps {
  defaultValue: string;
  children: React.ReactNode;
}

function Tabs({ defaultValue, children }: TabsProps): React.ReactElement {
  const [activeTab, setActiveTab] = useState(defaultValue);

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      <div className="tabs">{children}</div>
    </TabsContext.Provider>
  );
}

// Tab List
function TabList({ children }: { children: React.ReactNode }): React.ReactElement {
  return <div className="tab-list" role="tablist">{children}</div>;
}

// Tab Trigger
interface TabTriggerProps {
  value: string;
  children: React.ReactNode;
}

function TabTrigger({ value, children }: TabTriggerProps): React.ReactElement {
  const { activeTab, setActiveTab } = useTabsContext();

  return (
    <button
      type="button"
      role="tab"
      aria-selected={activeTab === value}
      className={cn('tab-trigger', activeTab === value && 'active')}
      onClick={() => setActiveTab(value)}
    >
      {children}
    </button>
  );
}

// Tab Content
interface TabContentProps {
  value: string;
  children: React.ReactNode;
}

function TabContent({ value, children }: TabContentProps): React.ReactElement | null {
  const { activeTab } = useTabsContext();

  if (activeTab !== value) return null;

  return (
    <div role="tabpanel" className="tab-content">
      {children}
    </div>
  );
}

// Attach sub-components
Tabs.List = TabList;
Tabs.Trigger = TabTrigger;
Tabs.Content = TabContent;

export { Tabs };

// Usage
function App(): React.ReactElement {
  return (
    <Tabs defaultValue="tab1">
      <Tabs.List>
        <Tabs.Trigger value="tab1">Tab 1</Tabs.Trigger>
        <Tabs.Trigger value="tab2">Tab 2</Tabs.Trigger>
      </Tabs.List>
      <Tabs.Content value="tab1">Content 1</Tabs.Content>
      <Tabs.Content value="tab2">Content 2</Tabs.Content>
    </Tabs>
  );
}
```

## Render Props Pattern

Pass a function as children or prop to control rendering.

```typescript
interface MousePosition {
  x: number;
  y: number;
}

interface MouseTrackerProps {
  children: (position: MousePosition) => React.ReactElement;
}

function MouseTracker({ children }: MouseTrackerProps): React.ReactElement {
  const [position, setPosition] = useState<MousePosition>({ x: 0, y: 0 });

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent): void => {
      setPosition({ x: e.clientX, y: e.clientY });
    };

    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  return children(position);
}

// Usage
function App(): React.ReactElement {
  return (
    <MouseTracker>
      {({ x, y }) => (
        <div>
          Mouse position: {x}, {y}
        </div>
      )}
    </MouseTracker>
  );
}
```

## Slot Pattern

Allow users to replace parts of a component.

```typescript
interface CardProps {
  header?: React.ReactNode;
  footer?: React.ReactNode;
  children: React.ReactNode;
}

function Card({ header, footer, children }: CardProps): React.ReactElement {
  return (
    <div className="card">
      {header && <div className="card-header">{header}</div>}
      <div className="card-body">{children}</div>
      {footer && <div className="card-footer">{footer}</div>}
    </div>
  );
}

// Usage
function App(): React.ReactElement {
  return (
    <Card
      header={<h2>Card Title</h2>}
      footer={<Button>Action</Button>}
    >
      Card content goes here
    </Card>
  );
}
```

## Polymorphic Components

Components that can render as different elements.

```typescript
type PolymorphicProps<E extends React.ElementType> = {
  as?: E;
} & React.ComponentPropsWithoutRef<E>;

function Box<E extends React.ElementType = 'div'>({
  as,
  children,
  ...props
}: PolymorphicProps<E>): React.ReactElement {
  const Component = as ?? 'div';
  return <Component {...props}>{children}</Component>;
}

// Usage
function App(): React.ReactElement {
  return (
    <>
      <Box>Default div</Box>
      <Box as="span">As span</Box>
      <Box as="a" href="/about">As link</Box>
      <Box as="button" onClick={() => {}}>As button</Box>
    </>
  );
}
```

## Controlled vs Uncontrolled

### Uncontrolled Component

```typescript
interface UncontrolledInputProps {
  defaultValue?: string;
  onChange?: (value: string) => void;
}

function UncontrolledInput({ defaultValue, onChange }: UncontrolledInputProps): React.ReactElement {
  const [value, setValue] = useState(defaultValue ?? '');

  const handleChange = (e: ChangeEvent<HTMLInputElement>): void => {
    setValue(e.target.value);
    onChange?.(e.target.value);
  };

  return <input value={value} onChange={handleChange} />;
}
```

### Controlled Component

```typescript
interface ControlledInputProps {
  value: string;
  onChange: (value: string) => void;
}

function ControlledInput({ value, onChange }: ControlledInputProps): React.ReactElement {
  return (
    <input
      value={value}
      onChange={(e) => onChange(e.target.value)}
    />
  );
}
```

### Controlled + Uncontrolled (Flexible)

```typescript
interface FlexibleInputProps {
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
}

function FlexibleInput({
  value: controlledValue,
  defaultValue,
  onChange,
}: FlexibleInputProps): React.ReactElement {
  const [internalValue, setInternalValue] = useState(defaultValue ?? '');
  const isControlled = controlledValue !== undefined;
  const value = isControlled ? controlledValue : internalValue;

  const handleChange = (e: ChangeEvent<HTMLInputElement>): void => {
    if (!isControlled) {
      setInternalValue(e.target.value);
    }
    onChange?.(e.target.value);
  };

  return <input value={value} onChange={handleChange} />;
}
```

## forwardRef Pattern

Forward refs to inner elements.

```typescript
import { forwardRef } from 'react';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label: string;
  error?: string;
}

const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, ...props }, ref) => {
    return (
      <div className="input-wrapper">
        <label>{label}</label>
        <input ref={ref} {...props} />
        {error && <span className="error">{error}</span>}
      </div>
    );
  }
);
Input.displayName = 'Input';

export { Input };
```

## Best Practices

1. **Prefer composition** - Use children and slots over many props
2. **Use TypeScript** - Strict types for all props
3. **Provide defaults** - Sensible default values
4. **Forward refs** - For focusable/interactive elements
5. **Display name** - Set for DevTools debugging
6. **Keep components small** - Single responsibility
7. **Colocate related components** - Compound components together

## Pattern Selection Guide

| Pattern | Use When |
|---------|----------|
| Props | Simple, few variations |
| Compound | Related components working together |
| Render Props | Need to expose internal state |
| Slots | Customizable sections |
| Polymorphic | Flexible element type |
| Controlled | Parent manages state |
| Uncontrolled | Self-contained state |

## Notes

- Start simple, add patterns as needed
- Compound components are great for component libraries
- Use Radix UI primitives for accessible base components
