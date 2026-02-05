{ self }: { config, options, pkgs, lib, ... }:

let
  cfg = config.local.mail;
  accounts = lib.attrValues cfg;
  move-mail = with pkgs; writeShellScriptBin "move-mail" /* bash */ ''
    set -euo pipefail

    export PATH="${lib.makeBinPath [ coreutils hostname util-linux fd ]}"

    usage() {
        echo "usage:"
        echo "$0 -s <source-file> -d <dest-maildir>"
    }

    fail() {
        echo "error: $1"
        usage
        exit 1
    }

    while getopts 's:d:h' arg; do
        case "$arg" in
            s)  src_path="$OPTARG";;
            d)  dst_dir="$OPTARG/cur";;
            h)  usage && exit 0;;
            *)  fail "invalid option";;
        esac
    done
    shift $(( OPTIND - 1 ))

    if [ ! -f "$src_path" ]; then
        fail "source file '$src_path' does not exist"
    fi

    if [ ! -d "$dst_dir" ]; then
        fail "destination directory '$dest_dir' does not exist"
    fi

    hostname=$(hostname -s)
    flags=$(basename "$src_path" | cut -d':' -f2 -s)

    i=0
    max_iter=100
    while true; do
        uuid="$(uuidgen -r)"
        unique="$uuid.$hostname"
        if ! fd --search-path "$dst_dir" --has-results -- "^$unique"; then
            break
        fi
        if [ "$i" -gt "$max_iter" ]; then
            fail "maximum number of iterations exceeded"
        fi
        let i++
    done

    dst_path="$dst_dir/$unique:$flags"
    echo "moving $src_path to $dst_path"
    mv "$src_path" "$dst_path"

    exit 0
  '';
  notmuch-move = with pkgs; writeShellScriptBin "notmuch-move" /* bash */ ''
    set -euo pipefail

    export PATH="${lib.makeBinPath [ coreutils notmuch findutils move-mail ]}"

    usage() {
        echo "usage:"
        echo "$0 [-n] [-r <tag> ...] -d <destination-mailbox> [--] <search-terms>"
        echo ""
        echo "-d <destination-mailbox>  Destination maildir folder relative"
        echo "                          to `database.mailroot`."
        echo "-n                        Run `notmuch new --no-hooks` before"
        echo "                          moving."
        echo "-r <tag> ...              Remove <tag> from matched messages"
        echo "                          after moving files."
        echo "-h                        Print usage details."
        echo "<search-terms>            Search terms to pass to `notmuch search`."
        echo ""
    }

    fail() {
        echo "error: $1"
        usage
        exit 1
    }

    update_paths() {
        notmuch new --no-hooks --quiet
    }

    unset pre_new
    remove_tags=""

    while getopts 'd:nr:h-' arg; do
        case "$arg" in
            d)  dst_maildir="$OPTARG";;
            n)  pre_new=1;;
            r)  for tag in $OPTARG; do
                    remove_tags+=" -$tag"
                done;;
            h)  usage && exit 0;;
            -)  break;;
            *)  fail "invalid option";;
        esac
    done
    shift $(( OPTIND - 1 ))

    search_terms=$@

    root="$(notmuch config get database.mailroot)"
    if [ -z "$root" ]; then
        root="$(notmuch config get database.path)"
    fi
    if [ -z "$root" ]; then
        fail "could not determine root maildir store"
    fi

    dst_dir="$root/$dst_maildir"
    if [ ! -d "$dst_dir/cur" ]; then
        fail "destination directory '$dst_dir' is not a valid maildir"
    fi

    if [ -v pre_new ]; then update_paths; fi

    notmuch search \
        --output=files \
        --format=text0 \
        -- "$search_terms" \
    | xargs \
        --null \
        --max-procs="$(nproc)" \
        --no-run-if-empty \
        -I {} \
        move-mail -d "$dst_dir" -s "{}"

    update_paths

    if [ -n "$remove_tags" ]; then
        notmuch tag $remove_tags -- "folder:$dst_maildir and ($search_terms)"
    fi

    exit 0
  '';
  notmuch-move-all = pkgs.writeShellScriptBin "notmuch-move-all" /* bash */ ''
    ${lib.concatStrings (lib.concatMap (account:
      lib.mapAttrsToList (tag: folder: /* bash */ ''
        ${notmuch-move}/bin/notmuch-move \
          -r "move/${tag}" \
          -d "${account.name}/${folder}" \
          -- tag:move/${tag} and tag:account/${account.name}
      '') (account.folders // account.extraFolders)) accounts)}
  '';
in
{
  options = {
    local.mail = lib.mkOption {
      type = with lib.types; attrsOf (submodule ({ name, ... }: {
        options =
          let
            accountOpts = options.accounts.email.accounts.type.getSubOptions [ ];
            wrap = name: args: self.lib.wrapOption accountOpts.${name} args;
          in
          {
            name = lib.mkOption {
              type = lib.types.str;
              default = name;
            };
            address = wrap "address" { };
            aliases = wrap "aliases" { };
            flavor = wrap "flavor" { };
            folders = wrap "folders" { };
            primary = wrap "primary" { };
            realName = wrap "realName" { default = "Ben Maddison"; };
            imap = wrap "imap" { };
            smtp = wrap "smtp" { };
            extraFolders = lib.mkOption {
              type = lib.types.submodule {
                freeformType = with lib.types; attrsOf str;
                options =
                  let
                    folderOpt = default: lib.mkOption { inherit default; };
                  in
                  {
                    archive = folderOpt "Archive";
                    spam = folderOpt "Spam";
                  };
              };
              default = { };
            };
            oauth2 = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            mbsyncPipelineDepth = lib.mkOption {
              type = with lib.types; nullOr int;
              default = null;
            };
          };
      }));
    };
  };

  config = lib.mkIf (cfg != { }) {

    accounts.email.maildirBasePath = "${config.xdg.dataHome}/mail";
    accounts.email.accounts =
      let
        mkEmailAccount = name: account: {
          inherit (account)
            address
            aliases
            flavor
            folders
            primary
            realName
            ;

          imap = lib.mkIf (account.imap != null) account.imap;
          smtp = lib.mkIf (account.smtp != null) account.smtp;

          passwordCommand =
            if account.oauth2 then
              "${self.packages.x86_64-linux.oauth2ms}/bin/oauth2ms"
              + lib.optionalString (config.local.gpg.enable) " -e ${account.address}"
            else
              "${pkgs.libsecret}/bin/secret-tool lookup mail ${name} address ${account.address}";
          userName = "${account.address}";

          notmuch.enable = true;

          msmtp = {
            enable = true;
            extraConfig.auth = lib.mkIf (account.oauth2) "xoauth2";
          };

          mbsync = {
            enable = true;
            create = "both";
            expunge = "both";
            patterns =
              lib.concatMap
                (f: [ "${f}" "${f}/*" ])
                (lib.attrValues (account.folders // account.extraFolders));
            extraConfig.channel.CopyArrivalDate = "yes";
            extraConfig.account.AuthMechs = lib.mkIf (account.oauth2) "XOAUTH2";
            extraConfig.account.PipelineDepth =
              lib.mkIf (account.mbsyncPipelineDepth != null) account.mbsyncPipelineDepth;
          };

        };
      in
      lib.mapAttrs mkEmailAccount cfg;

    home.packages = [ notmuch-move notmuch-move-all ];

    local.persistence.directories =
      lib.mkIf (builtins.any (a: a.oauth2) (lib.attrValues cfg)) [ ".config/oauth2ms" ];

    programs.notmuch = {
      enable = true;
      new.tags = [ "new" ];
      search.excludeTags = [ ];
      hooks.postNew =
        let
          tagAccount = account: ''
            +account/${account.name} -- folder:/^${account.name}\/.+/ and tag:new
          '';
        in
        ''
          ${pkgs.notmuch}/bin/notmuch tag --batch <<EOF

          ${lib.concatMapStrings tagAccount accounts}
          -new *

          EOF

          ${notmuch-move-all}/bin/notmuch-move-all
        '';
    };

    programs.msmtp.enable = true;

    programs.mbsync.enable = true;
    services.mbsync = {
      enable = true;
      frequency = "*:0/2";
      preExec = "${notmuch-move-all}/bin/notmuch-move-all";
      postExec = "${pkgs.notmuch}/bin/notmuch new";
    };
    systemd.user.services.mbsync.Service.Environment = [
      "SASL_PATH=${lib.concatStringsSep ":" [
        "${pkgs.cyrus_sasl.out}/lib/sasl2"
        "${self.packages.x86_64-linux.cyrus-sasl-xoauth2}/lib/sasl2"
      ]}"
    ];

    programs.neomutt.enable = true;
    xdg.configFile =
      let
        accountCfgPath = account: "neomutt/accounts/${account.name}";
        accountCfgs =
          let
            accountCfg = account: {
              "${accountCfgPath account}".text = with account; ''
                # account config for ${name}
                set from = "${address}"
                set real_name = "${realName}"
                set spool_file = "${folders.inbox}"
                set postponed = "+${name}/${folders.drafts}"
                set trash = "+${name}/${folders.trash}"
              '';
            };
          in
          lib.foldl' (a: b: a // b) { } (map accountCfg accounts);
        mainCfg =
          let
            cfgGpg = config.local.gpg;
            mailDir = "${config.accounts.email.maildirBasePath}";
            configDir = "${config.xdg.configHome}/neomutt";
            cacheDir = "${config.xdg.cacheHome}/neomutt";
            runtimeDir = "$XDG_RUNTIME_DIR/neomutt";
            primaryAccount = lib.head (lib.filter (a: a.primary) accounts);
            folders = account: account.folders // account.extraFolders;
            mailbox =
              let
                virtual = [ "inbox" "archive" "spam" "trash" ];
              in
              account: tag: folder:
                if builtins.elem tag virtual then ''
                  virtual-mailboxes "${folder}" "notmuch://?query=folder:\"${account.name}/${folder}\""
                '' else ''
                  mailboxes "+${account.name}/${folder}"
                '';
            mailboxes = account: [
              ''
                virtual-mailboxes "─[${account.name}]─" "notmuch://?query=tag:account/${account.name}"
              ''
            ] ++ lib.mapAttrsToList (mailbox account) (folders account);
            folderHook = account: ''
              folder-hook "${account.name}\." "source ${config.xdg.configHome}/${accountCfgPath account}"
            '';
          in
          {
            "neomutt/mailcap".text = with pkgs; /* mailcap */ ''
              text/html; ${w3m}/bin/w3m -dump -o -document_charset=%{charset} %s; nametemplate=%s.html; copiousoutput
              text/*; ${xdg-utils}/bin/xdg-open %s
              audio/*; ${xdg-utils}/bin/xdg-open %s
              image/*; ${xdg-utils}/bin/xdg-open %s
              application/*; ${xdg-utils}/bin/xdg-open %s
            '';
            "neomutt/neomuttrc".text = /* neomuttrc */ ''
              set header_cache = "${cacheDir}/headers"
              set message_cachedir = "${cacheDir}/bodies"
              #set tmpdir = "${runtimeDir}/tmp"
              set attach_save_dir = "${config.xdg.userDirs.extraConfig.XDG_ATTACH_DIR}"

              set mailcap_path = "${configDir}/mailcap"
              set signature = "${configDir}/signature"

              # mailboxes
              set folder = "${mailDir}"
              set nm_default_url = "notmuch://${mailDir}"
              ${lib.concatStrings (lib.concatMap mailboxes accounts)}
              ${lib.concatMapStrings folderHook accounts}
              source "${config.xdg.configHome}/${accountCfgPath primaryAccount}"

              # Basic Options --------------------------------------
              set wait_key = no        # shut up, mutt
              set mbox_type = Maildir  # mailbox type
              set timeout = 3          # idle time before scanning
              set mail_check = 0       # minimum time between scans
              unset move               # don't move messages
              unset record             # let server record sent items
              set delete = yes         # don't prompt before deleting
              set delete_untag         # untag on move or delete
              set quit                 # quit without prompting
              unset mark_old           # read/new is good enough for me
              set beep_new             # bell on new mails
              set pipe_decode          # strip headers and eval mimes when piping
              set thorough_search      # strip headers and eval mimes before searching
              set mail_check_stats     # get statistics for each mailbox

              ${lib.optionalString cfgGpg.enable ''
                # Crypto Options --------------------------------------
                set crypt_use_gpgme
                set crypt_use_pka = no
                set crypt_auto_pgp = yes
                ${lib.optionalString (cfgGpg.defaultSignKey != null) ''
                  set pgp_sign_as = "${cfgGpg.defaultSignKey}"
                  set crypt_autosign = yes
                ''}
                ${lib.optionalString (cfgGpg.defaultEncryptKey != null) ''
                  set pgp_default_key = "${cfgGpg.defaultEncryptKey}"
                  set crypt_auto_encrypt = no
                  set postpone_encrypt = yes
                  set pgp_self_encrypt = yes
                ''}
              ''}

              # Sidebar Options --------------------------------------
              set sidebar_visible = yes
              set sidebar_width   = 32
              set sidebar_component_depth = 0
              set sidebar_short_path
              set sidebar_delim_chars = "/"
              unset sidebar_folder_indent
              set sidebar_format = "%D%?F? [%F]?%* %?N?%N/?%?S?%S ?"
              set sidebar_divider_char = "┃"

              # Status Bar -----------------------------------------
              set status_chars  = " *%A"
              set status_format = "───[ folder: %f ]───[%r%m messages%?n? (%n new)?%?d? (%d to delete)?%?t? (%t tagged)? ]───%>─%?p?( %p postponed )?───"

              # Index View Options ---------------------------------
              set date_format = "%m/%d"
              index-format-hook  date        "~d<1w"                "%[%a %H:%M]"
              index-format-hook  date        "~d<1y"                "%[%a %d %b]"
              index-format-hook  date        "~A"                   "%[%d %b %Y]"
              index-format-hook  read        "~D"                   ""
              index-format-hook  read        "~Y \"move/archive\""  ""
              index-format-hook  read        "~U"                   ""
              index-format-hook  read        "~A"                   ""
              index-format-hook  flag        "~F"                   ""
              index-format-hook  flag        "~A"                   " "
              index-format-hook  tagged      "~T"                   ""
              index-format-hook  tagged      "~A"                   " "
              index-format-hook  reply       "~Q"                   ""
              index-format-hook  reply       "~A"                   " "
              index-format-hook  signed      "~g"                   ""
              index-format-hook  signed      "~A"                   " "
              index-format-hook  encrypt     "~G"                   ""
              index-format-hook  encrypt     "~A"                   " "
              index-format-hook  attachment  "~M application/*"     ""
              index-format-hook  attachment  "~A"                   " "
              index-format-hook  collapsed   "~v"                   ""
              index-format-hook  collapsed   "~A"                   " "
              set index_format = "%4C %@read@ %@flag@ %@tagged@ %@reply@ %@signed@ %@encrypt@ %@attachment@ %@collapsed@ %-10.10@date@  %-24.24F  %s"
              set uncollapse_jump                        # don't collapse on an unread message

              # sorting / threading
              set use_threads = yes
              set sort = reverse-last-date
              set sort_aux = reverse-last-date
              set sort_re                                # thread based on regex
              set reply_regex = "^(([Rr][Ee]?(\[[0-9]+\])?: *)?(\[[^]]+\] *)?)*"

              # Pager View Options ---------------------------------
              set pager_index_lines = 10 # number of index lines to show
              set pager_context = 3      # number of context lines to show
              set pager_stop             # don't go to next message automatically
              set menu_scroll            # scroll in menus
              set tilde                  # show tildes like in vim
              unset markers              # no ugly plus signs
              set quote_regex = "^( {0,4}[>|:#%]| {0,4}[a-z0-9]+[>|]+)+"
              set implicit_autoview = yes
              alternative_order text/plain text/enriched text/html

              # Compose View Options -------------------------------
              set sendmail = "${pkgs.msmtp}/bin/msmtp --read-recipients"
              set use_envelope_from                # which from?
              set sig_dashes                       # dashes before sig
              set edit_headers                     # show headers when composing
              set fast_reply                       # skip to compose when replying
              set askcc                            # ask for CC:
              set fcc_attach                       # save attachments with the body
              unset mime_forward                   # forward attachments as part of body
              set forward_format = "Fwd: %s"       # format of subject when forwarding
              set forward_decode                   # decode when forwarding
              set attribution = "On %d, %n wrote:" # format of quoting header
              set reply_to                         # reply to Reply to: field
              set reverse_name                     # reply as whomever it was to
              set include                          # include message in replies
              set forward_quote                    # include message in forwards
              set sendmail_wait = 30               # timeout after 30 seconds
              set query_command = "/home/benm/documents/repos/zz/zz addresses %s"
              set query_format = "%4c %t %-40.40n %-40.40a %?e?(%e)?"

              # General Navigation Key Bindings --------------------
              # sidebar
              bind  attach,browser,index,pager        H       sidebar-toggle-visible
              bind  attach,browser,index,pager        J       sidebar-next
              bind  attach,browser,index,pager        K       sidebar-prev
              bind  attach,browser,index,pager        L       sidebar-open
              # navigation back
              bind  index                             h       root-message
              bind  attach,browser,pager              h       exit
              # navigation down
              bind  index                             j       next-entry
              bind  pager                             j       next-line
              bind  pager                             \Cj     next-undeleted
              # navigation up
              bind  index                             k       previous-entry
              bind  pager                             k       previous-line
              bind  pager                             \Ck     previous-undeleted
              # navigation forward
              bind  index                             l       display-message
              bind  pager                             l       view-attachments
              bind  attach                            l       view-attach
              bind  generic                           l       select-entry
              # navigation jumps
              bind  index,pager                       g       noop
              bind  index                             gg      first-entry
              bind  pager                             gg      top
              bind  index                             G       last-entry
              bind  pager                             G       bottom
              bind  index                             gj      next-thread
              bind  index                             gk      previous-thread
              # folds
              bind  index                             z       noop
              bind  index                             <space> collapse-thread
              bind  index                             za      collapse-all
              # deletion
              bind  index,pager                       d       delete-message
              bind  index,pager                       D       delete-thread
              bind  index,pager                       u       undelete-message
              bind  index,pager                       U       undelete-thread
              # archive
              macro index,pager                       a       "<modify-tags>+move/archive -unread<enter>" \
                                                              "Mark read and archive"
              macro index,pager                       A       "<tag-thread><tag-prefix><modify-tags>+move/archive -unread<enter><untag-pattern>.<enter>" \
                                                              "Mark thread read and archive"
              # flagging
              bind  index,pager                       f       flag-message
              # composing
              bind  index                             m       mail
              bind  index,pager                       r       reply
              bind  index,pager                       R       group-reply
              bind  index,pager                       F       forward-message
              bind  editor                            <tab>   complete-query

              # TODO:
              # tagging
              bind  generic,pager                     t       noop
              bind  index                             tt      tag-entry
              bind  pager                             tt      tag-message
              bind  index                             tT      tag-thread
              bind  index                             t\\     tag-pattern
              macro index                             t/      "<untag-pattern>all<enter>" \
                                                              "clear tags"
              # Index Key Bindings --------------------------------
              bind  index                             <tab>   sync-mailbox
              bind  index                             \\\\    limit
              bind  index                             \\|     vfolder-from-query
              bind  index                             \\?     show-limit
              macro index                             \\/     "<limit>all<enter>" \
                                                              "clear limit"
              macro index                             \\f     "<limit>~(~F)<enter>" \
                                                              "limit to threads with flagged messages"
              macro index                             \\u     "<limit>~(~U)<enter>" \
                                                              "limit to threads with unread messages"
              macro index                             \Cr     "T~U<enter><tag-prefix><clear-flag>N<untag-pattern>.<enter>" \
                                                              "mark all messages as read"
              macro index                             O       "<shell-escape>systemctl --user start mbsync.service<enter>" \
                                                              "run offlineimap to sync all mail"
              macro index                             C       "<copy-message>?<toggle-mailboxes>" \
                                                              "copy a message to a mailbox"
              macro index                             M       "<save-message>?<toggle-mailboxes>" \
                                                              "move a message to a mailbox"

              # URL extraction ----------------------------------------------------
              macro index,pager                       \cb     "<pipe-message> ${pkgs.urlscan}/bin/urlscan --run 'xdg-open {}'<Enter>" \
                                                              "call urlscan to extract URLs out of a message"
              macro attach,compose                    \cb     "<pipe-entry> ${pkgs.urlscan}/bin/urlscan --run 'xdg-open {}'<Enter>" \
                                                              "call urlscan to extract URLs out of a message"

              # Folder Hooks --------------------------------------
              #folder-hook . "unalternates '*'"

              # Basic Colors ---------------------------------
              # Colour for attachment headers
              color attachment          blue                default
              # Highlighting bold patterns in the body of messages
              color bold                bold default        default
              # Error messages printed by NeoMutt
              color error               red                 default
              # Default colour of the message header in the pager
              color hdrdefault          magenta             default
              # Arrow or bar used to indicate the current item in a menu
              color indicator           bold cyan           black
              # The "+" markers at the beginning of wrapped lines in the pager
              color markers             default             default
              # Informational messages
              color message             blue                default
              # Default colour for all text
              color normal              default             default
              # Visual progress bar
              color progress            black               cyan
              # A question
              color prompt              bold blue           default
              # Highlighting of words in the pager
              color search              red                 default
              # Email's signature lines (.sig)
              color signature           default             default
              # The "~" used to pad blank lines in the pager
              color tilde               default             default
              # Thread tree drawn in the message index and attachment menu
              color tree                magenta             default
              # Highlighting underlined patterns in the body of messages
              color underline           underline default   default

              # Sidebar Colors ---------------------------------
              # The dividing line between the Sidebar and the Index/Pager panels
              color sidebar_divider     lightblack          default
              # Mailboxes containing flagged mail
              color sidebar_flagged     default             default
              # Cursor to select a mailbox
              color sidebar_highlight   default             lightblack
              # The mailbox open in the Index panel
              color sidebar_indicator   lightwhite          blue
              # Mailboxes containing new mail
              color sidebar_new         default             default
              # Mailbox that receives incoming mail
              color sidebar_spoolfile   default             default

              # Status Line colors ---------------------------
              color status              bold blue           black

              # Index Colors ---------------------------------
              # show unread msgs or collapsed threads with unread msgs in bold
              color index               bold default        default     "~U | (~v ~(~U))"
              # show the date in magenta
              color index_date          magenta             default

              # Regexp Colors ---------------------------------
              # color header            default             default
              # color body              default             default

              # Quoted Text Colors ---------------------------------
              color quoted              default             default
            '';
          };
      in
      accountCfgs // mainCfg;
  };
}
