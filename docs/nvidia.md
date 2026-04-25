# NVIDIA setup notes

This setup assumes AMD CPU + NVIDIA GPU.

Use `pkg/gpu-nvidia.txt` for the standard Arch `linux` kernel.

Use `pkg/gpu-nvidia-dkms.txt` for custom kernels such as `linux-zen`.

Add this kernel parameter:

```text
nvidia_drm.modeset=1
```

For systemd-boot, edit your loader entry in `/boot/loader/entries/` and add it to the `options` line.

For GRUB, edit `/etc/default/grub`, add the parameter to `GRUB_CMDLINE_LINUX_DEFAULT`, then run:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Check after reboot:

```bash
nvidia-smi
vulkaninfo --summary
```
