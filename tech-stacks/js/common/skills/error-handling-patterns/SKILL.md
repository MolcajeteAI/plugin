---
name: error-handling-patterns
description: Type-safe error handling with discriminated unions and Result types. Use when designing error handling strategies.
---

# Error Handling Patterns Skill

This skill covers type-safe error handling patterns for TypeScript.

## When to Use

Use this skill when:
- Designing error handling strategies
- Creating APIs that can fail
- Implementing recoverable error flows
- Building robust applications

## Core Principle

**ERRORS ARE VALUES** - Treat errors as first-class values that can be typed, returned, and handled explicitly.

## Result Type Pattern

### Basic Result Type

```typescript
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

// Helper functions
function ok<T>(data: T): Result<T, never> {
  return { success: true, data };
}

function err<E>(error: E): Result<never, E> {
  return { success: false, error };
}
```

### Using Result Type

```typescript
interface User {
  id: string;
  name: string;
}

interface UserNotFoundError {
  type: 'USER_NOT_FOUND';
  userId: string;
}

interface DatabaseError {
  type: 'DATABASE_ERROR';
  message: string;
}

type GetUserError = UserNotFoundError | DatabaseError;

async function getUser(id: string): Promise<Result<User, GetUserError>> {
  try {
    const user = await db.users.findUnique({ where: { id } });
    if (!user) {
      return err({ type: 'USER_NOT_FOUND', userId: id });
    }
    return ok(user);
  } catch (e) {
    return err({ type: 'DATABASE_ERROR', message: String(e) });
  }
}

// Usage
const result = await getUser('123');
if (result.success) {
  console.log(result.data.name); // User
} else {
  switch (result.error.type) {
    case 'USER_NOT_FOUND':
      console.log(`User ${result.error.userId} not found`);
      break;
    case 'DATABASE_ERROR':
      console.log(`Database error: ${result.error.message}`);
      break;
  }
}
```

## Discriminated Union Errors

### Error Type Hierarchy

```typescript
// Base error interface
interface BaseError {
  type: string;
  message: string;
  timestamp: Date;
}

// Specific error types
interface ValidationError extends BaseError {
  type: 'VALIDATION_ERROR';
  field: string;
  value: unknown;
}

interface NotFoundError extends BaseError {
  type: 'NOT_FOUND_ERROR';
  resource: string;
  id: string;
}

interface AuthorizationError extends BaseError {
  type: 'AUTHORIZATION_ERROR';
  requiredRole: string;
  userRole: string;
}

interface NetworkError extends BaseError {
  type: 'NETWORK_ERROR';
  url: string;
  statusCode?: number;
}

// Union of all errors
type AppError =
  | ValidationError
  | NotFoundError
  | AuthorizationError
  | NetworkError;
```

### Error Factory Functions

```typescript
function createValidationError(
  field: string,
  value: unknown,
  message: string,
): ValidationError {
  return {
    type: 'VALIDATION_ERROR',
    field,
    value,
    message,
    timestamp: new Date(),
  };
}

function createNotFoundError(resource: string, id: string): NotFoundError {
  return {
    type: 'NOT_FOUND_ERROR',
    resource,
    id,
    message: `${resource} with id ${id} not found`,
    timestamp: new Date(),
  };
}
```

## Try-Catch Patterns

### Type-Safe Catch Handling

```typescript
function handleError(error: unknown): AppError {
  // Error instance
  if (error instanceof Error) {
    return {
      type: 'NETWORK_ERROR',
      url: '',
      message: error.message,
      timestamp: new Date(),
    };
  }

  // String error
  if (typeof error === 'string') {
    return {
      type: 'NETWORK_ERROR',
      url: '',
      message: error,
      timestamp: new Date(),
    };
  }

  // Unknown error
  return {
    type: 'NETWORK_ERROR',
    url: '',
    message: 'An unknown error occurred',
    timestamp: new Date(),
  };
}

async function fetchData<T>(url: string): Promise<Result<T, NetworkError>> {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      return err({
        type: 'NETWORK_ERROR',
        url,
        statusCode: response.status,
        message: `HTTP ${response.status}`,
        timestamp: new Date(),
      });
    }
    const data = (await response.json()) as T;
    return ok(data);
  } catch (error) {
    return err({
      type: 'NETWORK_ERROR',
      url,
      message: error instanceof Error ? error.message : 'Unknown error',
      timestamp: new Date(),
    });
  }
}
```

## Custom Error Classes

### Typed Error Classes

