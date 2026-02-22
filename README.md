<img width="477" height="429" alt="rdp-biteback" src="https://github.com/user-attachments/assets/7baf47a0-29df-400e-af3e-d1499eaf0883" />


# rdp-biteback - Termsrv.dll Patch Utility

RDP Biteback is a small Windows tool that patches `termsrv.dll` to unlock full Remote Desktop Services functionality (for example, multiple sessions and relaxed licensing checks).  
It is intended for lab, testing and educational use only. Use at your own risk and make sure you respect all applicable licenses and laws.

> ⚠️ **Warning**  
> Modifying Microsoft binaries can break your system, violate license terms or reduce security.  
> Always test in a virtual machine first and keep reliable backups.

<img width="897" height="484" alt="screen" src="https://github.com/user-attachments/assets/69366b53-222e-4373-9762-1bb5087b18de" />

---

## How it works

The tool performs a simple binary patch on `termsrv.dll`:

- Reads the original `termsrv.dll` as raw bytes.
- Converts the bytes to a hex string representation.
- Searches for a specific instruction pattern that enforces RDP restrictions.
- Replaces this pattern with an alternative instruction sequence that removes those checks.
- Writes the modified bytes back to disk and restarts the relevant RDP services.

All patching is done in-memory using PowerShell, without installing extra dependencies or third‑party drivers.

---

## Features

- **One‑click patch**  
  A large **PATCH** button executes the full patching workflow on the selected `termsrv.dll`.

- **Patch status check**  
  A **CHECK PATCH** button scans the file and reports whether the patched instruction sequence is already present.

- **Service restart**  
  A **Restart services** button cleanly restarts the `TermService` and `UmRdpService` services after changes.

- **Custom file selection**  
  A **Browse** button lets you choose a custom `termsrv.dll` (e.g. from another installation or build).

- **Activity log**  
  A read‑only status/memo window shows a timestamped log of all actions and results (backup, patch, errors, service control).

---

## Usage

1. Run PowerShell as **Administrator**.
2. Clone or download this repository.
3. Execute the script:

   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\rdp-biteback.ps1
   ```

4. Verify that the default path points to the correct `termsrv.dll` (usually `C:\Windows\System32\termsrv.dll`).
5. (Optional) Click **Browse** to select another `termsrv.dll`.
6. Click **CHECK PATCH** to see if the file is already patched.
7. Click **PATCH** to:
   - Stop the RDP services
   - Create a `.bak` backup
   - Apply the binary patch
   - Restart the services
8. Watch the status log for any warnings or errors.

---

## Safety and rollback

- Before patching, the tool automatically creates a backup:

  ```text
  C:\Windows\System32\termsrv.dll.bak
  ```

- To roll back:
  1. Stop `TermService` and `UmRdpService`.
  2. Restore the backup file manually.
  3. Start the services again or reboot.

Always keep an additional offline backup or a VM snapshot in case the system fails to boot or RDP stops working.

---

## Requirements

- Windows with `termsrv.dll` present (e.g. Windows Server / client with RDP)
- PowerShell with Windows Forms support
- Administrative privileges (needed for:
  - stopping/starting services
  - taking ownership of system files
  - writing into `C:\Windows\System32`
)

---

## Legal and ethical notice

This project is for **educational and research purposes only**.  
You are solely responsible for how you use it:

- Do not use on systems you do not own or administer.
- Ensure compliance with Microsoft licensing and your local law.
- Consider the security impact of weakening RDP restrictions.

**RDP Biteback** is provided *as is*, without any warranty. The author takes no responsibility for data loss, system damage or policy violations.

---

## Credits

- Original concept and manual RDP patching techniques inspired by community research and technical write‑ups on patching `termsrv.dll`.
- Tool implementation and GUI wrapper by **\<suuhm\>**.
