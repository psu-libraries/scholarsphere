# 9. Access Controls and Actor Permissions

Date: 2020-05-19

## Status

Accepted

## Context

Permissions on works and collections can come from two sources: 1) the person who authored the resource, such as the
depositor or the proxy depositor; and 2) access controls (ACLs) that grant permissions based on user or group identity.

When determining who has access to a given resource, both these sources may need to be consulted.

## Decision

Access controls and depositor or proxy depositor rights are independent from one another.

Access controls should not include permissions granted by the Actor-to-resource arrangement, such as edit rights of the
depositor. They are a separate form of permission structure and therefore independent of one another. Likewise,
permissions that come from a depositor should have no bearing on what access controls may be applied to a resource.

## Consequences

There is no "one stop shop" for permissions. Access controls will not have ALL the possible permissions for a given
resource. It's up to the implementer to check all locations. This can be done via policy objects to determine access
to an individual resource, and Solr queries will need to account for both ACL-based permissions and depositor/proxy
permissions as well.

