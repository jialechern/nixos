{
    build = {
        mode = "primary";
        model = "volcengine/doubao-seed-2-0-code-preview-260215";
        prompt = "{file =./prompts/build.txt}";
        tools = {
            write = true;
            edit = true;
            bash = true;
        };
    };

    plan = {
        mode = "primary";
        model = "volcengine/doubao-seed-2-0-lite-260215";
        tools = {
            write = false;
            edit = false;
            bash = false;
        };
    };

    code-reviewer = {
        description = "Reviews code for best practices and potential issues";
        mode = "subagent";
        model = "volcengine/doubao-seed-2-0-code-preview-260215";
        prompt = "You are a code reviewer. Focus on security; performance; and maintainability.";
        tools = {
            write = false;
            edit = false;
        };
    };
}
