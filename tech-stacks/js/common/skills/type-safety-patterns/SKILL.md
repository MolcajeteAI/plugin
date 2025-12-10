---
name: type-safety-patterns
description: Advanced TypeScript type patterns including generics, type guards, and branded types. Use when designing type-safe APIs.
---

# Type Safety Patterns Skill

This skill covers advanced TypeScript patterns for maximum type safety.

## When to Use

Use this skill when:
- Designing type-safe APIs
- Working with unknown data
- Creating reusable generic utilities
- Implementing runtime type checking

## Core Principle

**TYPES ARE DOCUMENTATION** - Well-designed types make code self-documenting and catch errors at compile time.

## Type Guards

### typeof Guards

```typescript
function processValue(value: string | number): string {
  if (typeof value === 'string') {
    return value.toUpperCase(); // value is string
  }
  return value.toFixed(2); // value is number
}
```

### instanceof Guards

```typescript
class ApiError extends Error {
  constructor(
    message: string,
    public statusCode: number,
  ) {
    super(message);
  }
}

function handleError(error: unknown): string {
  if (error instanceof ApiError) {
    return `API Error ${error.statusCode}: ${error.message}`;
  }
  if (error instanceof Error) {
    return `Error: ${error.message}`;
  }
  return 'Unknown error';
}
```

### User-Defined Type Guards

```typescript
interface User {
  id: string;
  name: string;
  email: string;
}

function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'name' in value &&
    'email' in value &&
    typeof (value as Record<string, unknown>).id === 'string' &&
    typeof (value as Record<string, unknown>).name === 'string' &&
    typeof (value as Record<string, unknown>).email === 'string'
  );
}

function processUser(data: unknown): User {
  if (!isUser(data)) {
    throw new Error('Invalid user data');
  }
  return data; // data is User
}
```

### Assertion Functions

```typescript
function assertIsString(value: unknown): asserts value is string {
  if (typeof value !== 'string') {
    throw new Error(`Expected string, got ${typeof value}`);
  }
}

function processInput(input: unknown): string {
  assertIsString(input);
  return input.toUpperCase(); // input is string
}
```

## Generic Types

### Basic Generics

```typescript
function identity<T>(value: T): T {
  return value;
}

const str = identity('hello'); // string
const num = identity(42); // number
```

### Generic Constraints

```typescript
interface HasId {
  id: string;
}

function findById<T extends HasId>(items: T[], id: string): T | undefined {
  return items.find((item) => item.id === id);
}

interface User extends HasId {
  name: string;
}

const users: User[] = [{ id: '1', name: 'Alice' }];
const user = findById(users, '1'); // User | undefined
```

### Multiple Type Parameters

```typescript
function map<T, U>(items: T[], fn: (item: T) => U): U[] {
  return items.map(fn);
}

const numbers = [1, 2, 3];
const strings = map(numbers, (n) => n.toString()); // string[]
```

### Default Type Parameters

```typescript
interface ApiResponse<T = unknown> {
  data: T;
  status: number;
  message: string;
}

const response: ApiResponse<User> = {
  data: { id: '1', name: 'Alice', email: 'alice@example.com' },
  status: 200,
  message: 'OK',
};
```

## Branded Types

Prevent mixing incompatible values of the same underlying type:

```typescript
// Brand type utility
type Brand<T, B> = T & { __brand: B };

// Branded IDs
type UserId = Brand<string, 'UserId'>;
type OrderId = Brand<string, 'OrderId'>;

// Constructor functions
function createUserId(id: string): UserId {
  return id as UserId;
}

function createOrderId(id: string): OrderId {
  return id as OrderId;
}

// Type-safe functions
function getUser(id: UserId): User {
  // ...
}

function getOrder(id: OrderId): Order {
  // ...
}

// Usage
const userId = createUserId('user-123');
const orderId = createOrderId('order-456');

getUser(userId); // ✅ OK
getUser(orderId); // ❌ Type error!
```

