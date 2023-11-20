{nixvim, ...}: self: super: {
  customPlugins = {
    # reddit user bin-c found this link for me,
    # and I adapted the funtion to my overlay
    # https://github.com/NixOS/nixpkgs/blob/44a691ec0cdcd229bffdea17455c833f409d274a/pkgs/applications/editors/vim/plugins/overrides.nix#L746
    markdown-preview-nvim = let
      nodeDep = super.yarn2nix-moretea.mkYarnModules rec {
        inherit (super.vimPlugins.markdown-preview-nvim) pname version;
        packageJSON = "${super.vimPlugins.markdown-preview-nvim.src}/package.json";
        yarnLock = "${super.vimPlugins.markdown-preview-nvim.src}/yarn.lock";
        offlineCache = super.fetchYarnDeps {
          inherit yarnLock;
          hash = "sha256-kzc9jm6d9PJ07yiWfIOwqxOTAAydTpaLXVK6sEWM8gg=";
        };
      };
    in
      super.vimPlugins.markdown-preview-nvim.overrideAttrs {
        postInstall = ''
          ln -s ${nodeDep}/node_modules $out/app
        '';

        nativeBuildInputs = [super.nodejs];
        doInstallCheck = true;
        installCheckPhase = ''
          node $out/app/index.js --version
        '';
      };
  };
}
