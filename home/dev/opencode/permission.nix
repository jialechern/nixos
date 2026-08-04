{
  read = "allow";
  grep = "allow";
  glob = "allow";
  list = "allow";
  lsp = "allow";
  edit = "ask";
  bash = "ask";
  webfetch = "allow";
  # 联网搜索 (需在启动时注入 OPENCODE_ENABLE_EXA=1, 见 opencode.nix wrapper)
  websearch = "allow";
  skill = "allow";
  # 在执行过程中向用户提问
  question = "allow";
  # 在编码会话中管理待办事项列表
  todowrite = "allow";
}
