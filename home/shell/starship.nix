{ config, pkgs, lib, ... }:

{
  programs.starship = {
    enable = true;

    # 开启 Shell 支持
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;

    # 配置路径
    configPath = "${config.xdg.configHome}/starship.toml";

    settings = {
      # 基础设置
      "$schema" = "https://starship.rs/config-schema.json";
      add_newline = true;
      continuation_prompt = "[▸▹ ](dimmed white)";

      # 主布局配置
      format = lib.concatStrings [
        "($nix_shell$container$fill$git_metrics\n)"
        "$cmd_duration"
        "$hostname"
        "$localip"
        "$shlvl"
        "$shell"
        "$env_var"
        "$jobs"
        "$sudo"
        "$username"
        "$character"
      ];

      right_format = lib.concatStrings [
        "$singularity$kubernetes$directory$vcsh$fossil_branch"
        "$git_branch$git_commit$git_state$git_status$hg_branch"
        "$pijul_channel$docker_context$package$c$cpp$cmake"
        "$cobol$daml$dart$deno$dotnet$elixir$elm$erlang"
        "$fennel$fortran$golang$guix_shell$haskell$haxe$helm"
        "$java$julia$kotlin$gradle$lua$nim$nodejs$ocaml$opa"
        "$perl$php$pulumi$purescript$python$raku$rlang$red"
        "$ruby$rust$scala$solidity$swift$terraform$vlang$vagrant"
        "$xmake$zig$buf$conda$pixi$meson$spack$memory_usage"
        "$aws$gcloud$openstack$azure$crystal$custom$status"
        "$os$battery$time"
      ];

      # 填充
      fill.symbol = " ";

      # 核心交互符号
      character = {
        format = "$symbol ";
        success_symbol = "[◎](bold italic bright-yellow)";
        error_symbol = "[○](italic purple)";
        vimcmd_symbol = "[■](italic dimmed green)";
        vimcmd_replace_one_symbol = "◌";
        vimcmd_replace_symbol = "□";
        vimcmd_visual_symbol = "▼";
      };

      # 用户名与权限
      username = {
        style_user = "bright-yellow bold italic";
        style_root = "purple bold italic";
        format = "[⭘ $user]($style) ";
        disabled = false;
        show_always = false;
      };

      sudo = {
        format = "[$symbol]($style)";
        style = "bold italic bright-purple";
        symbol = "⋈┈";
        disabled = false;
      };

      # 路径与目录
      directory = {
        home_symbol = "⌂";
        truncation_length = 2;
        truncation_symbol = "□ ";
        read_only = " ◈";
        use_os_path_sep = true;
        style = "italic blue";
        format = "[$path]($style)[$read_only]($read_only_style)";
        repo_root_style = "bold blue";
        repo_root_format = "[$before_root_path]($before_repo_root_style)[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) [△](bold bright-blue)";
      };

      # 任务与持续时间
      cmd_duration.format = "[◄ $duration ](italic white)";
      jobs = {
        format = "[$symbol$number]($style) ";
        style = "white";
        symbol = "[▶](blue italic)";
      };

      # 网络与系统
      localip = {
        ssh_only = true;
        format = " ◯[$localipv4](bold magenta)";
        disabled = false;
      };

      time = {
        disabled = false;
        format = "[ $time]($style)";
        time_format = "%R";
        utc_time_offset = "local";
        style = "italic dimmed white";
      };

      # 电池状态（包含列表定义）
      battery = {
        format = "[ $percentage $symbol]($style)";
        full_symbol = "█";
        charging_symbol = "[↑](italic bold green)";
        discharging_symbol = "↓";
        unknown_symbol = "░";
        empty_symbol = "▃";
        display = [
          { threshold = 20; style = "italic bold red"; }
          { threshold = 60; style = "italic dimmed bright-purple"; }
          { threshold = 70; style = "italic dimmed yellow"; }
        ];
      };

      # Git 深度配置
      git_branch = {
        format = " [$branch(:$remote_branch)]($style)";
        symbol = "[△](bold italic bright-blue)";
        style = "italic bright-blue";
        truncation_symbol = "⋯";
        truncation_length = 11;
        ignore_branches = [ "main" "master" ];
        only_attached = true;
      };

      git_metrics = {
        format = "([▴$added]($added_style))([▿$deleted]($deleted_style))";
        added_style = "italic dimmed green";
        deleted_style = "italic dimmed red";
        ignore_submodules = true;
        disabled = false;
      };

      git_status = {
        style = "bold italic bright-blue";
        format = "([⎪$ahead_behind$staged$modified$untracked$renamed$deleted$conflicted$stashed⎥]($style))";
        conflicted = "[◪◦](italic bright-magenta)";
        ahead = "[▴│[$\{count}](bold white)│](italic green)";
        behind = "[▿│[$\{count}](bold white)│](italic red)";
        diverged = "[◇ ▴┤[$\{ahead_count}](regular white)│▿┤[$\{behind_count}](regular white)│](italic bright-magenta)";
        untracked = "[◌◦](italic bright-yellow)";
        stashed = "[◃◈](italic white)";
        modified = "[●◦](italic yellow)";
        staged = "[▪┤[$count](bold white)│](italic bright-cyan)";
        renamed = "[◎◦](italic bright-blue)";
        deleted = "[✕](italic red)";
      };

      # 语言开发环境
      nix_shell = {
        style = "bold italic dimmed blue";
        symbol = "✶";
        format = "[$symbol nix⎪$state⎪]($style) [$name](italic dimmed white)";
        impure_msg = "[⌽](bold dimmed red)";
        pure_msg = "[⌾](bold dimmed green)";
        unknown_msg = "[◌](bold dimmed yellow)";
      };

      python = {
        format = " [py](italic) [$\{symbol}$\{version}]($style)";
        symbol = "[⌉](bold bright-blue)⌊ ";
        version_format = "$\{raw}";
        style = "bold bright-yellow";
      };

      lua = {
        format = " [lua](italic) [$\{symbol}$\{version}]($style)";
        version_format = "$\{raw}";
        symbol = "⨀ ";
        style = "bold bright-yellow";
      };

      rust = {
        format = " [rs](italic) [$symbol$version]($style)";
        symbol = "⊃ ";
        version_format = "$\{raw}";
        style = "bold red";
      };

      nodejs = {
        format = " [node](italic) [◫ ($version)](bold bright-green)";
        version_format = "$\{raw}";
        detect_files = [ "package-lock.json" "yarn.lock" ];
        detect_folders = [ "node_modules" ];
      };

      # 内存与通用
      memory_usage = {
        symbol = "▪▫▪ ";
        format = " mem [$\{ram}( $\{swap})]($style)";
      };

      package = {
        format = " [pkg](italic dimmed) [$symbol$version]($style)";
        version_format = "$\{raw}";
        symbol = "◨ ";
        style = "dimmed yellow italic bold";
      };
    };
  };
}
