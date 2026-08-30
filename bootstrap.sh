#!/usr/bin/env bash
# Bootstrap a fresh machine for this Neovim config.
#
# Idempotent and safe to re-run: every step checks before it acts.
#
#   ./bootstrap.sh              # everything
#   ./bootstrap.sh --no-dotnet  # skip the .NET SDK (~1GB), if no C# work here
#   ./bootstrap.sh --check      # report what's missing, change nothing
#
# Ubuntu/Debian only (uses apt). Prompts once for sudo.

set -euo pipefail

DO_DOTNET=1
CHECK_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --no-dotnet) DO_DOTNET=0 ;;
    --check)     CHECK_ONLY=1 ;;
    -h|--help)   sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

BOLD=$'\033[1m'; RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; RST=$'\033[0m'
step() { printf '\n%s==> %s%s\n' "$BOLD" "$1" "$RST"; }
ok()   { printf '  %s✓%s %s\n' "$GRN" "$RST" "$1"; }
warn() { printf '  %s!%s %s\n' "$YLW" "$RST" "$1"; }
err()  { printf '  %s✗%s %s\n' "$RED" "$RST" "$1"; }

# `command -v` is not enough here: Claude Code installs a shell *function*
# named rg that shims ripgrep out of its own binary, so `command -v rg`
# succeeds on a machine with no real ripgrep. Check the filesystem instead.
have() { unset -f "$1" 2>/dev/null || true; command -v "$1" >/dev/null 2>&1; }

# `ls missing/dir | wc -l` exits 2 under `set -o pipefail`, which kills the
# script mid-summary. Count without depending on ls's exit status.
count_dir() {
  [[ -d $1 ]] || { echo 0; return 0; }
  find "$1" -mindepth 1 -maxdepth 1 -printf . 2>/dev/null | wc -c
}

# --------------------------------------------------------------- 0. nvim

# nvim-treesitter's main branch (pinned in lazy-lock.json) needs Neovim
# 0.12+: it calls vim.list.unique(), absent in 0.11, so install() throws
# and NO parser ever builds. Ubuntu 26.04's apt tops out at 0.11.6, hence
# the snap. apt's nvim must go too -- /usr/bin precedes /snap/bin on PATH,
# so leaving it installed keeps 0.11.6 shadowing the snap.
step "Neovim >= 0.12"
nvim_minor() { { nvim --version 2>/dev/null || true; } | sed -n '1s/.*v0\.\([0-9]*\).*/\1/p'; }
cur="$(nvim_minor)"

if [[ -n $cur && $cur -ge 12 ]]; then
  ok "$(nvim --version | head -1) at $(command -v nvim)"
elif [[ $CHECK_ONLY -eq 1 ]]; then
  warn "Neovim 0.$cur is too old for nvim-treesitter main (needs 0.12+)"
  warn "would: snap install nvim --classic; apt remove neovim"
else
  echo "  Neovim 0.$cur is too old; installing snap (classic)..."
  sudo snap install nvim --classic
  if dpkg -s neovim >/dev/null 2>&1; then
    echo "  removing apt neovim (it shadows the snap via /usr/bin)..."
    sudo apt-get remove -y neovim
  fi
  hash -r
  new="$(nvim_minor)"
  if [[ -n $new && $new -ge 12 ]]; then
    ok "$(nvim --version | head -1) at $(command -v nvim)"
  else
    err "still on 0.$new at $(command -v nvim) -- check PATH order"
    err "treesitter parsers will not build until this resolves"
  fi
fi

# ---------------------------------------------------------------- 1. apt

APT_PKGS=(
  build-essential      # cc/make: treesitter parsers, telescope-fzf-native
  golang-go            # gopls, sqls
  ripgrep              # telescope live_grep
  fd-find              # telescope <leader>fu picker
  fzf                  # telescope-fzf-native
  git curl wget unzip  # mason downloaders
  imagemagick          # image.nvim (processor = "magick_cli")
  wl-clipboard         # img-clip <leader>p on Wayland
  xclip                # ...and the X11 fallback
)
[[ $DO_DOTNET -eq 1 ]] && APT_PKGS+=(dotnet-sdk-10.0)   # csharpier, roslyn

