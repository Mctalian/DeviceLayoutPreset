.PHONY: get_tokens build

build:
	@wow-build-tools build -d -t DeviceLayoutPreset -r .release

watch:
	@wow-build-tools watch -t DeviceLayoutPreset -r .release
