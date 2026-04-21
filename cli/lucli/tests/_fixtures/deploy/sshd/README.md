# SSH test fixture

Two openssh-server containers on host ports 22022 and 22023, user `deploy`
with sudo and password auth disabled. Used by SshClientSpec (Task 6+) and
SshPoolSpec (Task 9).

## Start / Stop

```bash
bash tools/deploy-sshd-up.sh
bash tools/deploy-sshd-down.sh
```

`test_key` is a deterministic ed25519 keypair committed to the repo — it
has NO production value and exists only for test reproducibility.
