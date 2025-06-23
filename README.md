## Fault Tolerant Heap Manager for Windows

The Fault Tolerant Heap (FTH) is a subsystem of Windows 7 responsible for monitoring application crashes and autonomously applying mitigations to prevent future crashes on a per application basis. [Learn More](https://learn.microsoft.com/en-us/windows/win32/win7appqual/fault-tolerant-heap)

---
### Features

- Toggle FTH ON/OFF
- Add/Remove Apps to Exclusion List

---

### How To Use
**Run From PowerShell Console as Admin**
```PowerShell
iwr https://raw.githubusercontent.com/zoicware/TweakFTH/main/ManageFTH.ps1 | iex
```

![image](https://github.com/user-attachments/assets/4ad783cb-6e01-4c3e-9645-ab329afba462)
