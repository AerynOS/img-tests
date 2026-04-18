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

## When release you may do

- [ ] config user group in oobe.sh
- [ ] config uid in oobe.sh
- [ ] config uid in wsl-distribution.conf
- [ ] config default user in wsl.conf
