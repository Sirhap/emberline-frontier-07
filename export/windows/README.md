# export/windows

Windows Desktop 是可选包，给老板本机跑。**验收门是 Linux `DISPLAY=:9`**，见 `export/linux/README.md`。

```bash
./tools/export_windows_accept.sh
```

需要 Godot 4.7 和官方模板文件 `windows_release_x86_64.exe`（在 `Godot_v4.7-stable_export_templates.tpz` 的 `templates/` 里，不是 `windows_desktop_release.zip`）。缺模板脚本直接失败，不会造假 exe。

产物：`dist/windows/EmberlineFrontier07.exe` + `.pck`，以及 `dist/windows-accept-<shortsha>.zip`。解压后 exe 和 pck 放一起双击运行。霜晶皮肤同样打进包。不改 Cloudflare Web。
