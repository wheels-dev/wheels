# SSH test fixture

Two openssh-server containers on host ports 22022 and 22023, user `deploy`
with sudo and password auth disabled. Used by SshClientSpec (Task 6+) and
SshPoolSpec (Task 9).

## Start / Stop

```bash
bash tools/deploy-sshd-up.sh
bash tools/deploy-sshd-down.sh
```

The specs start the fixture (`up -d` is idempotent) but leave it running: it is one
Compose project on fixed ports, shared by every checkout on the machine, so a
per-spec teardown could stop it under another CLI suite running at the same time.
Stop it with `deploy-sshd-down.sh` when you're done, or set
`WHEELS_DEPLOY_SSHD_TEARDOWN=1` to have the specs stop it after each bundle.

`test_key` is a deterministic ed25519 keypair committed to the repo — it
has NO production value and exists only for test reproducibility.
