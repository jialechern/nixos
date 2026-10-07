# AGENTS.md

Flake-based NixOS + Home Manager configuration for two machines, single user
`jlc` (defined once in `flake.nix`). System modules live in `modules/` (imported
wholesale via `modules.nix`), Home Manager config in `home.nix` + `home/`,
per-machine config in `hosts/<hostname>/` — each host's `configuration.nix` only
imports its `hardware-configuration.nix` and the shared `hosts/common.nix`
(users and groups, mount options, stateVersion) and sets `networking.hostName`.
**Import order matters**: `../common.nix` must come before
`./hardware-configuration.nix`, since their `fileSystems.options` lists merge in
import order and the order lands in the generated fstab (and the drv hash).

## Commands

- Rebuild system **and** home manager in one step (HM is embedded as a NixOS
  module — there is no standalone `home-manager switch`): the **user** runs
  `sudo nixos-rebuild switch --flake /etc/nixos#omen` (or `#hp`). Agents cannot
  run `sudo` (denied by the local permission policy), so make the change and ask
  the user to rebuild.
- Fresh install: `sudo ./nixos-install.sh -n <host>` (wraps `nixos-install` with
  TUNA substituters)
- Fast eval check: `nix flake check` (evaluates every nixosConfiguration). Bare
  `nix build` fails — there is no default package; use
  `nix build .#nixosConfigurations.<host>.config.system.build.toplevel` if you
  need the derivation.
- `nixpkgs` is pinned to the TUNA git mirror
  (`git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-unstable`)
  — do not "fix" this URL to GitHub; the lockfile matches it. Substituters
  (TUNA, USTC, cache.nixos.org) are set in `modules/nix-config.nix`.

## Structure

- `hosts/`: `common.nix` (shared host-level config, imported by both hosts) and
  `hosts/<name>/`: requires `configuration.nix` + `hardware-configuration.nix`
  plus an entry in `flake.nix`. GPU module is chosen per host:
  `./modules/nvidia.nix` (dGPU, e.g. `omen`) or `./modules/intel-extra.nix`
  (iGPU, e.g. `hp`) — never both.
