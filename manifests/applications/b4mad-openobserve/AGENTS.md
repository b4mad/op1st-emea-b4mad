# Agent Instructions: b4mad-openobserve

## sops

`sops -d` on files in this directory (e.g. `openobserve-credentials.enc.yaml`)
requires the operator's GPG private key. It is not available in the default
Claude Code sandbox environment (`~/.gnupg` has no secret keyring there).

Run sops decrypt/encrypt operations on `nano` instead, where the key is
present.
