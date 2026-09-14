export PATH="/usr/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
alias comic_dl="docker run -it --rm -e PGID=100 -e PUID=1002 -v /pool1/Media/Comics-incoming:/directory:rw -w /directory ghcr.io/xonshiz/comic-dl:latest comic_dl -dd /directory"
alias comic_dl="docker run -it --rm -e PGID=100 -e PUID=1002 -v /pool1/Media/Comics-incoming:/directory:rw -w /directory ghcr.io/xonshiz/comic-dl:latest comic_dl -dd /directory"

# Created by `pipx` on 2026-08-12 19:46:22
export PATH="$PATH:/pool1/Home/christos/.local/bin"
eval "$(zoxide init zsh --cmd cd)"
eval "$(starship init bash)"
