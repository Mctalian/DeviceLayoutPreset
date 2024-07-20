IF EXIST DeviceLayoutPreset.zip (
  del DeviceLayoutPreset.zip
)
COPY License DeviceLayoutPreset/LICENSE
COPY README.md DeviceLayoutPreset/README.md
tar.exe -a -c -f DeviceLayoutPreset.zip DeviceLayoutPreset
DEL DeviceLayoutPreset/LICENSE
DEL DeviceLayoutPreset/README.md
