# 2. Define use of decorators and presenters

Date: 2019-11-04

## Status

Accepted

## Context

The issue motivating this decision, and any context that influences or constrains the decision.
We need to distinguish between decorator and presenter objects in order to clarify which would be used in a given
situation.

## Decision

Decorators extend SimpleDelegator and will always delegate undefined methods to the delegated object.

Presenters take the form of "plain ol' Ruby objects" (POROs) and would generally not delegate methods to an object.
Their usage is designed to be more flexible when the rendering of content isn't tied specifically to one object.

## Consequences

While decorators are firmly extensions of SimpleDecorator, presenters have an amorphous structure which could lead to differing opinions about their usage later on.

