{
    build = {
        mode = "primary";
        model = "volcengine/doubao-seed-1-8-251228";
        prompt = "{file =./prompts/build.txt}";
        tools = {
            write = true;
            edit = true;
            bash = true;
        };
    };

    plan = {
        mode = "primary";
        model = "volcengine/doubao-seed-1-6-flash-250828";
        tools = {
            write = false;
            edit = false;
            bash = false;
        };
    };

    code-reviewer = {
        description = "Reviews code for best practices and potential issues";
        mode = "subagent";
        model = "volcengine/doubao-seed-code-preview-251028";
        prompt = "You are a code reviewer. Focus on security; performance; and maintainability.";
        tools = {
            write = false;
            edit = false;
        };
    };
}
