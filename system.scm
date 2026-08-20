(use-modules (gnu)
             (gnu services base)
             (gnu services containers)
             (gnu services dbus)
             (gnu services desktop)
             (gnu services dns)
             (gnu services docker)
             (shika packages docker)
             (gnu services linux)
             (gnu services networking)
             (gnu services pm)
             (gnu services shepherd)
             (gnu services ssh)
             (gnu services sysctl)
             (gnu services virtualization)
             (gnu system accounts)
             (gnu packages admin)
             (gnu packages curl)
             (gnu packages fontutils)
             (gnu packages fonts)
             (gnu packages games)
             (gnu packages gnome-xyz)
             (gnu packages hardware)
             (gnu packages linux)
             (gnu packages ncurses)
             (gnu packages containers)
             (gnu packages shells)
             (abbe packages fonts)
             (guix gexp)
             (nongnu packages linux)
             (nongnu packages nvidia)
             (nonguix)
             (nonguix transformations)
             (sorubedo services virtualization))

;;; ---------------------------------------------------------------------------
;;; 密钥与身份凭据
;;; ---------------------------------------------------------------------------

;; 系统服务使用的签名密钥和 SSH 公钥。
(define nonguix-signing-key
  (plain-file "nonguix.pub"
   "(public-key (ecc (curve Ed25519)
 (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))"))

(define pantherx-signing-key
  (plain-file "pantherx.pub"
   "(public-key (ecc (curve Ed25519)
 (q #0096373009D945F86C75DFE96FC2D21E2F82BA8264CB69180AA4F9D3C45BAA47#)))"))

(define sorubedo-ssh-public-key
  (plain-file "sorubedo.pub"
   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN4Q3QhJb4Bc0oSECsTXHbz+RQg1w2pKXbsavP1Dm/Og sorubedo@Laptop"))

;; Keep Docker's persisted runtime name stable while allowing Guix to update
;; the underlying runc store path between system generations.
(define docker-daemon-config
  (mixed-text-file
   "docker-daemon.json"
   "{\n"
   "  \"default-runtime\": \"guix-runc\",\n"
   "  \"runtimes\": {\n"
   "    \"guix-runc\": {\n"
   "      \"path\": \"" (file-append runc "/sbin/runc") "\"\n"
   "    }\n"
   "  }\n"
   "}\n"))

;;; ---------------------------------------------------------------------------
;;; 控制台与登录
;;; ---------------------------------------------------------------------------

;; greetd 使用 tty1，其余终端由 mingetty 提供登录提示。
(define tuigreet-command
  #~(string-append #$tuigreet
                   "/bin/tuigreet"
                   " --time"
                   " --remember"
                   " --asterisks"
                   " --power-shutdown 'loginctl poweroff'"
                   " --power-reboot 'loginctl reboot'"
                   " --cmd 'niri --session'"))

(define greetd-service
  (service greetd-service-type
           (greetd-configuration (terminals (list (greetd-terminal-configuration
                                                   (terminal-vt "1")
                                                   (terminal-switch #t)
                                                   (default-session-command
                                                    tuigreet-command)))))))

(define mingetty-services
  (map (lambda (tty)
         (service mingetty-service-type
                  (mingetty-configuration (tty tty))))
       '("tty2" "tty3" "tty4" "tty5" "tty6")))

;;; ---------------------------------------------------------------------------
;;; 虚拟机 NAT 网络
;;; ---------------------------------------------------------------------------

;; 网桥、宿主机地址和子网范围。
(define %vmnat-bridge
  "vmnat0")
(define %vmnat-prefix
  "192.168.240.1/24")
(define %vmnat-subnet
  "192.168.240.0/24")

;; 为 vmnat0 安装 DHCP、DNS、转发和 NAT 规则。
(define vmnat0-firewall-service
  (simple-service 'vmnat0-firewall shepherd-root-service-type
                  (list (shepherd-service (provision '(vmnat0-firewall))
                                          (requirement '(iptables
                                                         vmnat-networking))
                                          (documentation
                                           "Install forwarding and NAT rules for vmnat0.")
                                          (one-shot? #t)
                                          (start #~(lambda _
                                                     (let ((iptables #$(file-append
                                                                        iptables
                                                                        "/sbin/iptables")))
                                                       (define (ensure-rule
                                                                check-args
                                                                add-args)
                                                         (or (zero? (apply
                                                                     system*
                                                                     iptables
                                                                     check-args))
                                                             (zero? (apply
                                                                     system*
                                                                     iptables
                                                                     add-args))))
                                                       (and
                                                        ;; 放行虚拟机访问宿主机提供的 DHCP 和 DNS。
                                                        (ensure-rule (list
                                                                      "-C"
                                                                      "INPUT"
                                                                      "-i"
                                                                      #$%vmnat-bridge
                                                                      "-p"
                                                                      "udp"
                                                                      "--dport"
                                                                      "67"
                                                                      "-j"
                                                                      "ACCEPT")
                                                                     (list
                                                                      "-I"
                                                                      "INPUT"
                                                                      "1"
                                                                      "-i"
                                                                      #$%vmnat-bridge
                                                                      "-p"
                                                                      "udp"
                                                                      "--dport"
                                                                      "67"
                                                                      "-j"
                                                                      "ACCEPT"))
                                                        (ensure-rule (list
                                                                      "-C"
                                                                      "INPUT"
                                                                      "-i"
                                                                      #$%vmnat-bridge
                                                                      "-p"
                                                                      "udp"
                                                                      "--dport"
                                                                      "53"
                                                                      "-j"
                                                                      "ACCEPT")
                                                                     (list
                                                                      "-I"
                                                                      "INPUT"
                                                                      "1"
                                                                      "-i"
                                                                      #$%vmnat-bridge
                                                                      "-p"
                                                                      "udp"
                                                                      "--dport"
                                                                      "53"
                                                                      "-j"
                                                                      "ACCEPT"))
                                                        (ensure-rule (list
                                                                      "-C"
                                                                      "INPUT"
                                                                      "-i"
                                                                      #$%vmnat-bridge
                                                                      "-p"
                                                                      "tcp"
                                                                      "--dport"
                                                                      "53"
                                                                      "-j"
                                                                      "ACCEPT")
                                                                     (list
                                                                      "-I"
                                                                      "INPUT"
                                                                      "1"
                                                                      "-i"
                                                                      #$%vmnat-bridge
                                                                      "-p"
                                                                      "tcp"
                                                                      "--dport"
                                                                      "53"
                                                                      "-j"
                                                                      "ACCEPT"))
                                                        ;; 允许虚拟机出站，并放行已建立连接的返回流量。
                                                        (ensure-rule (list
                                                                      "-C"
                                                                      "FORWARD"
                                                                      "-i"
                                                                      #$%vmnat-bridge
                                                                      "-j"
                                                                      "ACCEPT")
                                                                     (list
                                                                      "-I"
                                                                      "FORWARD"
                                                                      "1"
                                                                      "-i"
                                                                      #$%vmnat-bridge
                                                                      "-j"
                                                                      "ACCEPT"))
                                                        (ensure-rule (list
                                                                      "-C"
                                                                      "FORWARD"
                                                                      "-o"
                                                                      #$%vmnat-bridge
                                                                      "-m"
                                                                      "conntrack"
                                                                      "--ctstate"
                                                                      "ESTABLISHED,RELATED"
                                                                      "-j"
                                                                      "ACCEPT")
                                                                     (list
                                                                      "-I"
                                                                      "FORWARD"
                                                                      "1"
                                                                      "-o"
                                                                      #$%vmnat-bridge
                                                                      "-m"
                                                                      "conntrack"
                                                                      "--ctstate"
                                                                      "ESTABLISHED,RELATED"
                                                                      "-j"
                                                                      "ACCEPT"))
                                                        ;; 对虚拟机网段做源地址伪装。
                                                        (ensure-rule (list
                                                                      "-t"
                                                                      "nat"
                                                                      "-C"
                                                                      "POSTROUTING"
                                                                      "-s"
                                                                      #$%vmnat-subnet
                                                                      "!"
                                                                      "-o"
                                                                      #$%vmnat-bridge
                                                                      "-j"
                                                                      "MASQUERADE")
                                                                     (list
                                                                      "-t"
                                                                      "nat"
                                                                      "-A"
                                                                      "POSTROUTING"
                                                                      "-s"
                                                                      #$%vmnat-subnet
                                                                      "!"
                                                                      "-o"
                                                                      #$%vmnat-bridge
                                                                      "-j"
                                                                      "MASQUERADE"))))))))))

;;; ---------------------------------------------------------------------------
;;; 主机操作系统
;;; ---------------------------------------------------------------------------

(define %base-os
  (operating-system
    ;; 基本系统信息。
    (locale "zh_CN.utf8")
    (timezone "Asia/Shanghai")
    (keyboard-layout (keyboard-layout "us"))
    (host-name "OhMyGuix")

    ;; 用户、内核与固件。
    (users (cons* (user-account
                    (name "sorubedo")
                    (comment "Sorubedo")
                    (group "users")
                    (home-directory "/home/sorubedo")
                    (supplementary-groups '("wheel" "netdev" "audio" "video"
                                            "cgroup"))
                    (shell (file-append fish "/bin/fish")))
                  %base-user-accounts))
    (kernel linux)
    (kernel-arguments (append '("nvidia.NVreg_EnableS0ixPowerManagement=1"
                                "nvidia.NVreg_UseKernelSuspendNotifiers=1")
                              %default-kernel-arguments))
    (firmware (cons* linux-firmware %base-firmware))

    ;; 系统软件包。
    (packages (append (list fish
                            ncurses
                            curl
                            brightnessctl
                            ddcutil
                            podman-compose
                            font-terminus
                            fontconfig
                            font-google-noto-sans-cjk
                            font-google-noto-serif-cjk
                            font-google-noto-emoji
                            font-maple-nf-cn-unhinted
                            font-lxgw-wenkai
                            font-lxgw-neozhisong
                            adw-gtk3-theme
                            papirus-icon-theme
                            qogir-icon-theme
                            bibata-cursor-theme) %base-packages))

    ;; 系统服务，按功能分组排列。
    (services
     (append (list
              ;; 控制台与登录。
              (simple-service 'console-numlock activation-service-type
                              #~(for-each (lambda (tty)
                                            (call-with-input-file tty
                                              (lambda (port)
                                                (parameterize ((current-input-port
                                                                port))
                                                  (system* #$(file-append kbd
                                                              "/bin/setleds")
                                                           "-D" "+num")))))
                                          '("/dev/tty1" "/dev/tty2"
                                            "/dev/tty3" "/dev/tty4"
                                            "/dev/tty5" "/dev/tty6")))
              (simple-service 'tuigreet-cache activation-service-type
                              #~(begin
                                  (use-modules (guix build utils))
                                  (mkdir-p "/var/cache/tuigreet")
                                  (let ((greeter (getpwnam "greeter")))
                                    (chown "/var/cache/tuigreet"
                                           (passwd:uid greeter)
                                           (passwd:gid greeter)))
                                  (chmod "/var/cache/tuigreet" #o755)))
              greetd-service
              (service openssh-service-type
                       (openssh-configuration (authorized-keys `(("sorubedo" ,sorubedo-ssh-public-key)))))

              ;; 桌面会话与设备支持。
              (service elogind-service-type)
              (service udisks-service-type)
              (service polkit-service-type)
              (service bluetooth-service-type
                       (bluetooth-configuration (auto-enable? #t)))
              (service x11-socket-directory-service-type)
              (udev-rules-service 'ddcutil ddcutil)
              (udev-rules-service 'steam-devices steam-devices-udev-rules)
              (service gnome-keyring-service-type
                       (gnome-keyring-configuration (pam-services '(("greetd" . login)
                                                                    ("passwd" . passwd)))))
              (service power-profiles-daemon-service-type)
              (service upower-service-type)
              (service zram-device-service-type
                       (zram-device-configuration (size "8G")
                                                  (compression-algorithm 'zstd)
                                                  (priority 100)))

              ;; 宿主机网络。
              (service dhcpcd-service-type
                       (dhcpcd-configuration (extra-content
                                              "denyinterfaces vmnat0\n")))
              (service iwd-service-type)
              (service ntp-service-type)

              ;; 虚拟机 NAT：宿主机管理 vmnat0，libvirt 只连接此桥。
              (service static-networking-service-type
                       (list (static-networking (provision '(vmnat-networking))
                                                (links (list (network-link (name
                                                                            %vmnat-bridge)
                                                                           (type 'bridge)
                                                                           (arguments '()))))
                                                (addresses (list (network-address
                                                                  (device
                                                                   %vmnat-bridge)
                                                                  (value
                                                                   %vmnat-prefix)))))))
              (service dnsmasq-service-type
                       (dnsmasq-configuration (shepherd-provision '(dnsmasq-vmnat0))
                                              (shepherd-requirement '(vmnat-networking))
                                              (extra-options (list
                                                              "--except-interface=lo"
                                                              "--interface=vmnat0"
                                                              "--bind-dynamic"
                                                              "--dhcp-range=192.168.240.100,192.168.240.254,255.255.255.0,12h"
                                                              "--dhcp-option=option:router,192.168.240.1"
                                                              "--dhcp-option=option:dns-server,192.168.240.1"))))
              vmnat0-firewall-service

              ;; 虚拟化。
              (service virtlog-service-type)
              (service libvirt-service-type
                       (libvirt-configuration (unix-sock-rw-perms "0777")
                                              (auth-unix-rw "polkit")))
              (service virtiofsd-service-type)

              ;; 容器运行时。
              (service containerd-service-type)
              (service docker-service-type
                       (docker-configuration
                        (docker-cli docker-full)
                        (config-file docker-daemon-config)))
              (service iptables-service-type)
              (service rootless-podman-service-type
                       (rootless-podman-configuration (subgids (list (subid-range
                                                                      (name
                                                                       "sorubedo"))))
                                                      (subuids (list (subid-range
                                                                      (name
                                                                       "sorubedo"))))))

              ;; 二进制替代服务器。
              (simple-service 'substitute-servers guix-service-type
                              (guix-extension (substitute-urls (list
                                                                "https://substitutes.nonguix.org"
                                                                "https://substitutes.guix.gofranz.com"))
                                              (authorized-keys (list
                                                                nonguix-signing-key
                                                                pantherx-signing-key)))))

             mingetty-services

             ;; 对基础服务做定制：控制台字体、登录终端、IPv4 转发。
             (modify-services %base-services
               (console-font-service-type config =>
                                          (map (lambda (tty)
                                                 (cons tty
                                                       (file-append
                                                        font-terminus
                                                        "/share/consolefonts/ter-132n")))
                                               '("tty1" "tty2" "tty3" "tty4"
                                                 "tty5" "tty6")))
               ;; 保留 login-service-type，供 Noctalia 生成 /etc/pam.d/login。
               (delete mingetty-service-type)
               ;; 开启 IPv4 转发，供虚拟机 NAT 使用。
               (sysctl-service-type config =>
                                    (sysctl-configuration (settings (cons '("net.ipv4.ip_forward" . "1")
                                                                     %default-sysctl-settings)))))))

    ;; 启动加载与磁盘布局。
    (bootloader (bootloader-configuration
                  (bootloader grub-efi-bootloader)
                  (targets (list "/boot/efi"))
                  (keyboard-layout keyboard-layout)))
    (swap-devices (list (swap-space
                          (target (uuid "5ba4abca-d2bb-48ae-9d7e-5175cbce8fe9")))))
    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device (uuid
                                    "444eb90b-0e73-4c18-999f-2c1eed09da89"
                                    'xfs))
                           (type "xfs"))
                         (file-system
                           (mount-point "/boot/efi")
                           (device (uuid "B694-DDB7"
                                         'fat32))
                           (type "vfat")) %base-file-systems))))

;;; ---------------------------------------------------------------------------
;;; 最终系统变换
;;; ---------------------------------------------------------------------------

;; 使用 Nonguix 的 NVIDIA 驱动变换生成最终系统。
((nonguix-transformation-nvidia #:driver nvda-new-feature
                                #:open-source-kernel-module? #t)
 %base-os)
