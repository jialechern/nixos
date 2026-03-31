{
    prettier = {
        command = [ "npx" "prettier" "--write" "$FILE" ];
        environment = {
            NODE_ENV = "development";
        };
        extensions = [ ".js" ".ts" ".jsx" ".tsx" ];
    };

    custom-markdown-formatter = {
        command = [ "deno" "fmt" "$FILE" ];
        extensions = [".md"];
    };
}
