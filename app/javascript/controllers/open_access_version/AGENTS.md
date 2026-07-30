# Purpose

To auto-populate a `WorkVersion`'s open access version and open access permissions fields on the publish page.

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

User enters the publish page --> Javascript checks the Rails endpoint for this `WorkVersion`'s `open_access_version` and `ActionCable` connection is set up to receive `open_access_version` updates --> Updates the `open_access_version` field when an `open_access_version` is retrieved or updated --> Uses open access permissions data hidden in DOM to select the permissions that map to the open access version --> autopopulates the permissions fields --> Any user changes to the `open_access_version` field will trigger an update to the open access permissions fields


## Invariants

These should always remain true:

- Calls should remain internal to ScholarSphere
- Business constants and values should be pulled from the DOM, not stored in javascript code


## Testing

- Use jest.
- Mock timeout configurations so the test suite us fast.

## Additional Guidance

- It should be clear to the user that when permissions data is auto-populated what fields were updated.
