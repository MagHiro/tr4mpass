# WSL2 Apple USB troubleshooting (read-only)

For devices that stay on a black screen and report a 60-second DFU-to-Recovery timeout, first determine whether the USB mode changed or WSL2 lost the attachment. A black screen alone does not establish which mode is active.

## Check WSL2

In Ubuntu:

```bash
bash tools/diagnose-apple-usb.sh
```

In Windows PowerShell:

```powershell
usbipd list
```

The diagnostic script only reads `lsusb` output. It does not send DFU requests, write device identifiers, or perform activation.

- `05ac:1227` indicates standard DFU mode; `05ac:f014` indicates Port DFU mode.
- `05ac:1280` through `05ac:1283` indicate Apple Recovery Mode variants.
- No Apple USB entries in WSL2 may mean the device detached on USB re-enumeration. Check `usbipd list` in Windows; it may need reattachment.
- Multiple Apple devices in DFU/Recovery mode are ambiguous. Disconnect unrelated devices.
- Other USB IDs must not be assumed to be Recovery Mode.

Run offline tests (no phone required):

```bash
bash tests/test_diagnose_apple_usb.sh
```

## Limitations

Successful USB enumeration does not establish that DFU_ABORT can transition an A13 device to Recovery Mode. The current Path B implementation has a separate DFU handle lifetime/identity-stage mismatch; none of these diagnostics resolves it or demonstrates working Activation Lock bypass. For legitimate Activation Lock removal, use the original Apple Account or Apple's ownership verification support process.
