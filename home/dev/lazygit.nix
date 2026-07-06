{ config, pkgs, ... }:

{
  programs.lazygit = {
    enable = true;

    # settings 字段的内容会 1:1 转换为 lazygit 的 config.yml
    settings = {
      # 与Lazygit UI相关的配置
      gui = {
        # 参见 https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#custom-author-color
        authorColors = { };

        # 参见 https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#custom-branch-color
        branchColorPatterns = { };

        # 文件名和文件扩展名的自定义图标
        customIcons = {
          filenames = { };
          extensions = { };
        };

        scrollHeight = 2; # 主窗口滚动时每次滚动的行数
        scrollPastBottom = true; # 如果为true, 允许滚动过主窗口内容的底部
        scrollOffMargin = 2;
        scrollOffBehavior = "margin"; # 选项: 'margin'(默认)| 'jump'
        tabWidth = 4; # 每个制表符的空格数
        mouseEvents = true; # 如果为true, 捕获鼠标事件

        # 跳过确认警告类设置
        skipAmendWarning = false;
        skipDiscardChangeWarning = false;
        skipStashWarning = false;
        skipNoStagedFilesWarning = false;
        skipRewordInEditorWarning = false;
        skipSwitchWorktreeOnCheckoutWarning = false;

        sidePanelWidth = 0.3333; # 左侧区域占总屏幕宽度的比例
        expandFocusedSidePanel = false;
        mainPanelSplitMode = "flexible";
        enlargedSideViewLocation = "left";
        wrapLinesInStagingView = true;
        useHunkModeInStagingView = true;
        language = "auto"; # 选项: 'auto'(默认)| 'zh-CN' 等

        timeFormat = "02 Jan 06";
        shortTimeFormat = "3:04PM";

        # 与颜色和样式相关的配置
        theme = {
          activeBorderColor = [ "green" "bold" ];
          inactiveBorderColor = [ "default" ];
          searchingActiveBorderColor = [ "cyan" "bold" ];
          optionsTextColor = [ "blue" ];
          selectedLineBgColor = [ "blue" ];
          inactiveViewSelectedLineBgColor = [ "bold" ];
          cherryPickedCommitFgColor = [ "blue" ];
          cherryPickedCommitBgColor = [ "cyan" ];
          markedBaseCommitFgColor = [ "blue" ];
          markedBaseCommitBgColor = [ "yellow" ];
          unstagedChangesColor = [ "red" ];
          defaultFgColor = [ "default" ];
        };

        commitLength.show = true;
        showListFooter = true;
        showFileTree = true;
        showRootItemInFileTree = true;
        showNumstatInFilesView = false;
        showRandomTip = true;
        showCommandLog = true;
        showBottomLine = true;
        showPanelJumps = true;
        nerdFontsVersion = ""; # 使用的Nerd字体版本 (如 "3")
        showFileIcons = true;

        commitAuthorShortLength = 2;
        commitAuthorLongLength = 17;
        commitHashLength = 8;
        showBranchCommitHash = false;
        showDivergenceFromBaseBranch = "none";
        commandLogSize = 8;
        splitDiff = "auto";
        screenMode = "normal";
        border = "rounded";
        animateExplosion = true;
        portraitMode = "auto";
        filterMode = "substring";

        spinner = {
          frames = [ "|" "/" "-" "\\" ];
          rate = 50;
        };

        statusPanelView = "dashboard";
        switchToFilesAfterStashPop = true;
        switchToFilesAfterStashApply = true;
        switchTabsWithPanelJumpKeys = false;
      };

      # 与Git相关的配置
      git = {
        pagers = [ ];
        commit = {
          signOff = false;
          autoWrapCommitMessage = true;
          autoWrapWidth = 72;
        };
        merging = {
          manualCommit = false;
          args = "";
          squashMergeMessage = "Squash merge {{selectedRef}} into {{currentBranch}}";
        };
        mainBranches = [ "master" "main" ];
        skipHookPrefix = "WIP";
        autoFetch = true;
        autoRefresh = true;
        autoForwardBranches = "onlyMainBranches";
        fetchAll = true;
        autoStageResolvedConflicts = true;
        branchLogCmd = "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium {{branchName}} --";
        allBranchesLogCmds = [
          "git log --graph --all --color=always --abbrev-commit --decorate --date=relative --pretty=medium"
        ];
        ignoreWhitespaceInDiffView = false;
        diffContextSize = 3;
        renameSimilarityThreshold = 50;
        overrideGpg = false;
        disableForcePushing = false;
        log = {
          order = "topo-order";
          showGraph = "always";
          showWholeGraph = false;
        };
        localBranchSortOrder = "date";
        remoteBranchSortOrder = "date";
        truncateCopiedCommitHashesTo = 12;
      };

      update = {
        method = "prompt";
        days = 14;
      };

      refresher = {
        refreshInterval = 10;
        fetchInterval = 60;
      };

      confirmOnQuit = false;
      quitOnTopLevelReturn = false;

      # 与外部操作相关的配置
      os = {
        edit = "";
        editAtLine = "";
        editAtLineAndWait = "";
        editInTerminal = false;
        openDirInEditor = "";
        editPreset = "";
        open = "";
        openLink = "";
        copyToClipboardCmd = "";
        readFromClipboardCmd = "";
        shellFunctionsFile = "";
      };

      disableStartupPopups = false;
      customCommands = [ ];
      services = { };
      notARepository = "prompt";
      promptToReturnFromSubprocess = true;

      # 键绑定配置 (保持与你原文件完全一致)
      keybinding = {
        universal = {
          quit = "<c-q>";
          suspendApp = "<c-z>";
          return = "<esc>";
          quitWithoutChangingDirectory = "Q";
          togglePanel = "<tab>";
          prevItem = "<up>";
          nextItem = "<down>";
          prevItem-alt = "k";
          nextItem-alt = "j";
          prevPage = ",";
          nextPage = ".";
          scrollLeft = "H";
          scrollRight = "L";
          gotoTop = "<";
          gotoBottom = ">";
          toggleRangeSelect = "v";
          prevBlock = "<left>";
          nextBlock = "<right>";
          prevBlock-alt = "<c-p>";
          nextBlock-alt = "<c-n>";
          jumpToBlock = [ "1" "2" "3" "4" "5" ];
          focusMainView = "0";
          nextMatch = "n";
          prevMatch = "N";
          startSearch = "/";
          optionMenu-alt1 = "?";
          select = "<c-c>";
          goInto = "<enter>";
          confirm = "<enter>";
          confirmMenu = "<enter>";
          confirmInEditor = "<a-enter>";
          remove = "d";
          new = "n";
          edit = "e";
          openFile = "o";
          scrollUpMain = "<pgup>";
          scrollDownMain = "<pgdown>";
          scrollUpMain-alt1 = "K";
          scrollDownMain-alt1 = "J";
          scrollUpMain-alt2 = "<c-u>";
          scrollDownMain-alt2 = "<c-d>";
          executeShellCommand = ":";
          createRebaseOptionsMenu = "m";
          pushFiles = "P";
          pullFiles = "p";
          refresh = "R";
          createPatchOptionsMenu = "<c-/>";
          nextTab = "]";
          prevTab = "[";
          nextScreenMode = "+";
          prevScreenMode = "_";
          cyclePagers = "|";
          undo = "z";
          redo = "Z";
          filteringMenu = "<c-s>";
          diffingMenu = "W";
          copyToClipboard = "<c-o>";
          openRecentRepos = "<c-r>";
          submitEditorText = "<enter>";
          extrasMenu = "@";
          toggleWhitespaceInDiffView = "<c-w>";
          increaseContextInDiffView = "}";
          decreaseContextInDiffView = "{";
          openDiffTool = "<c-t>";
        };
        status = {
          checkForUpdate = "u";
          recentRepos = "<enter>";
          allBranchesLogGraph = "a";
        };
        files = {
          commitChanges = "c";
          commitChangesWithoutHook = "w";
          amendLastCommit = "A";
          commitChangesWithEditor = "C";
          confirmDiscard = "x";
          ignoreFile = "i";
          refreshFiles = "r";
          stashAllChanges = "s";
          viewStashOptions = "S";
          toggleStagedAll = "a";
          viewResetOptions = "D";
          fetch = "f";
          toggleTreeView = "`";
          openMergeOptions = "M";
          copyFileInfoToClipboard = "y";
          collapseAll = "-";
          expandAll = "=";
        };
        branches = {
          createPullRequest = "o";
          viewPullRequestOptions = "O";
          copyPullRequestURL = "<c-y>";
          checkoutBranchByName = "c";
          forceCheckoutBranch = "F";
          checkoutPreviousBranch = "-";
          rebaseBranch = "r";
          renameBranch = "R";
          mergeIntoCurrentBranch = "M";
          moveCommitsToNewBranch = "N";
          viewGitFlowOptions = "i";
          fastForward = "f";
          createTag = "T";
          pushTag = "P";
          setUpstream = "u";
          fetchRemote = "f";
          addForkRemote = "F";
          sortOrder = "s";
        };
        commits = {
          squashDown = "s";
          renameCommit = "r";
          renameCommitWithEditor = "R";
          viewResetOptions = "g";
          markCommitAsFixup = "f";
          createFixupCommit = "F";
          squashAboveCommits = "S";
          moveDownCommit = "<c-j>";
          moveUpCommit = "<c-k>";
          amendToCommit = "A";
          resetCommitAuthor = "a";
          pickCommit = "p";
          revertCommit = "t";
          cherryPickCopy = "C";
          pasteCommits = "V";
          markCommitAsBaseForRebase = "B";
          tagCommit = "T";
          checkoutCommit = "<c-c>";
          resetCherryPick = "<ctrl+shift+r>";
          copyCommitAttributeToClipboard = "y";
          openLogMenu = "<c-l>";
          openInBrowser = "o";
          viewBisectOptions = "b";
          startInteractiveRebase = "i";
          selectCommitsOfCurrentBranch = "*";
        };
        stash = {
          popStash = "g";
          renameStash = "r";
        };
        main = {
          toggleSelectHunk = "a";
          pickBothHunks = "b";
          editSelectHunk = "E";
        };
        submodules = {
          init = "i";
          update = "u";
          bulkMenu = "b";
        };
      };
    };
  };
}