step "System packages (apt)"
missing=()
for p in "${APT_PKGS[@]}"; do
  dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
done

if [[ ${#missing[@]} -eq 0 ]]; then
  ok "all ${#APT_PKGS[@]} packages already installed"
elif [[ $CHECK_ONLY -eq 1 ]]; then
  warn "would install: ${missing[*]}"
else
  echo "  installing: ${missing[*]}"
  sudo apt-get update -qq
  sudo apt-get install -y "${missing[@]}"
  ok "installed ${#missing[@]} package(s)"
fi

# ------------------------------------------------------- 2. fd -> fdfind

# Debian ships the binary as `fdfind` (name clash with an older fd package),
# but telescope/keymaps.lua:60 shells out to plain `fd`.
step "fd shim"
mkdir -p ~/.local/bin
if have fd; then
  ok "fd already resolvable"
elif [[ $CHECK_ONLY -eq 1 ]]; then
  warn "would symlink ~/.local/bin/fd -> $(command -v fdfind 2>/dev/null || echo /usr/bin/fdfind)"
elif [[ -x /usr/bin/fdfind ]]; then
  ln -sf /usr/bin/fdfind ~/.local/bin/fd
  ok "~/.local/bin/fd -> /usr/bin/fdfind"
else
  err "fdfind not found; <leader>fu will not work"
fi

# ------------------------------------------------------------- 3. node

# Deliberately NOT apt's npm: Ubuntu pairs npm 9.2.0 with nodejs 22, a
# combination that breaks on `npm -g`. fnm is user-level and per-project.
step "Node (via fnm)"
export FNM_DIR="${FNM_DIR:-$HOME/.local/share/fnm}"
[[ -d $FNM_DIR ]] && export PATH="$FNM_DIR:$PATH"

if have node && have npm; then
  ok "node $(node -v), npm $(npm -v)"
elif [[ $CHECK_ONLY -eq 1 ]]; then
  warn "would install fnm + Node LTS"
else
  if ! have fnm; then
    curl -fsSL https://fnm.vercel.app/install.sh \
      | bash -s -- --install-dir "$FNM_DIR" --skip-shell
    export PATH="$FNM_DIR:$PATH"
  fi
  eval "$(fnm env --shell bash)"
  fnm install --lts
  fnm default "$(fnm current)"
  eval "$(fnm env --shell bash)"
  ok "node $(node -v), npm $(npm -v)"

  # Wire fnm into future interactive shells, once.
  for rc in ~/.bashrc ~/.zshrc; do
    [[ -f $rc ]] || continue
    grep -q 'fnm env' "$rc" && continue
    case "$rc" in *zshrc) sh=zsh ;; *) sh=bash ;; esac
    printf '\n# fnm (added by nvim bootstrap.sh)\nexport PATH="%s:$PATH"\neval "$(fnm env --use-on-cd --shell %s)"\n' \
      "$FNM_DIR" "$sh" >> "$rc"
    ok "wired fnm into $(basename "$rc")"
  done
fi

# ------------------------------------------------------------- 4. oxfmt

# formatting.lua:31 hardcodes ~/.vite-plus/bin/oxfmt. Rather than edit the
# config, put a binary at that path so it keeps working as written.
step "oxfmt (conform formatter for js/ts/css/html/json/yaml)"
OXFMT=~/.vite-plus/bin/oxfmt
if [[ -x $OXFMT ]]; then
  ok "already present at $OXFMT"
elif [[ $CHECK_ONLY -eq 1 ]]; then
  warn "missing: $OXFMT (format-on-save is a silent no-op without it)"
elif have npm; then
  mkdir -p ~/.vite-plus/bin
  if npm install -g oxfmt >/dev/null 2>&1 && have oxfmt; then
    ln -sf "$(command -v oxfmt)" "$OXFMT"
    ok "installed and linked -> $OXFMT"
  else
    err "npm could not install 'oxfmt'."
    err "If you use the Vite+ toolchain, install it there; the config"
    err "expects the binary at $OXFMT."
    err "Until then js/ts format-on-save silently does nothing"
    err "(notify_on_error = false in formatting.lua)."
  fi
else
  warn "skipped (no npm)"
fi

# ------------------------------------------------------------ 5. neovim

step "Neovim plugins, LSPs and parsers"
if [[ $CHECK_ONLY -eq 1 ]]; then
  warn "would sync lazy, install mason packages, build treesitter parsers"
else
  export PATH="$HOME/.local/bin:$FNM_DIR:$PATH"
  have fnm && eval "$(fnm env --shell bash)" || true

  echo "  syncing plugins..."
  nvim --headless "+Lazy! sync" +qa 2>&1 | grep -vE '^\s*$' || true

  echo "  installing mason packages (this blocks; a few minutes)..."
  # Registry names, not lspconfig names. Mirrors mason.lua's two lists.
  nvim --headless -c 'MasonInstall \
    html-lsp css-lsp cssmodules-language-server json-lsp lua-language-server \
    gopls svelte-language-server sqls \
    oxlint stylua typescript-language-server csharpier roslyn-language-server' \
    -c 'qa' 2>&1 | tail -20 || warn "some mason packages failed; see :MasonLog"

  # `Lazy! build` fires treesitter's install() and returns in ~1ms -- the
  # main-branch install() is async, so headless exits before anything
  # compiles. Drive it directly and block on the returned Task instead.
  # NOTE: this list must stay in sync with the `build` hook in
  # lua/matsa/plugins/treesitter.lua -- blocking is only possible from here.
  echo "  building treesitter parsers (needs cc; a few minutes)..."
  nvim --headless -c 'lua
    local langs = {
      "bash","c_sharp","css","dockerfile","gitignore","go","html",
      "javascript","jsdoc","json","lua","markdown","markdown_inline",
      "query","sql","svelte","tsx","typescript","vim","vimdoc","xml","yaml",
    }
    local ok, t = pcall(require("nvim-treesitter").install, langs)
    if not ok then
      io.stderr:write("treesitter install failed: " .. tostring(t) .. "\n")
    elseif t and t.wait then
      pcall(function() t:wait(900000) end)
    end' -c 'qa' 2>&1 | tail -5 || warn "treesitter install reported errors"
  ok "neovim bootstrap done"
fi

# ------------------------------------------------------------ 6. verify

step "Verification"
fail=0
check() {
  if have "$1"; then ok "$(printf '%-12s %s' "$1" "$(command -v "$1")")"
  else err "$(printf '%-12s MISSING — %s' "$1" "$2")"; fail=1; fi
}
if [[ -n "$(nvim_minor)" && "$(nvim_minor)" -ge 12 ]]; then
  ok "$(printf '%-12s %s' nvim "$(nvim --version | head -1 | awk '{print $2}')")"
else
  err "$(printf '%-12s 0.%s — too old, treesitter main needs 0.12+' nvim "$(nvim_minor)")"; fail=1
fi
check cc     "treesitter parsers cannot compile"
check make   "telescope-fzf-native cannot build"
check go     "gopls, sqls"
check node   "typescript-tools"
check npm    "typescript-tools, mason js packages"
check rg     "telescope live_grep"
check fd     "telescope <leader>fu"
check magick "image.nvim previews"
[[ $DO_DOTNET -eq 1 ]] && check dotnet "csharpier, roslyn"

if [[ -x ~/.local/share/nvim/mason/bin/lua-language-server ]]; then
  n=$(count_dir ~/.local/share/nvim/mason/bin)
  ok "mason: $n binaries installed"
fi
n_parsers=$(count_dir ~/.local/share/nvim/site/parser)
if [[ $n_parsers -gt 0 ]]; then ok "treesitter: $n_parsers parsers built"
else err "treesitter: 0 parsers built"; fail=1; fi

echo
if [[ $fail -eq 0 ]]; then
  printf '%s%sAll good.%s Open nvim; it should start clean.\n' "$BOLD" "$GRN" "$RST"
else
  printf '%s%sSome tools are still missing%s (listed above).\n' "$BOLD" "$YLW" "$RST"
  printf 'If you just installed Node, open a new shell — fnm needs a fresh login.\n'
fi
exit 0