- Flake inputs: `nixpkgs` (TUNA mirror), `home-manager`, `sops-nix` and `pi`
  (GitHub: `earendil-works/pi/stable`, `follows` this repo's nixpkgs). All three
  of `home-manager`, `sops-nix` and `pi` are fetched from GitHub, and `pi`
  additionally pulls a fixed-output model catalog and npm tarball from `pi.dev`
  at build time, so it belongs on the "needs a proxy on a first install" list
  too (README's 网络问题 section). Unlike `sops.nix`, `home/shell/pi.nix` has no
  `pathExists` switch: it is imported unconditionally by `home/shell.nix`, so
  disabling it means commenting that import out. No
  external dotfiles inputs remain: the Neovim config now lives in this repo at
  `home/shell/nvim/` and is deployed to `~/.config/nvim` by
  `home/shell/nvim.nix` (see "Neovim config" below); KeePassXC is still
  software-only, `~/.config/keepassxc/` is maintained locally. The
  personal `scripts` input is gone too: `play-musics` is no longer installed
  (its search is inlined into niri's `Mod+Ctrl+M` bind in
  `home/desktop/niri/conf.d/bind.kdl`) and `by-proxies-run` was dropped from
  `home.file`. `~/Wallpapers/` is likewise no longer a symlink into a
  wallpapers input: it is declared by `xdg.userDirs.extraConfig.WALLPAPERS` in
  `home.nix` and created by `createDirectories = true`, and the user fills it
  with images. niri's startup and wallpaper binds recurse into every subdirectory of
  it by enumerating the directories with `find` and passing all of them as
  `--folder` (waypaper's own CLI has no subfolder switch; its GUI-side recursion
  is controlled by `subfolders` and `all_subfolders` in the user's
  `~/.config/waypaper/config.ini`).

## Neovim config

`home/shell/nvim/` is the single source of truth; `home/shell/nvim.nix` deploys
it to `~/.config/nvim` the way `niri.nix` deploys niri: a `pkgs.runCommand`
copies the directory (dropping `AGENTS.md`, failing the build if any `*.lua`
fails a `luajit -bl` syntax check) and `xdg.configFile."nvim"` symlinks it
recursively — **read-only store links, so edit the repo and rebuild;
`~/.config/nvim` cannot be edited in place**. Subtree rules (load order,
single-sourced keymaps, treesitter, folding) live in `home/shell/nvim/AGENTS.md`
— read it before touching the config.

- `home/shell/nvim/**` must be `git add`-ed before rebuilding: a newly created
  Lua file is invisible to the git-flake filter and would silently stay out of
  the deployment (see the git-indexed-files gotcha below).
- Plugins, grammars/queries and LSP/format binaries come from nix, never from
  lazy.nvim/Mason: declare them in `home/shell/nvim.nix`
  (`programs.neovim.plugins`; `{ plugin = ...; optional = true; }` puts a plugin
  in `pack/hm/opt` for `packadd`, a bare package name puts it in `start`).
  `packadd` takes the *directory* name under
  `~/.local/share/nvim/site/pack/hm/`, which is not always the nixpkgs attribute
  name.
- `programs.neovim.sideloadInitLua` stays `true`: it keeps nix's `initLua`
  (luajit `package.path`, disabled providers) out of `~/.config/nvim/init.lua`,
  injecting it through wrapper `--cmd` flags instead. Setting it to `false`
  makes HM write that file and collide with the deployed config.
- The hot-debug channel is `~/.config/nvim/after/plugin/local-live.lua`: a
  tmpfiles-created writable file (not in the flake, never overwritten by a
  rebuild, cannot fail the build) that nvim auto-sources as the last step of
  startup. Apply edits with `:luafile %` or `:restart`; the subtree AGENTS.md
  has the recipe.
- Checking a change needs no rebuild — run from `home/shell/nvim/` (nvim writes
  only to `~/.local/{share,state}/nvim`, never into the config dir):
  - all Lua parses: `nvim --headless -u NONE -i NONE -c 'lua for _,f in ipairs(vim.fn.glob("**/*.lua",false,true)) do assert(loadfile(f)) end' -c 'qa!'`
  - config without plugins: `nvim --headless --noplugin -i NONE --cmd "set rtp^=$PWD" -u "$PWD/init.lua" -c 'qa!'`
  - full load with plugins (catches a wrong `packadd` name): drop `--noplugin`
  - keymap self-check: run `require('utils.map').check()` in the full load;
    `stylua --check` and `lua-language-server --check=. --checklevel=Warning`
    (needs `VIMRUNTIME`) are documented in the subtree AGENTS.md.
- After switching, a plain `nvim` must load the deployed tree: `ls -la
  ~/.config/nvim` should show per-file symlinks into
  `/nix/store/*-home-manager-files/.config/nvim/`, which chain into the
  `/nix/store/*-nvim-config-checked/` tree.

## Gotchas

- **Optional modules are toggled by file existence, not flake edits.** These
  imports are guarded by `builtins.pathExists`:
  `modules/system-dependencies-require-proxy.nix`,
  `home/desktop/applications-require-proxy.nix`, `home/shell/nvim.nix`, in
  `home.nix`: `sops.nix`, `home/desktop.nix`, and in `home/other.nix`:
  `home/other/skills.nix`. Move a file away to disable it; restore to
  re-enable. Only `sops.nix` additionally needs its input and comments handled
  in `flake.nix` (see README). A git flake only copies
  files indexed by git, so a newly added switch file must be `git add`-ed first —
  otherwise the switch silently stays false, and `warn-dirty = false` in
  `modules/nix-config.nix` suppresses the only warning you would get. The same
  filter means the built tree is the worktree **restricted to git-indexed
  files**: untracked files are invisible, while staged *and* unstaged edits to
  tracked files are both built. So a successful rebuild is not evidence that the
  committed tree builds — check `git status` is clean before treating a build as
  a contract comparison.
- **sops-nix**: secrets are age-encrypted files under `secrets/` (routing rules
  in `.sops.yaml`); the decryption key must exist at
  `~/.config/sops/age/keys.txt` when the configuration is **activated** — HM's
  activation script (which runs inside `nixos-rebuild switch`) is what decrypts,
  so a plain `nix build` does not need the key. Edit secrets with
  `sops secrets/<dir>/<file>.yaml`. Encrypted files are committed; never add
  plaintext secrets.
- **Proxy dependence**: nix-daemon is configured with `http://127.0.0.1:20172`
  in `modules/nix-config.nix`; some packages (and sops) only build via the
  transparent proxy (v2raya). If a build fails on network fetch and the proxy is
  down, temporarily remove the `*-require-proxy` files or `sops.nix` rather than
  editing proxy config.
- `stateVersion` is `25.11` in both system and home configs — do not bump
  casually.

## Conventions

- Code comments and commit messages are in Chinese; match that when writing
  them. Commit style is conventional commits: `feat(rofi): ...`,
  `fix(niri): ...`, `chore(deps): ...`.
- No formatter is configured in the flake; follow the surrounding style of the
  file you edit.
- `AGENTS.md` files are tracked — the root one used to be gitignored and the
  `.gitignore` entry is gone. Keep repo-wide rules here and put subtree rules in
  a nested `AGENTS.md` next to the code, as `home/shell/nvim/AGENTS.md` does.
