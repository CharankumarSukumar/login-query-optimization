# Database normalization review (Week 2)

Schema: `users`, `roles`, `permissions`, `user_roles`, `role_permissions` (see `sql/01_schema.sql`).

## Normal forms, table by table
| Table | Key | 1NF | 2NF | 3NF | Notes |
|---|---|---|---|---|---|
| users | `id` (candidate keys: `username`, `email`) | yes - one value per column | yes - single-column key | yes - every column describes the user only | `failed_attempts` and `last_login` are login state of the user, so they depend only on `id` |
| roles | `id` (`name` unique) | yes | yes | yes | lookup table |
| permissions | `id` (`name` unique) | yes | yes | yes | lookup table |
| user_roles | (`user_id`, `role_id`) | yes | yes - no column outside the key | yes | junction table: many-to-many users <-> roles |
| role_permissions | (`role_id`, `permission_id`) | yes | yes | yes | junction table: many-to-many roles <-> permissions |

Result: the schema is in third normal form. A role name or a permission name is stored once;
changing it updates one row, and there are no update anomalies.

## Why normalization hurts read speed
Finding "all permissions of one user" needs a 4-table join
(`users` -> `user_roles` -> `role_permissions` -> `permissions`). The join is correct but costs
work on every login.

## Deliberate, controlled denormalization
`mv_user_permissions` (materialized view) stores the pre-joined result `(user_id, permission)`.
- Source of truth stays the 5 normalized tables; the view is a derived copy.
- Trade-off: the copy can be stale after role changes, so it must be refreshed:
  `REFRESH MATERIALIZED VIEW CONCURRENTLY mv_user_permissions;`
- Measured benefit: under 20 clients the view gave 15,431 tps versus 5,233 tps for the join (2.9x),
  and about 18,800 tps at 90 clients (see `docs/test_plan.md`).

## Possible further normalization (not done)
Login attempts could move into a separate `login_attempts` table to keep an audit history.
It was left out because the lockout rule only needs the current counter.
