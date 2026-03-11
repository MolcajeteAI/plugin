# Python Step Definition Template

Use this template when creating new step definition files for Python (behave). Each template includes docstrings with parameter descriptions and real assertion bodies.

Step definitions are part of the executable specification. They must contain real assertions that fail (red) when no production code exists and pass (green) after the Developer implements the feature.

When creating a new step file, use the full template (module docstring + imports + step functions). When appending to an existing step file, add only the new step functions.

```python
"""
{Domain} step definitions.

Steps for {domain description} scenarios.
"""

from behave import given, when, then


@given("user {name} is logged in")
def step_given_user_logged_in(context, name):
    """
    Set up an authenticated user session.

    Args:
        name (str): Username to authenticate as
    """
    context.user = context.app.get_user(name)
    context.session = context.app.login(context.user)
    assert context.session is not None, f"Failed to create session for {name}"


@when("the user creates a {entity} with name {name}")
def step_when_create_entity(context, entity, name):
    """
    Perform entity creation via the application.

    Args:
        entity (str): Type of entity to create
        name (str): Name for the new entity
    """
    context.response = context.app.create(entity, {"name": name}, session=context.session)


@then("the {entity} record should have:")
def step_then_record_should_have(context, entity):
    """
    Assert the entity record matches expected field values.

    Args:
        entity (str): Type of entity to verify
    """
    record = context.app.get_latest(entity)
    assert record is not None, f"No {entity} record found"
    for row in context.table:
        actual = getattr(record, row["field"])
        assert str(actual) == row["value"], (
            f"{entity}.{row['field']}: expected {row['value']}, got {actual}"
        )
```
