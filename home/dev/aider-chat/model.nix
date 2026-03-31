{ config, pkgs, ... }:

let
  # =========================================================
  # 统一维护的模型名称
  # 只在这里改, 下面的 metadata 和 settings 会一起跟着变
  # =========================================================
  aiderModels = {
    doubaoCode = "openai/doubao-seed-code-preview-251028";
    deepseekV3 = "openai/deepseek-v3-2-251201";
    seed18 = "openai/doubao-seed-1-8-251228";
    seed16Flash = "openai/doubao-seed-1.6-flash-250828";
  };
in
{
    # =========================================================
    # 生成 `~/.config/aider/model.metadata.json`
    # =========================================================
    xdg.configFile."aider/model.metadata.json".text = builtins.toJSON {
        "${aiderModels.doubaoCode}" = {
            max_tokens = 256000;
            max_input_tokens = 256000;
            max_output_tokens = 128000;
            litellm_provider = "openai";
            mode = "chat";
        };

        "${aiderModels.deepseekV3}" = {
            max_tokens = 128000;
            litellm_provider = "openai";
            mode = "chat";
        };

        "${aiderModels.seed18}" = {
            max_tokens = 256000;
            litellm_provider = "openai";
            mode = "chat";
        };

        "${aiderModels.seed16Flash}" = {
            max_tokens = 256000;
            litellm_provider = "openai";
            mode = "chat";
        };
    };

    # =========================================================
    # 生成 `~/.config/aider/model.settings.yml`
    # =========================================================
    xdg.configFile."aider/model.settings.yml".text = ''
    - name: ${aiderModels.doubaoCode}
      edit_format: diff
      use_repo_map: true

    - name: ${aiderModels.deepseekV3}
      edit_format: diff
      use_repo_map: true

    - name: ${aiderModels.seed18}
      edit_format: diff
      use_repo_map: true

    - name: ${aiderModels.seed16Flash}
      edit_format: whole
      use_repo_map: false
    '';
}
