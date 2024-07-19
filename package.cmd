IF EXIST DeviceLayoutPreset.zip (
  del DeviceLayoutPreset.zip
)
COPY License src/LICENSE
COPY README.md src/README.md
pushd src
tar.exe -a -c -f ../DeviceLayoutPreset.zip *
DEL LICENSE
DEL README.md
popd
