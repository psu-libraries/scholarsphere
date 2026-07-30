# Purpose

To provide functions for auto-populating a `WorkVersion`'s open access version and open access permissions fields on the publish page.

## Responsibilities

This directory is responsible for:

- Auto-populating a `WorkVersion`'s `open_access_version` field when updated in the database via a Rails endpoint and `ActionCable` on the `WorkVersion` upload publish page
- Auto-populates the `publisher_statement`, `license`, and `embargo_date` using selected `open_access_version` and open access permissions stored in a hidden element in the DOM.
- Preventing the user from clicking the 'Publish' button until an `open_access_version` is determined.

This directory is NOT responsible for:

- Any pages outside of the publish page.
- Auto-populating any fields other than the `open_access_version`, `publisher_statement`, `license`, and `embargo_date`.
- Retrieving the open access permissions data from OA.Works or determining the `WorkVersion`'s `open_access_version`.

## Workflow

1. User enters the publish page.
2. JavaScript checks the Rails endpoint for this `WorkVersion`'s `open_access_version`, and an `ActionCable` connection is set up to receive `open_access_version` updates.
3. The `open_access_version` field is updated when an `open_access_version` is retrieved or updated.
4. Open access permissions data hidden in the DOM is used to select the permissions that map to the open access version.
5. The permissions fields are auto-populated.
6. Any user changes to the `open_access_version` field trigger an update to the open access permissions fields.


## Invariants

These should always remain true:

- Calls should remain internal to ScholarSphere
- Business constants and values should be pulled from the DOM, not stored in javascript code

## Contracts

- The `open-access:version-updated` event must be dispatched with `detail.versionAllowed` as a boolean.
- Timeout fallback runs once after 15 seconds.
- On timeout, if loading is still visible and controls are still hidden, the UI should reveal controls, hide the spinner, and make one final fetch to the Rails endpoint.
- ActionCable updates must be ignored when the incoming id does not match the page `WorkVersion` id.
- Open access field values must be sourced from DOM-provided data attributes.

## Acceptance Criteria

- Selecting an `open_access_version` updates `publisher_statement`, `license`, and `embargo_date`.
- The user sees a clear message listing which fields were auto-updated.
- If no permissions match the selected `open_access_version`, guidance is shown and publish is blocked.
- The open access spinner appears during version detection and does not block the user indefinitely.


## Testing

- Use jest.
- Mock timeout configurations so the test suite is fast.
- Cover channel id mismatch behavior.
- Cover timeout fallback and non-fallback branches.
- Assert the `open-access:version-updated` event payload.
- Assert the updated-fields message renders as intended.

## Additional Guidance

- It should be clear to the user which permissions fields were auto-populated.
- If the selected `open_access_version` does not map to any permissions data, the user should be prompted to reupload the correct version and should not be allowed to publish.