```typescript
abstract class AppErrorBase extends Error {
  abstract readonly type: string;
  readonly timestamp: Date;

  constructor(message: string) {
    super(message);
    this.name = this.constructor.name;
    this.timestamp = new Date();
    Error.captureStackTrace(this, this.constructor);
  }
}

class ValidationErrorClass extends AppErrorBase {
  readonly type = 'VALIDATION_ERROR' as const;

  constructor(
    message: string,
    public readonly field: string,
    public readonly value: unknown,
  ) {
    super(message);
  }
}

class NotFoundErrorClass extends AppErrorBase {
  readonly type = 'NOT_FOUND_ERROR' as const;

  constructor(
    public readonly resource: string,
    public readonly id: string,
  ) {
    super(`${resource} with id ${id} not found`);
  }
}
```

### Type Guard for Error Classes

```typescript
function isValidationError(error: unknown): error is ValidationErrorClass {
  return error instanceof ValidationErrorClass;
}

function isNotFoundError(error: unknown): error is NotFoundErrorClass {
  return error instanceof NotFoundErrorClass;
}

function isAppError(
  error: unknown,
): error is ValidationErrorClass | NotFoundErrorClass {
  return isValidationError(error) || isNotFoundError(error);
}
```

## Async Error Handling

### Promise-Based Result

```typescript
async function safeAsync<T>(
  fn: () => Promise<T>,
): Promise<Result<T, Error>> {
  try {
    const data = await fn();
    return ok(data);
  } catch (error) {
    return err(error instanceof Error ? error : new Error(String(error)));
  }
}

// Usage
const result = await safeAsync(() => fetchUser('123'));
if (result.success) {
  console.log(result.data);
}
```

### Multiple Async Operations

```typescript
async function getAllResults<T, E>(
  operations: Promise<Result<T, E>>[],
): Promise<Result<T[], E>> {
  const results = await Promise.all(operations);

  const errors = results.filter(
    (r): r is { success: false; error: E } => !r.success,
  );

  if (errors.length > 0) {
    return err(errors[0].error);
  }

  const data = results
    .filter((r): r is { success: true; data: T } => r.success)
    .map((r) => r.data);

  return ok(data);
}
```

## Error Logging

### Structured Error Logging

```typescript
interface ErrorLog {
  type: string;
  message: string;
  timestamp: string;
  stack?: string;
  context?: Record<string, unknown>;
}

function logError(error: AppError, context?: Record<string, unknown>): void {
  const log: ErrorLog = {
    type: error.type,
    message: error.message,
    timestamp: error.timestamp.toISOString(),
    context,
  };

  if (error instanceof Error) {
    log.stack = error.stack;
  }

  console.error(JSON.stringify(log));
}
```

## Error Recovery Patterns

### Retry with Backoff

```typescript
interface RetryOptions {
  maxAttempts: number;
  delayMs: number;
  backoffMultiplier: number;
}

async function withRetry<T, E>(
  fn: () => Promise<Result<T, E>>,
  options: RetryOptions,
): Promise<Result<T, E>> {
  let lastError: E | undefined;
  let delay = options.delayMs;

  for (let attempt = 1; attempt <= options.maxAttempts; attempt++) {
    const result = await fn();
    if (result.success) {
      return result;
    }

    lastError = result.error;

    if (attempt < options.maxAttempts) {
      await new Promise((resolve) => setTimeout(resolve, delay));
      delay *= options.backoffMultiplier;
    }
  }

  return err(lastError!);
}
```

### Fallback Values

```typescript
function withFallback<T, E>(
  result: Result<T, E>,
  fallback: T,
): T {
  return result.success ? result.data : fallback;
}

function withFallbackFn<T, E>(
  result: Result<T, E>,
  fallbackFn: (error: E) => T,
): T {
  return result.success ? result.data : fallbackFn(result.error);
}
```

## Best Practices Summary

1. **Use Result types for recoverable errors**
2. **Use discriminated unions for error types**
3. **Always handle unknown in catch clauses**
4. **Create factory functions for errors**
5. **Log errors with structured context**
6. **Use type guards for error narrowing**
7. **Throw only for unrecoverable errors**

## When to Throw vs Return Error

### Throw for:
- Programming errors (bugs)
- Unrecoverable situations
- Constraint violations that should never happen

### Return Error for:
- Expected failure cases
- User input validation
- Network/IO operations
- Business rule violations

## Code Review Checklist

- [ ] All errors have explicit types
- [ ] Catch clauses handle `unknown` type
- [ ] Result types used for recoverable errors
- [ ] Error factory functions create consistent errors
- [ ] Discriminated unions enable exhaustive handling
- [ ] Errors are logged with context
- [ ] Recovery strategies implemented where appropriate
