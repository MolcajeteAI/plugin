# TypeScript Step Definition Template

Use this template when creating new step definition files for TypeScript (cucumber-js). Each template includes JSDoc comments with parameter descriptions and real assertion bodies.

Step definitions are part of the executable specification. They must contain real assertions that fail (red) when no production code exists and pass (green) after the Developer implements the feature.

When creating a new step file, use the full template (imports + step functions). When appending to an existing step file, add only the new step functions.

```typescript
/**
 * {Domain} step definitions.
 *
 * Steps for {domain description} scenarios.
 */

import { Given, When, Then } from "@cucumber/cucumber";
import { strict as assert } from "node:assert";
import type { World } from "./world";

/**
 * Set up an authenticated user session.
 *
 * @param name - Username to authenticate as
 */
Given("user {string} is logged in", async function (this: World, name: string) {
  this.user = await this.app.getUser(name);
  this.session = await this.app.login(this.user);
  assert.ok(this.session, `Failed to create session for ${name}`);
});

/**
 * Perform entity creation via the application.
 *
 * @param entity - Type of entity to create
 * @param name - Name for the new entity
 */
When("the user creates a {string} with name {string}", async function (this: World, entity: string, name: string) {
  this.response = await this.app.create(entity, { name }, this.session);
});

/**
 * Assert the entity record matches expected field values.
 *
 * @param entity - Type of entity to verify
 */
Then("the {string} record should have:", async function (this: World, entity: string) {
  const record = await this.app.getLatest(entity);
  assert.ok(record, `No ${entity} record found`);
  for (const row of this.table!.hashes()) {
    const actual = record[row.field];
    assert.strictEqual(
      String(actual),
      row.value,
      `${entity}.${row.field}: expected ${row.value}, got ${actual}`
    );
  }
});
```
