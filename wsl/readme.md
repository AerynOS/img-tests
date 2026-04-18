# AerynOS WSL

To create and distribute follow this guide
https://learn.microsoft.com/en-us/windows/wsl/build-custom-distro

## Files
- readme.md   :this file
- osroot      :files need for wsl

```
.
├── osroot
│   ├── etc
│   │   ├── oobe.sh
│   │   ├── wsl.conf
│   │   └── wsl-distribution.conf
│   └── usr
│       └── lib
│           └── wsl
│               ├── aerynos.ico
│               └── aerynos-wt.json
└── readme.md
```

## ToDo

- [ ] config user group in oobe.sh
- [ ] config uid in oobe.sh
- [ ] config uid in wsl-distribution.conf
- [ ] config default user in wsl.conf
- [ ] disable or mask service may cause issues with WSL
   - systemd-resolved.service
   - systemd-networkd.service
   - NetworkManager.service
   - systemd-tmpfiles-setup.service
   - systemd-tmpfiles-clean.service
   - systemd-tmpfiles-clean.timer
   - systemd-tmpfiles-setup-dev-early.service
   - systemd-tmpfiles-setup-dev.service
   - tmp.mount