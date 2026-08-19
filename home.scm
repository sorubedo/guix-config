(use-modules (guix packages)
             (gnu home)
             (gnu home services)
             (gnu home services desktop)
             (gnu home services shells)
             (gnu home services sound)
             (gnu home services ssh)
             (gnu services)
             (gnu packages admin)
             (gnu packages chromium)
             (gnu packages containers)
             (gnu packages fcitx5)
             (gnu packages freedesktop)
             (gnu packages glib)
             (gnu packages gl)
             (gnu packages gnome)
             (gnu packages hardware)
             (gnu packages lxqt)
             (gnu packages nwg-shell)
             (gnu packages package-management)
             (gnu packages qt)
             (gnu packages shellutils)
             (gnu packages terminals)
             (gnu packages version-control)
             (gnu packages virtualization)
             (gnu packages window-management)
             (gnu packages xdisorg)
             (gnu packages xorg)
             (nongnu packages editors)
             (guix gexp)
             (noctalia)
             (nongnu packages nvidia)
             (nongnu packages video)
             (shika packages wl-clip-persist)
             (shika packages lazygit)
             (shika packages admin)
             (gnu packages fontutils)
             (gnu packages ibus)
             (sorubedo packages input-methods)
             (sorubedo packages vnc)
             (sorubedo packages tools)
             (abbe packages rust)
             (gnu packages vulkan)
             (gnu packages graphics))

;;; ---------------------------------------------------------------------------
;;; 输入法软件包变体
;;; ---------------------------------------------------------------------------

(define fcitx5-rime-with-plugins
  ((package-input-rewriting
    `((,librime . ,librime-with-plugins)))
   fcitx5-rime))

;;; ---------------------------------------------------------------------------
;;; Guix Home 环境
;;; ---------------------------------------------------------------------------

;; 使用 Mesa 替换并启用 Nonguix NVIDIA 驱动。
(replace-mesa (home-environment
                ;;; 用户软件包
                (packages (list nvda-new-feature
                                impala
                                fzf
                                git
                                github-cli
                                lazygit
                                fastfetch-no-zfs
                                starship
                                direnv
                                foot
                                ungoogled-chromium/wayland
                                niri
                                xwayland-satellite
                                xeyes
                                vulkan-tools
                                mesa-utils
                                glmark2
                                noctalia-git
                                pcmanfm-qt
                                lxqt-menu-data
                                gvfs
                                file-roller
                                (list glib "bin")
                                wl-clipboard
                                wl-clip-persist
                                xdg-desktop-portal
                                xdg-desktop-portal-gtk
                                xdg-desktop-portal-gnome
                                gnome-keyring
                                seahorse
                                qt6ct
                                qtsvg
                                nwg-look
                                qtwayland
                                xdg-utils
                                xdg-user-dirs
                                flatpak
                                virt-manager
                                distrobox
                                vscodium
                                obs-nvidia
                                mpv-nvidia
                                fcitx5
                                fcitx5-chinese-addons
                                fcitx5-configtool
                                fcitx5-qt
                                fcitx5-rime-with-plugins
                                fontmanager
                                wayvnc
                                steamguard-cli))

                ;;; 家庭服务
                ;; 按环境、桌面和终端功能分组。
                (services
                 (append (list
                          ;; 环境变量与基础会话服务。
                          (simple-service 'local-bin-path
                           home-environment-variables-service-type
                           '(("PATH" . "$HOME/.local/bin:$PATH")))
                          (simple-service 'flatpak-environment
                           home-environment-variables-service-type
                           '(("XDG_DATA_DIRS" . "$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:$XDG_DATA_DIRS")))
                          (service home-dbus-service-type)
                          (service home-ssh-agent-service-type)
                          (service home-pipewire-service-type)

                          ;; XDG Desktop Portal 选择 GTK 文件选择器和 GNOME 密钥环。
                          (simple-service 'xdg-desktop-portal-config
                           home-xdg-configuration-files-service-type
                           `(("xdg-desktop-portal/niri-portals.conf" ,(plain-file
                                                                       "niri-portals.conf"
                                                                       "[preferred]
default=gnome;gtk;
org.freedesktop.impl.portal.Access=gtk;
org.freedesktop.impl.portal.Notification=gtk;
org.freedesktop.impl.portal.Secret=gnome-keyring;
org.freedesktop.impl.portal.FileChooser=gtk;
org.freedesktop.impl.portal.ScreenCast=gnome;
org.freedesktop.impl.portal.Screenshot=gnome;
"))))

                          ;; 隐藏 PCManFM-Qt 的偏好设置桌面入口。
                          (simple-service 'hide-pcmanfm-qt-desktop-pref
                                          home-xdg-data-files-service-type
                                          `(("applications/pcmanfm-qt-desktop-pref.desktop" ,
                                             (plain-file
                                              "pcmanfm-qt-desktop-pref.desktop"
                                              "[Desktop Entry]
Type=Application
Hidden=true
"))))

                          ;; Fish 交互式 shell 配置。
                          (service home-fish-service-type
                                   (home-fish-configuration (config (list (plain-file
                                                                           "config.fish"
                                                                           "function fish_greeting
    fastfetch
end

if status is-interactive
    starship init fish | source
    fzf --fish | source
    direnv hook fish | source
end
"))))))
                         %base-home-services)))
              #:driver nvda-new-feature)
