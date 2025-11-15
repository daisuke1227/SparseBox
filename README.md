# SparseBox

On-device backup restoration?

- [x] rewrote SparseRestore to swift
- [x] integrated bl_sbx (itunesstored & bookassetd sandbox escape for iOS ≤26.1)

> [!NOTE]
> I have no interest in updating this project at the moment, see Releases for more info. PR welcome.

## Features

### Backup Restoration Exploit
The primary method uses on-device backup restoration with path traversal to modify MobileGestalt and enable various iOS features.

### BL Sandbox Escape (iOS ≤26.1)
Alternative exploit method using itunesstored & bookassetd daemons to escape the sandbox and write arbitrary files. This exploit:
- Works on iOS 26.1 and below (patched in iOS 26.2+)
- Uses crafted SQLite databases (BLDatabaseManager.sqlite, downloads.28.sqlitedb)
- Delivers EPUB payloads to arbitrary file paths
- Can modify MobileGestalt.plist to spoof device type
- For educational and research purposes only

## Installation
SideStore is recommended as you will also be getting the pairing file and setting up VPN.

Download ipa from [Releases](https://github.com/khanhduytran0/SparseBox/releases), Actions tab or [nightly.link](https://nightly.link/khanhduytran0/SparseBox/workflows/build/main/artifact.zip)

Before opening SparseBox, you have to close SideStore from app switcher. This is because only one app can use VPN proxy at a time. Maybe changing port could solve this issue.

## Thanks to
- @SideStore: em_proxy and minimuxer
- @JJTech0130: SparseRestore and backup exploit
- @PoomSmart: MobileGestalt dump
- @Lakr233: BBackupp
- @libimobiledevice
- [the sneakyf1shy apple intelligence tutorial](https://gist.github.com/f1shy-dev/23b4a78dc283edd30ae2b2e6429129b5#file-best_sae_trick-md)
