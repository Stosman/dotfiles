# dotfiles

A Stow-based repo. Each top-level folder is a package whose contents
mirror `$HOME`. `stow -t $HOME <package>` symlinks that package's
files into place; `stow -D -t $HOME <package>` removes the links.

## Setup on a new or existing machine

```
sudo apt install stow          # Debian, if not already there
git clone https://github.com/Stosman/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh                   # links everything
# or: ./install.sh zsh btop    # just those packages
```

Everything above stows into `$HOME` and needs no special permissions.
The `etc` package is the one exception: it holds `/etc/stos/stos-duck.ansi`
and `/etc/update-motd.d/99-stos`, so `install.sh etc` runs `sudo stow -t /
etc` instead. Fine to run on its own or mixed in with the rest,
`./install.sh zsh etc` works too, `sudo` only prompts for that one
package.

## Rebuilding the repo from a live machine

`bootstrap-dotfiles.sh` reads the curated `FILES` list near the top
and copies each real file from `$HOME` into the matching package
folder here. Run it on the machine, not inside this repo:

```
./bootstrap-dotfiles.sh ~/dotfiles
```

Edit the `FILES` array when your setup changes, add a line for a
new config file, drop a line for something you no longer use.

## Packages included

| Package    | Contents |
|------------|----------|
| zsh        | `.zshrc` |
| bash       | `.bashrc`, `.bash_profile` |
| npm        | `.npmrc` |
| starship   | `.config/starship.toml` |
| htop       | `.config/htop/htoprc` |
| micro      | `.config/micro/bindings.json`, `settings.json`, `syntax/ansi.yaml` |
| git        | `.gitconfig` |
| neofetch   | `.config/neofetch/config.conf` |
| btop       | `.config/btop/btop.conf` |
| motd       | `motd_art`, `motd1` |
| scripts    | the whole `scripts/` folder |
| misc       | `duck.sh`, `solidfy.py` |
| etc        | `/etc/stos/stos-duck.ansi`, `/etc/update-motd.d/99-stos` |

## Deliberately left out

- `.profile` — confirmed leftover Debian boilerplate, no real edits.
- `micro/colorschemes/` and `btop/themes/` — both empty right now.
  Add them back into `FILES` in `bootstrap-dotfiles.sh` if you ever
  drop a custom theme in either.
- `.ssh/` — holds your private key (`id_rsa`). This never belongs in
  a git repo, public or private. If you want your `known_hosts` or
  an SSH `config` tracked, add just that one file by hand, never the
  whole directory.
- `.docker/config.json` and `.docker/.token_seed*` — these can hold
  registry auth tokens.
- `.npm/`, `.cache/`, `.local/` — caches and pipx virtualenvs. These
  get rebuilt automatically (`npm install`, `pipx install gdown`,
  etc.), so there's nothing worth versioning.
- `.bash_history`, `.zsh_history`, `.lesshst` — command history.
  Personal, not configuration, and often reveals more than you'd
  want in a repo (paths, hostnames, one-off commands).
- `.zcompdump*`, `.wget-hsts` — regenerated automatically, no reason
  to track them.
- Binaries in `~/.local/bin` (`fd`, `bat`, `zoxide`, `gdown`) — these
  are installed tools, not config. Reinstall them with your package
  manager or `cargo install` / `pipx install` rather than committing
  the compiled binaries. Worth adding an `install-tools.sh` here
  later if you want that scripted too.
- `~/.config/ookla/speedtest-cli.json` — machine-specific speedtest
  CLI state, not something you'd want to reuse elsewhere.

## Notes

- No cron jobs or systemd user timers found (checked with `crontab
  -l` and `systemctl --user list-timers`), so everything here runs
  by hand. Nothing extra to capture.
- `stos-duck.ansi.bak` sitting in your home folder is a leftover copy
  of `/etc/stos/stos-duck.ansi`, the real one now lives in the `etc`
  package. Safe to delete the `.bak` once you've confirmed the two
  match.
- If you keep different machines (desktop vs. the `stos` server),
  consider a second install profile, e.g. `./install.sh zsh starship
  scripts` on the server instead of running everything.
