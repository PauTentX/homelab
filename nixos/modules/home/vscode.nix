{ config, pkgs, inputs, lib, ... }:

{
  # Forcer VSCode en Français via un script d'activation (car argv.json ne peut pas être en lecture seule)
  home.activation.vscodeLanguage = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -f $HOME/.vscode/argv.json ]; then
      ${pkgs.gnused}/bin/sed -i '/"locale":/d' $HOME/.vscode/argv.json
      ${pkgs.gnused}/bin/sed -i '/^{/a \  "locale": "fr",' $HOME/.vscode/argv.json
    else
      mkdir -p $HOME/.vscode
      echo '{"locale": "fr"}' > $HOME/.vscode/argv.json
    fi
  '';

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
    
    # Configuration du Profil Par Défaut
    profiles.default = {
      # Extensions officielles gérées par Nix
      extensions = with pkgs.vscode-extensions; [
        # 🇫🇷 Traduction Française
        ms-ceintl.vscode-language-pack-fr

        # 🤖 GitHub Copilot
        github.copilot
        github.copilot-chat

        # 🎨 Thème & Esthétique
        catppuccin.catppuccin-vsc
        pkief.material-icon-theme

        # 🦀 Rust
        rust-lang.rust-analyzer
        fill-labs.dependi
        tamasfe.even-better-toml

        # ⚙️ C / C++
        llvm-vs-code-extensions.vscode-clangd
        twxs.cmake

        # 🐍 Python
        ms-python.python
        ms-python.vscode-pylance
        ms-vscode.powershell
        charliermarsh.ruff

        # 🟢 Node.js & Web
        esbenp.prettier-vscode
        bradlc.vscode-tailwindcss
        dbaeumer.vscode-eslint

        # 🛠️ Utilitaires
        eamodio.gitlens
        usernamehw.errorlens
        ms-vsliveshare.vsliveshare
        jnoortheen.nix-ide
        mkhl.direnv
      ];

      # Paramètres Utilisateur VSCode
      userSettings = {
        # 🤖 GitHub Copilot
        "github.copilot.enable" = { "*" = true; };
        "github.copilot.editor.enableAutoCompletions" = true;
        "chat.commandCenter.enabled" = true;
        "github.copilot.chat.localeOverride" = "fr";

        # 🎨 Apparence (Stylix gère le thème et la police, on garde juste l'iconTheme)
        "workbench.iconTheme" = "material-icon-theme";
        "editor.fontLigatures" = true;
        
        # ⚡ Comportement & UI
        "window.titleBarStyle" = "custom";
        "editor.formatOnSave" = true;
        "editor.minimap.enabled" = false;
        "editor.smoothScrolling" = true;
        "editor.cursorSmoothCaretAnimation" = "on";
        
        # 🌐 Domaines de confiance (Fix erreur schéma Catppuccin)
        "json.schemaDownload.enable" = true;
        "json.schemaDownload.trustedDomains" = {
          "https://raw.githubusercontent.com" = true;
        };
        
        # 🦀 Configuration Rust
        "rust-analyzer.check.command" = "clippy";

        # 🐚 Configuration PowerShell
        "powershell.powerShellAdditionalExePaths" = {
          "NixOS" = "${pkgs.powershell}/bin/pwsh";
        };
        "powershell.powerShellDefaultVersion" = "NixOS";
        
        # ⚙️ Configuration C++ (Clangd)
        "clangd.arguments" = [
          "--background-index"
          "--clang-tidy"
          "--header-insertion=iwyu"
          "--completion-style=detailed"
          "--function-arg-placeholders"
          "--fallback-style=llvm"
        ];
        
        # 🐍 Configuration Python (Ruff + Pylance)
        "[python]" = {
          "editor.defaultFormatter" = "charliermarsh.ruff";
          "editor.formatOnSave" = true;
        };
        "python.languageServer" = "Pylance";
        "python.analysis.typeCheckingMode" = "basic";

        # ❄️ Configuration Nix
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        "nix.serverSettings".nixd.formatting.command = [ "nixpkgs-fmt" ];
      };
    };
  };
}
