# Agent Instructions — b4mad-dolt

## Adding a SQL user

`dolt sql-server` speaks the MySQL protocol and uses MySQL's standard
privilege system (`CREATE USER` / `GRANT`), persisted in its own `mysql`
system database on the PVC — there is no separate user-management manifest
or CRD for this. Users are created by connecting as `root` and running SQL.

The MySQL port (3306) has no external Route (see `ingress.yaml` for why —
HAProxy can't carry the wire protocol), so reach it either from inside the
cluster or via port-forward:

```bash
oc port-forward -n b4mad-dolt svc/dolt-sql-server 3306:3306
```

Get the root password from the sealed secret's source (see
`root-password-secret.enc.yaml` / your SOPS-decrypted copy, or
`oc get secret dolt-root -n b4mad-dolt -o jsonpath='{.data.DOLT_ROOT_PASSWORD}' | base64 -d`),
then connect and create the user:

```bash
mysql -h 127.0.0.1 -P 3306 -u root -p
```

```sql
CREATE USER 'alice'@'%' IDENTIFIED BY 'change-me';

-- Grant access to a specific database (typical case: a dolt database this
-- user will clone/push/pull via remotesapi):
GRANT ALL PRIVILEGES ON some_database.* TO 'alice'@'%';

-- Or, if the user only needs remotesapi clone/push access and no direct
-- SQL access beyond that, scope grants to what they actually need instead
-- of blanket ALL PRIVILEGES.

FLUSH PRIVILEGES;
```

New users authenticate against remotesapi the same way root does:

```bash
DOLT_REMOTE_PASSWORD=change-me dolt clone --user alice \
  https://hub.dolt.b4mad.industries/<database>
```

## Creating a database for remotesapi

remotesapi exposes whatever databases the server already has — there is no
separate "register this database for remotesapi" step. Creating it over SQL
is enough:

```sql
CREATE DATABASE some_database;
```

`dolt-sql-server` creates `some_database` as its own dolt repo directory
under `/var/lib/dolt` (the `dolt-data` PVC) the moment this runs, and
remotesapi serves it immediately at
`https://hub.dolt.b4mad.industries/some_database` — same host, path is just
the database name.

Grant the users who need it access (see above), then clone:

```bash
DOLT_REMOTE_PASSWORD=change-me dolt clone --user alice \
  https://hub.dolt.b4mad.industries/some_database
```

If you already have a local dolt repo you want to publish instead of
starting empty, push to it as a remote once the (empty) database exists
server-side:

```bash
dolt remote add hub https://hub.dolt.b4mad.industries/some_database
DOLT_REMOTE_PASSWORD=change-me dolt push hub main
```

### Persistence

Both user grants (in the `mysql` system database) and databases (each its
own dolt repo directory) live only on the `dolt-data` PVC, not in any
Kubernetes manifest. They survive pod restarts (same PVC) but are **not**
captured by GitOps — if the PVC is ever recreated, both users and databases
must be re-created manually. Don't hand-write a manifest for either; there
isn't a declarative resource for dolt SQL users or databases to hand-write
against.
