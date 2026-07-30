# Stimulus Controllers

## Purpose

Stimulus controllers coordinate user interactions and DOM updates. They should remain lightweight and delegate business logic to collaborators.

## Design Principles

* Keep controllers small and focused.
* Prefer private methods for implementation details.
* Keep lifecycle methods (`connect`, `disconnect`) concise.
* Delegate API calls, polling, validation, and business logic to modules or service objects.
* Prefer composition over large controllers.

## Responsibilities

Controllers should:

* Respond to Stimulus lifecycle events.
* Handle `data-action` events.
* Read and update the DOM.
* Coordinate collaborators.

Controllers should **not**:

* Contain complex business logic.
* Perform extensive data transformation.
* Mix unrelated responsibilities.

## Testing

* Test business logic outside the controller whenever possible.
* Keep controller tests focused on user interactions and DOM behavior.
