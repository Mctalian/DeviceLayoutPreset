DLP = LibStub("AceAddon-3.0"):NewAddon("DeviceLayoutPreset", "AceConsole-3.0", "AceEvent-3.0")

local options = { 
	name = "DeviceLayoutPreset",
	handler = DLP,
	type = "group",
	args = {
        desc = {
            type = "description",
            name = "Automatically switch your UI layouts using Blizzard's \"Edit Mode\" when you play on multiple devices. It is a simple addon, but it gets the job done.",
            order = 0
        },
        howToHeader = {
            type = "header",
            name = "How to Use",
            order = 1
        },
        howToDesc = {
            type = "description",
            name = "0. Have multiple Edit Mode presets, one for each device (i.e. Steam Deck, Laptop, PC, etc.)\n1. Install this addon on all of the devices you play on.\n2. Set the \"Preset to Load\" below to the layout you want for each device.\n\nNow when you play on your SteamDeck in the morning and your PC in the evening, you don't need to manually change the Edit Mode presets!",
            order = 2
        },
		preset = {
			type = "select",
			name = "Preset to Load",
			desc = "The Edit Mode preset to load when logging in on this device.",
			get = "GetPreset",
			set = "SetPreset",
            order = -1
		},
	},
}

local defaults = {
    profile = {
        presetIndexOnLogin = 0,
    }
}

function DLP:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("DeviceLayoutPresetDB", defaults, true)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("DeviceLayoutPreset", options)
    self.initialized = false
    self:RegisterEvent("SPELLS_CHANGED")
    self:RegisterChatCommand("dlp", "SlashCommand")
    self:RegisterChatCommand("devicelayoutpreset", "SlashCommand")
    self:RegisterChatCommand("deviceLayoutPreset", "SlashCommand")
end


function DLP:SPELLS_CHANGED()
    if self.initialized == false then
        self.initialized = true
        self:Print("Configured to select Edit Mode preset " .. self.db.profile.presetIndexOnLogin .. " on this device")
        self:InitializeOptions()
        if self.db.profile.presetIndexOnLogin > 0 then
            EditModeManagerFrame:SelectLayout(self.db.profile.presetIndexOnLogin)
        end
    end
end

function DLP:InitializeOptions()
    local layouts = EditModeManagerFrame:GetLayouts()
    options.args.preset.values = {}

    for i, l in ipairs(layouts) do
        options.args.preset.values[i] = l.layoutName
    end
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("DeviceLayoutPreset", "DeviceLayoutPreset")
end

function DLP:SetPreset(info, value)
    self.db.profile.presetIndexOnLogin = value
end

function DLP:GetPreset(info)
    return self.db.profile.presetIndexOnLogin
end

function DLP:SlashCommand(msg, editBox)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
end

