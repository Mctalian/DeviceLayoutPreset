---@type string, table
local _, ns = ...

---@class DLP_ns
local G_DLP = ns

---@class DLP_Locale
local L = LibStub("AceLocale-3.0"):NewLocale(G_DLP.localeName, "enUS", true)

L["OPTIONS_DESC"] = "Automatically switch your UI layouts using Blizzard's \"Edit Mode\" when you play on multiple devices. It is a simple addon, but it gets the job done."
L["OPTIONS_HOWTO_NAME"] = "How to use"
L["OPTIONS_HOWTO_STEP0"] = "0. Have multiple Edit Mode presets, one for each device (i.e. Steam Deck, Laptop, PC, etc.)"
L["OPTIONS_HOWTO_STEP1"] = "1. Install this addon on all of the devices you play on."
L["OPTIONS_HOWTO_STEP2"] = "2. Set the \"Default preset to load\" below to the layout you want for each device."
L["OPTIONS_HOWTO_CONCLUSION"] = "\nNow when you play on your SteamDeck in the morning and your PC in the evening, you don't need to manually change the Edit Mode presets!"
L["OPTIONS_PRESET_NAME"] = "Default preset to load"
L["OPTIONS_PRESET_DESC"] = "The Edit Mode preset to load when logging in on this device or when switching to a spec with no override defined below."
L["OPTIONS_SPECS_NAME"] = "Class Specialization Overrides"
L["OPTIONS_SPECS_DESC"] = "If you'd like to have different layouts for specific specializations, you can set overrides here."
L["OPTIONS_SPECS_PRESET_DESC"] = "The Edit Mode preset to load in %s spec."
L["DO_NOT_OVERRIDE"] = "Same as default preset"

L["ERROR_NO_LAYOUT_INFO"] = "There was an issue retrieving layoutInfo on startup, please report this issue on github"
L["ERROR_NO_SPEC_INFO"] = "There was an issue retrieving specInfo on startup, please report this issue on github"
L["ERROR_LAYOUT_INVALID"] = "No valid layout found. Visit the addon options (/dlp) to select a valid Edit Mode preset."

L["LAYOUT_TYPE_DEVICE"] = "Device"
L["LAYOUT_TYPE_SPEC"] = "Specialization"

L["SUCCESS_LOADED_LAYOUT"] = "Successfully loaded your %s layout: \"%s\" - Have a fun session!"

L["WELCOME_NEW_VERSION"] = "Thanks for using DeviceLayoutPreset %s!"

L["EVENT_DELETED_LAYOUT"] = "Looks like your selected layout has been deleted. Visit the addon options (/dlp) to select a new preset for this device and/or specs."
L["EVENT_CREATED_LAYOUT"] = "New layout detected! Visit the addon options (/dlp) to use this layout in your presets."
