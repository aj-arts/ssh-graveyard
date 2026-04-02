# ssh-graveyard

`ssh-graveyard` is a small Bash utility that reads your SSH config, lists concrete `Host` entries, and checks which targets still respond to `ping`.

## Demo

https://github.com/user-attachments/assets/ca90d6d6-e34d-4b8e-b7fb-64bea08b9c5a

It prints a table with:

- `HOST`: the SSH alias from your config
- `HOSTNAME`: the resolved hostname from `ssh -G`
- `VIA`: whether the host is reached directly, through `ProxyJump`, or through `ProxyCommand`
- `STATUS`: whether the host appears `alive` or `unreachable`

## Requirements

- Bash
- OpenSSH (`ssh`)
- `awk`
- `ping`
- An SSH config file, defaulting to `~/.ssh/config`

## Usage

Run the script directly:

```bash
./graveyard.sh
```

Or point it at a different SSH config:

```bash
SSH_CONFIG=/path/to/config ./graveyard.sh
```

For the bundled safe demo config:

```bash
SSH_CONFIG=./demo/demo-ssh-config ./graveyard.sh
```

## Notes

- Wildcard and negated host entries are skipped.
- Host details are resolved with `ssh -G`, so values inherited from other SSH config sections are taken into account.
- Reachability is based on ICMP `ping`, which may report `unreachable` for hosts that block ping even if SSH still works.
