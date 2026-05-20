# ssh

Every `wheels deploy` command runs over plain SSH. There is no agent
installed on the hosts — the control machine issues Docker commands
remotely and parses the output.

## Defaults

By default `wheels deploy` connects as the current local user using the
default SSH key (`~/.ssh/id_rsa`, `~/.ssh/id_ed25519`, etc.) via the
system SSH agent.

## Overriding

    ssh:
      user: deploy
      port: 22
      proxy: bastion.example.com
      keys:
        - ~/.ssh/deploy_key

## Bastion (ProxyJump)

When `ssh.proxy:` is set, every connection first SSHes into the bastion
and then to the target host. This maps to OpenSSH's `ProxyJump` option.

    ssh:
      proxy: bastion.example.com
      user: deploy

## Agent forwarding

Not forwarded by default. If your build step or hook needs the local
agent inside a container, turn it on explicitly:

    ssh:
      forward_agent: true

## Connection pooling

All commands within one `wheels deploy` invocation share a single SSH
connection per host (ControlMaster-style). Commands that fan out to
every host run in parallel.

## Troubleshooting

    wheels deploy exec "uptime"   # smoke test SSH + sudo
    wheels deploy exec --interactive "bash"

If a host is unreachable, deploy fails fast with the host in the error
message. There is no built-in retry — `wheels deploy` stays strict on
purpose.
