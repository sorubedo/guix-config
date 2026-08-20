(list (channel
       (name 'sorubedo)
       (url "https://github.com/sorubedo/guix-channel")
       (branch "main"))
      (channel
       (name 'noctalia)
       (url "https://github.com/noctalia-dev/noctalia")
       (branch "main"))
      (channel
       (name 'abbe)
       (url "https://codeberg.org/group/guix-modules")
       (branch "mainline")
       (introduction
        (make-channel-introduction
         "8c754e3a4b49af7459a8c99de130fa880e5ca86a"
         (openpgp-fingerprint
          "F682 CDCC 39DC 0FEA E116  20B6 C746 CFA9 E74F A4B0"))))
      (channel
       (name 'nonguix)
       (url "https://gitlab.com/nonguix/nonguix")
       (branch "master")
       (introduction
        (make-channel-introduction
         "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
         (openpgp-fingerprint
          "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
      (channel
       (name 'shikanox)
       (url "https://codeberg.org/ch4og/shikanox.git")
       (commit "78a65cac2462c1901964fb48b427ebb3f5e3012f")
       (introduction
        (make-channel-introduction
         "fe3b5f72aa676c69f4d43507bdd18fb051906917"
         (openpgp-fingerprint
          "7C9E 7EBA 828C 58DF DACE  5BED 4DCC 7AB7 FC75 319B"))))
      (channel
       (name 'rosenthal)
       (url "https://codeberg.org/hako/rosenthal.git")
       (branch "trunk")
       (introduction
        (make-channel-introduction
         "7677db76330121a901604dfbad19077893865f35"
         (openpgp-fingerprint
          "13E7 6CD6 E649 C28C 3385  4DF5 5E5A A665 6149 17F7"))))
      (channel
       (name 'pantherx)
       (url "https://codeberg.org/gofranz/panther.git")
       (branch "master")
       (introduction
        (make-channel-introduction
         "54b4056ac571611892c743b65f4c47dc298c49da"
         (openpgp-fingerprint
          "A36A D41E ECC7 A871 1003  5D24 524F EB1A 9D33 C9CB"))))
      (channel
       (name 'guix)
       (url "https://git.guix.gnu.org/guix.git")
       (branch "master")
       (introduction
        (make-channel-introduction
         "9edb3f66fd807b096b48283debdcddccfea34bad"
         (openpgp-fingerprint
          "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))
