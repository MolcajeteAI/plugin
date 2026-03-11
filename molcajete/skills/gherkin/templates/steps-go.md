# Go Step Definition Template

Use this template when creating new step definition files for Go (godog). Each template includes doc comments with parameter descriptions and real assertion bodies.

Step definitions are part of the executable specification. They must contain real assertions that fail (red) when no production code exists and pass (green) after the Developer implements the feature.

When creating a new step file, use the full template (package + imports + step struct + functions). When appending to an existing step file, add only the new step functions and register them in `InitializeScenario`.

```go
package steps

import (
	"context"
	"fmt"

	"github.com/cucumber/godog"
)

// {Domain}Steps registers step definitions for {domain} scenarios.
type {Domain}Steps struct {
	world *TestWorld
}

// New{Domain}Steps creates a new {domain} steps instance.
func New{Domain}Steps(world *TestWorld) *{Domain}Steps {
	return &{Domain}Steps{world: world}
}

// stepGivenUserLoggedIn sets up an authenticated user session.
//
// Parameters:
//   - name (string): Username to authenticate as
func (s *{Domain}Steps) stepGivenUserLoggedIn(ctx context.Context, name string) error {
	user, err := s.world.App.GetUser(name)
	if err != nil {
		return fmt.Errorf("get user %s: %w", name, err)
	}
	s.world.User = user
	s.world.Session, err = s.world.App.Login(user)
	if err != nil {
		return fmt.Errorf("login as %s: %w", name, err)
	}
	return nil
}

// stepWhenCreateEntity performs entity creation via the application.
//
// Parameters:
//   - entity (string): Type of entity to create
//   - name (string): Name for the new entity
func (s *{Domain}Steps) stepWhenCreateEntity(ctx context.Context, entity, name string) error {
	resp, err := s.world.App.Create(entity, map[string]string{"name": name}, s.world.Session)
	if err != nil {
		return fmt.Errorf("create %s: %w", entity, err)
	}
	s.world.Response = resp
	return nil
}

// stepThenRecordShouldHave asserts the entity record matches expected field values.
//
// Parameters:
//   - entity (string): Type of entity to verify
//   - table (*godog.Table): Expected field/value pairs
func (s *{Domain}Steps) stepThenRecordShouldHave(ctx context.Context, entity string, table *godog.Table) error {
	record, err := s.world.App.GetLatest(entity)
	if err != nil {
		return fmt.Errorf("get latest %s: %w", entity, err)
	}
	for _, row := range table.Rows[1:] {
		field, expected := row.Cells[0].Value, row.Cells[1].Value
		actual := record.Field(field)
		if actual != expected {
			return fmt.Errorf("%s.%s: expected %s, got %s", entity, field, expected, actual)
		}
	}
	return nil
}

// InitializeScenario registers all {domain} steps.
func (s *{Domain}Steps) InitializeScenario(ctx *godog.ScenarioContext) {
	ctx.Step(`^user "([^"]*)" is logged in$`, s.stepGivenUserLoggedIn)
	ctx.Step(`^the user creates a "([^"]*)" with name "([^"]*)"$`, s.stepWhenCreateEntity)
	ctx.Step(`^the "([^"]*)" record should have:$`, s.stepThenRecordShouldHave)
}
```
