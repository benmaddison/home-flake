{ self }: { config, options, pkgs, lib, ... }:

let
  cfg = config.local.sway;
  colors = config.local.colorscheme.hashHex;
in
{
  options.local.sway = {
    enable = lib.mkEnableOption "enable sway wm";
  };

  config = lib.mkIf cfg.enable {
    services.kanshi = {
      enable = true;
      profiles = {
        mobile.outputs = [];
      };
    };
    wayland.windowManager.sway = {
      enable = true;
      config = {
        bars = [
          {
            inherit (config.wayland.windowManager.sway.config) fonts;
            statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${config.xdg.configHome}/i3status-rust/config-default.toml";
            colors = with colors; {
              inherit (primary) background;
              separator = bright.black;
              statusline = bright.black;
              focusedWorkspace = {
                background = normal.blue;
                border = bright.blue;
                text = bright.white;
              };
              activeWorkspace = with bright; {
                background = black;
                border = black;
                text = white;
              };
              inactiveWorkspace = with normal; {
                background = black;
                border = black;
                text = white;
              };
              urgentWorkspace = with bright; {
                background = black;
                border = red;
                text = red;
              };
              bindingMode = with bright; {
                background = black;
                border = yellow;
                text = yellow;
              };
            };
          }
        ];
        colors = with colors; let
          default = {
            inherit (primary) background;
            text = primary.foreground;
            border = normal.black;
            childBorder = normal.black;
            indicator = normal.blue;
          }; in
        {
          inherit (primary) background;
          focused = default // { childBorder = bright.black; };
          focusedInactive = default;
          unfocused = default;
          urgent = default // { childBorder = normal.red; };
          placeholder = default;
        };
        defaultWorkspace = "workspace number 1";
        floating.criteria = [ ];
        gaps.inner = 6;
        modifier = "Mod4";
        menu = with config.programs.rofi; lib.mkIf enable "${package}/bin/rofi -show drun";
        startup = [
          { command = "${pkgs.networkmanagerapplet}/bin/nm-applet"; }
        ];
        keybindings =
          let
            cfg = config.wayland.windowManager.sway.config;
            mod = cfg.modifier;
            alt = "Mod1";

            # TODO: "Ctrl+[0..9] -> workspaces 11 - 20
            workspaces = [ 1 2 3 4 5 6 7 8 9 10 ];
            workspaceBindings = mod: cmd:
              let
                key = ws: toString (lib.mod ws 10);
                binding = mod: cmd: ws:
                  lib.nameValuePair "${mod}+${key ws}" "${cmd ws}";
              in
              lib.listToAttrs (map (binding mod cmd) workspaces);
            workspaceNum = ws: "workspace number ${toString ws}";

            navBindings = mod: cmd:
              let
                directions =
                  { "h" = "left"; "j" = "down"; "k" = "up"; "l" = "right"; };
                binding = mod: cmd: key: direction:
                  lib.nameValuePair "${mod}+${key}" "${cmd direction}";
              in
              lib.mapAttrs' (binding mod cmd) directions;

            focusWorkspace = workspaceNum;
            moveContainerToWorkspace = ws:
              "move container to ${workspaceNum ws}";
            followContainerToWorkspace = ws:
              "${moveContainerToWorkspace ws}; ${focusWorkspace ws}";
            moveFocus = direction: "focus ${direction}";
            moveContainer = direction: "move ${direction}";
            moveWorkspaceToOutput = direction:
              "move workspace to output ${direction}";

            # audioBindings =
            #   let
            #     pactl-sink = cmd: arg:
            #       let pactl = "${osConfig.hardware.pulseaudio.package}/bin/pactl";
            #       in "exec ${pactl} set-sink-${cmd} @DEFAULT_SINK@ ${arg}";
            #   in
            #   lib.optionalAttrs osConfig.hardware.pulseaudio.enable
            #     {
            #       "XF86AudioLowerVolume" = pactl-sink "volume" "-10%";
            #       "XF86AudioRaiseVolume" = pactl-sink "volume" "+10%";
            #       "XF86AudioMute" = pactl-sink "mute" "toggle";
            #     };
            backlightBindings =
              let light = args: "exec ${pkgs.light}/bin/light ${args}"; in
              {
                "XF86MonBrightnessDown" = light "-U 10";
                "XF86MonBrightnessUp" = light "-A 10";
              };
          in
          workspaceBindings "${mod}" focusWorkspace //
          workspaceBindings "${mod}+Shift" moveContainerToWorkspace //
          workspaceBindings "${mod}+${alt}" followContainerToWorkspace //
          navBindings "${mod}" moveFocus //
          navBindings "${mod}+Shift" moveContainer //
          navBindings "${mod}+Ctrl" moveWorkspaceToOutput //
          # audioBindings //
          backlightBindings //
          {
            "${mod}+Return" = "exec ${cfg.terminal}";
            # TODO: "${mod}+Shift+Return" -> launch browser
            "${mod}+space" = "exec ${cfg.menu}";
            # TODO: "${mod}+Shift+space" -> cmd launcher
            # TODO: "${mod}+Ctrl+space" -> window launcher
            # TODO: "${mod}+${alt}+space" -> file launcher
            # TODO: "${mod}+Shift+question" -> help pop-up
            # TODO: "${mod}+equal" -> calulator
            # TODO: "${mod}+z" -> fuzzy finder
            "${mod}+q" = "[con_id=\"__focused__\"] kill";

            "${mod}+Tab" = "workspace next";
            "${mod}+Shift+Tab" = "workspace previous";

            # TODO: scratchpad move/show

            "${mod}+backslash" = "[urgent=oldest] focus";

            "${mod}+BackSpace" = "split toggle";
            "${mod}+f" = "fullscreen toggle";
            "${mod}+t" = "layout toggle tabbed splith splitv";
            "${mod}+Shift+f" = "floating toggle";
            "${mod}+Shift+t" = "focus mode_toggle";

            "${mod}+Escape" = "exec systemctl start physlock.service";
            "${mod}+Shift+c" = "reload";
            "${mod}+Shift+r" = "restart";
            "${mod}+Shift+q" = "exec i3-msg exit";

            # TODO: "${mod}+grave -> show tray
            # TODO: "${mod}+Shift+v -> vpn toggle
            # TODO: "${mod}+n -> notifications
            # TODO: "${mod}+Shift+n -> file manager

            "${mod}+r" = "mode resize";
          };
      };
    };
  };
}
