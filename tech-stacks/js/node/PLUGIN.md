# Node.js Backend Tech-Stack

Node.js backend development with Fastify, Prisma, and modern backend patterns.

## Overview

This tech-stack extends the `js/common` foundation with backend-specific tooling for building production-ready Node.js APIs and services.

## Core Philosophy

1. **Type Safety First** - Strict TypeScript, no `any` types
2. **Zero Warnings** - All warnings treated as errors
3. **Modern Patterns** - ESM-first, async/await, structured concurrency
4. **Well-Known Libraries** - Fastify, Prisma, Zod, Pino
5. **Quality Gates** - Automated checks before deployment

## Inheritance

This stack inherits from `js/common`, which provides:
- TypeScript strict configuration
- Linting and formatting (Biome or ESLint + Prettier)
- Testing with Vitest
- Security auditing
- Quality enforcement

## Frameworks Supported

- **Fastify 5.x** - Fast, schema-based HTTP framework (recommended)
- **Express 5.x** - Minimalist web framework
- **Hono** - Ultrafast web framework for the edge
- **Prisma** - Type-safe ORM
- **Drizzle ORM** - Lightweight SQL-first ORM
- **tRPC** - End-to-end type-safe APIs
- **GraphQL** - Query language for APIs

## Commands

### Inherited from js/common
- `/node:init` - Initialize TypeScript project
- `/node:install` - Install and audit dependencies
- `/node:dev` - Run development environment
- `/node:build` - Build project
- `/node:type-check` - Run TypeScript compiler checks
- `/node:lint` - Run linter
- `/node:format` - Format code
- `/node:test` - Run test suite
- `/node:test-watch` - Run tests in watch mode
- `/node:test-coverage` - Generate coverage report
- `/node:audit` - Security audit
- `/node:validate` - Run all quality checks

### Backend Development
- `/node:api-init` - Initialize REST/GraphQL API project
- `/node:db-generate` - Generate Prisma client
- `/node:db-migrate` - Run database migrations
- `/node:db-seed` - Seed database with test data
- `/node:api-validate` - Validate API schemas (Zod)

### Testing
- `/node:test-integration` - Run integration tests
- `/node:test-e2e` - Run end-to-end tests
- `/node:test-containers` - Run tests with Docker containers

### Deployment
- `/node:docker-build` - Build Docker image
- `/node:docker-run` - Run Docker container
- `/node:deploy` - Deploy to platform (Vercel, Railway, Fly.io)

## Agents

### Inherited from js/common
- `node:developer` - TypeScript development with strict type safety
- `node:tester` - Testing and coverage with Vitest
- `node:security` - Security auditing (READ-ONLY)
- `node:quality-guardian` - Code quality enforcement
- `node:documenter` - Documentation generation

### Backend-Specific
- `node:api-builder` - REST/GraphQL/tRPC API development
- `node:database-architect` - Database schema design and management
- `node:deployer` - Docker and platform deployment

## Skills

### Inherited from js/common
- TypeScript strict configuration
- ESM module patterns
- Type safety patterns
- Error handling patterns
- Vitest configuration
- Biome/ESLint setup
- Security scanning
- Pre-commit hooks

### Backend Development
- `fastify-patterns` - Fastify routing, plugins, decorators
- `api-versioning` - API versioning strategies
- `authentication-strategies` - JWT, session, OAuth patterns
- `authorization-patterns` - RBAC, ABAC implementation

### Database
- `prisma-setup` - Prisma ORM configuration and patterns
- `drizzle-setup` - Drizzle ORM alternative
- `migration-strategies` - Database migration best practices
- `query-optimization` - Query performance tuning

### Validation & Serialization
- `zod-validation` - Schema validation with Zod
- `serialization-patterns` - JSON serialization, data transformation

### Testing
- `integration-testing` - Supertest, API testing patterns
- `testcontainers-usage` - Docker-based integration tests
- `e2e-testing-backend` - End-to-end backend testing

### Deployment
- `docker-backend-patterns` - Multi-stage Docker builds for Node.js
- `serverless-patterns` - Serverless deployment (Vercel, AWS Lambda)

## Requirements

### Core
- Node.js >= 22 LTS
- npm >= 10 or pnpm >= 9

### Recommended
- Fastify >= 5.0 OR Express >= 5.0
- Prisma >= 6.0 OR Drizzle ORM >= 0.33
- Zod >= 3.23
- Pino >= 9.0

### Optional
- Docker >= 24.0
- testcontainers - Integration testing
- Supertest - HTTP testing

## Deployment Targets

- Docker
- Vercel
- Railway
- Fly.io
- Render
- AWS Lambda
- Cloudflare Workers
- Google Cloud Run
- Azure Container Apps
- DigitalOcean App Platform

## Quick Start

```bash
# Initialize a new Fastify API project
/node:api-init

# Set up database with Prisma
/node:db-generate
/node:db-migrate

# Run development server
/node:dev

# Run tests
/node:test
/node:test-integration

# Build and deploy
/node:docker-build
/node:deploy
```

## Quality Gates

Every project must pass:
- TypeScript type-check (zero errors)
- Linter (zero warnings)
- Formatter (all files formatted)
- Tests (100% passing)
- Security audit (no high/critical vulnerabilities)
- NO `any` types (explicit or implicit)
