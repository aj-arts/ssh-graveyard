# ssh-graveyard

`ssh-graveyard` is a small Bash utility that reads your SSH config, lists concrete `Host` entries, and checks which targets still respond to `ping`.

## Demo

https://github.com/user-attachments/assets/4b9093bf-2895-481b-94ee-ec408a8700ee

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

## Install

Install `ssh-graveyard` into `~/.local/bin`:

```bash
mkdir -p ~/.local/bin && curl -fsSL https://raw.githubusercontent.com/aj-arts/ssh-graveyard/main/graveyard.sh -o ~/.local/bin/ssh-graveyard && chmod +x ~/.local/bin/ssh-graveyard
```

If `~/.local/bin` is not already on your `PATH`, add this to `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload your shell:

```bash
source ~/.zshrc
```

## Usage

Run it from any terminal:

```bash
ssh-graveyard
```

Or point it at a different SSH config:

```bash
SSH_CONFIG=/path/to/config ssh-graveyard
```

## Notes

- Wildcard and negated host entries are skipped.
- Host details are resolved with `ssh -G`, so values inherited from other SSH config sections are taken into account.
- Reachability is based on ICMP `ping`, which may report `unreachable` for hosts that block ping even if SSH still works.
