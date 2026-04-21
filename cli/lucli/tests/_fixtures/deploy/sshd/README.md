# SSH test fixture

Two openssh-server containers on ports 22022 and 22023.

## Start / Stop

    bash tools/deploy-sshd-up.sh
    bash tools/deploy-sshd-down.sh

`test_key` is a deterministic ed25519 keypair. NO production value; exists
only for test reproducibility. Both containers accept the same `authorized_keys`
so a single key unlocks both hosts.

User: `deploy` (passwordless sudo enabled).
