{
  build = {
    mode = "primary";
    model = "opencode/minimax-m2.5-free";
    prompt = "{file =./prompts/build.txt}";
    tools = {
      write = true;
      edit = true;
      bash = true;
    };
  };

  plan = {
    mode = "primary";
    model = "opencode/minimax-m2.5-free";
    tools = {
      write = false;
      edit = false;
      bash = false;
    };
  };

  code-reviewer = {
    description = "Reviews code for best practices and potential issues";
    mode = "subagent";
    model = "opencode/minimax-m2.5-free";
    prompt = "You are a code reviewer. Focus on security; performance; and maintainability.";
    tools = {
      write = false;
      edit = false;
    };
  };
}
