# Database Fixtures

Patterns for managing database state in BDD tests. The strategy is configured in `bdd/CLAUDE.md` under `## Extended Configuration`.

## Strategy Comparison

| Strategy | Speed | Isolation | Setup Cost | Best For |
|----------|-------|-----------|------------|----------|
| transaction-rollback | Fast | Per-scenario | Low (DB connection) | Most projects; wraps each scenario in a transaction that rolls back |
| testcontainers | Medium | Per-suite | High (container spin-up) | CI pipelines; spins up a fresh DB container per test suite |
| truncation | Fast | Per-scenario | Low | Simple schemas; truncates all tables between scenarios |

## Transaction Rollback

Wraps each scenario in a database transaction that rolls back after the scenario completes. Fastest option but requires all test code to share the same DB connection.

### Python (behave)

In `bdd/steps/environment.py`:

```python
def before_scenario(context, scenario):
    context.db_conn = get_db_connection()
    context.db_conn.autocommit = False

def after_scenario(context, scenario):
    context.db_conn.rollback()
    context.db_conn.close()
```

In `bdd/steps/world.py`, expose the connection:

```python
def get_db(context):
    return context.db_conn
```

### TypeScript (cucumber-js)

In `bdd/steps/world.ts`:

```typescript
import { World, Before, After } from "@cucumber/cucumber";
import { Pool, PoolClient } from "pg";

const pool = new Pool();

Before(async function (this: World) {
  this.dbClient = await pool.connect();
  await this.dbClient.query("BEGIN");
});

After(async function (this: World) {
  await this.dbClient.query("ROLLBACK");
  this.dbClient.release();
});
```

### Go (godog)

In `bdd/steps/world.go`:

```go
func InitializeScenario(ctx *godog.ScenarioContext) {
    var tx *sql.Tx

    ctx.Before(func(ctx context.Context, sc *godog.Scenario) (context.Context, error) {
        db := getDB()
        var err error
        tx, err = db.Begin()
        if err != nil {
            return ctx, err
        }
        return context.WithValue(ctx, txKey, tx), nil
    })

    ctx.After(func(ctx context.Context, sc *godog.Scenario, err error) (context.Context, error) {
        if tx != nil {
            tx.Rollback()
        }
        return ctx, nil
    })
}
```

## Testcontainers

Spins up a fresh database container per test suite. Best for CI where isolation matters more than speed.

### Python

```python
# conftest.py or environment.py
from testcontainers.postgres import PostgresContainer

def before_all(context):
    context.pg = PostgresContainer("postgres:16")
    context.pg.start()
    context.db_url = context.pg.get_connection_url()

def after_all(context):
    context.pg.stop()
```

### TypeScript

```typescript
import { PostgreSqlContainer } from "@testcontainers/postgresql";

let container: StartedPostgreSqlContainer;

BeforeAll(async () => {
  container = await new PostgreSqlContainer("postgres:16").start();
  process.env.DATABASE_URL = container.getConnectionUri();
});

AfterAll(async () => {
  await container.stop();
});
```

### Go

```go
import "github.com/testcontainers/testcontainers-go/modules/postgres"

func TestFeatures(t *testing.T) {
    ctx := context.Background()
    pg, err := postgres.Run(ctx, "postgres:16")
    if err != nil {
        t.Fatal(err)
    }
    defer pg.Terminate(ctx)

    connStr, _ := pg.ConnectionString(ctx)
    // pass connStr to godog suite
}
```

## Truncation

Truncates all tables between scenarios. Simpler than transaction rollback but slower on large schemas.

### Truncation Helper (all languages)

Execute `TRUNCATE TABLE {table1}, {table2}, ... CASCADE` between scenarios. Maintain a list of tables to truncate (exclude migration tables).

```python
# Python example
TABLES = ["users", "orders", "products"]

def after_scenario(context, scenario):
    cursor = context.db_conn.cursor()
    cursor.execute(f"TRUNCATE TABLE {', '.join(TABLES)} CASCADE")
    context.db_conn.commit()
```

## Integration with bdd/CLAUDE.md

The `Database state strategy` field in `bdd/CLAUDE.md` determines which pattern the Developer agent uses when implementing step definition bodies that interact with the database:

| Config Value | Pattern | World Integration |
|-------------|---------|-------------------|
| `transaction-rollback` | Before/After hooks with BEGIN/ROLLBACK | `world.[ext]` exposes `get_db()` returning the transaction connection |
| `testcontainers` | BeforeAll/AfterAll container lifecycle | `world.[ext]` exposes `get_db()` returning the container connection |
| `truncation` | After hooks with TRUNCATE CASCADE | `world.[ext]` exposes `get_db()` returning a standard connection |
| `none` | No DB hooks | No DB integration in world module |
