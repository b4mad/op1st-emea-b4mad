# Agent Instructions — b4mad-forgejo

## GPG signing key UID

When generating a GPG key for Forgejo server-side commit signing, the key's
user ID (UID) **must** follow this exact form:

```
Forgejo (#B4mad Forgejo commit signing) <forgejo@b4mad.net>
```

- Name-Real: `Forgejo`
- Name-Comment: `#B4mad Forgejo commit signing`
- Name-Email: `forgejo@b4mad.net`

Do not add per-instance suffixes (e.g. `(nostromo test)`) to the comment — keep
the UID identical across instances so the signing identity is stable.