## Discriminated Unions

```typescript
// Define discriminated union
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

// Usage
function divide(a: number, b: number): Result<number, string> {
  if (b === 0) {
    return { success: false, error: 'Division by zero' };
  }
  return { success: true, data: a / b };
}

// Pattern matching
const result = divide(10, 2);
if (result.success) {
  console.log(result.data); // number
} else {
  console.log(result.error); // string
}
```

## Utility Types

### Built-in Utility Types

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  createdAt: Date;
}

// Partial - all properties optional
type PartialUser = Partial<User>;

// Required - all properties required
type RequiredUser = Required<PartialUser>;

// Pick - select properties
type UserBasic = Pick<User, 'id' | 'name'>;

// Omit - exclude properties
type UserWithoutDates = Omit<User, 'createdAt'>;

// Readonly - all properties readonly
type ReadonlyUser = Readonly<User>;

// Record - object with specific key/value types
type UserMap = Record<string, User>;
```

### Custom Utility Types

```typescript
// Make specific properties optional
type PartialBy<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;

type UserCreate = PartialBy<User, 'id' | 'createdAt'>;

// Make specific properties required
type RequiredBy<T, K extends keyof T> = Omit<T, K> & Required<Pick<T, K>>;

// Deep readonly
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object ? DeepReadonly<T[P]> : T[P];
};

// Non-nullable properties
type NonNullableProps<T> = {
  [P in keyof T]: NonNullable<T[P]>;
};
```

## Template Literal Types

```typescript
type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';
type ApiPath = '/users' | '/orders' | '/products';

type ApiEndpoint = `${HttpMethod} ${ApiPath}`;
// "GET /users" | "GET /orders" | "GET /products" | "POST /users" | ...

// Event handlers
type EventName = 'click' | 'focus' | 'blur';
type EventHandler = `on${Capitalize<EventName>}`;
// "onClick" | "onFocus" | "onBlur"
```

## Conditional Types

```typescript
// Extract array element type
type ArrayElement<T> = T extends (infer E)[] ? E : never;

type Numbers = ArrayElement<number[]>; // number
type Strings = ArrayElement<string[]>; // string

// Extract promise value type
type Awaited<T> = T extends Promise<infer U> ? U : T;

type ResolvedValue = Awaited<Promise<string>>; // string

// Extract function return type
type ReturnOf<T> = T extends (...args: unknown[]) => infer R ? R : never;
```

## Mapped Types

```typescript
// Make all properties nullable
type Nullable<T> = {
  [P in keyof T]: T[P] | null;
};

// Getters for all properties
type Getters<T> = {
  [P in keyof T as `get${Capitalize<string & P>}`]: () => T[P];
};

interface Person {
  name: string;
  age: number;
}

type PersonGetters = Getters<Person>;
// { getName: () => string; getAge: () => number; }
```

## Index Signatures with Constraints

```typescript
// String index with specific value type
interface StringMap {
  [key: string]: string;
}

// Template literal key constraints
interface EventHandlers {
  [K: `on${string}`]: (event: Event) => void;
}

// Record with computed keys
type StatusCodes = Record<200 | 400 | 404 | 500, string>;
```

## Best Practices Summary

1. **Use type guards for runtime type checking**
2. **Prefer user-defined type guards for complex types**
3. **Use branded types for domain IDs**
4. **Use discriminated unions for state machines**
5. **Leverage utility types instead of manual typing**
6. **Use generics for reusable, type-safe code**
7. **Prefer `unknown` over `any` for unknown values**

## Code Review Checklist

- [ ] No `any` types - use `unknown` with type guards
- [ ] Generic constraints are properly defined
- [ ] Type guards return `value is Type`
- [ ] Discriminated unions have literal discriminant
- [ ] Branded types used for domain identifiers
- [ ] Utility types used where applicable
- [ ] Conditional types are well-documented
