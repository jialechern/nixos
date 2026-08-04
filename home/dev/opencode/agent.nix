{
  build = {
    mode = "primary";
    model = "deepseek/deepseek-v4-flash";
    prompt = "{file =./prompts/build.txt}";
    tools = {
      write = true;
      edit = true;
      bash = true;
    };
  };

  plan = {
    mode = "primary";
    model = "deepseek/deepseek-v4-flash";
    tools = {
      write = false;
      edit = false;
      bash = false;
    };
  };

  code-reviewer = {
    description = "Reviews code for best practices and potential issues";
    mode = "subagent";
    model = "deepseek/deepseek-v4-pro";
    prompt = "You are a code reviewer. Focus on security; performance; and maintainability.";
    tools = {
      write = false;
      edit = false;
    };
  };
}
