local addonName = "DeviceLayoutPreset"
DLP = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0")

local options = {
    name = addonName,
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
            values = function()
                return DLP:GetLayouts()
            end,
            get = "GetPreset",
            set = "SetPreset",
            order = -1
        }
    }
}

local defaults = {
    profile = {
        presetIndexOnLogin = 0 -- DEPRECATED
    },
    global = {
        presetIndexOnLogin = 0,
        migratedFromProfile = false
    }
}

local layouts = nil

function DLP:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("DeviceLayoutPresetDB", defaults, true)
    if not self.db.global.migratedFromProfile then
        self.db.global.presetIndexOnLogin = self.db.profile.presetIndexOnLogin
        self.db.global.migratedFromProfile = true
    end
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options)
    self:InitializeOptions()
    self:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
    self:SecureHook(C_EditMode, "OnLayoutDeleted", OnLayoutDeleted)
    self:SecureHook(C_EditMode, "OnLayoutAdded", OnLayoutAdded)
    self:RegisterChatCommand("dlp", "SlashCommand")
    self:RegisterChatCommand("devicelayoutpreset", "SlashCommand")
    self:RegisterChatCommand("deviceLayoutPreset", "SlashCommand")
end

function DLP:EDIT_MODE_LAYOUTS_UPDATED(_, layoutInfo)
    local desired = self.db.global.presetIndexOnLogin
    layouts = EditModeManagerFrame:GetLayouts()
    if layoutInfo.activeLayout == desired then
        self:Print("Have a fun session!")
    elseif desired <= 0 or desired > table.getn(layouts) then
        self:Print("Visit the addon options (/dlp) to select the Edit Mode preset for this device.")
        self.db.global.presetIndexOnLogin = 0
    else
        EditModeManagerFrame:SelectLayout(desired)
        self:Print("Successfully loaded your device layout: \"" .. layouts[desired].layoutName .. "\" - Have a fun session!")
    end
    self:UnregisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
end

function DLP:OnLayoutDeleted(deletedIndex)
    if deletedIndex == self.db.global.presetIndexOnLogin then
        self:Print("Visit the addon options (/dlp) to select a new preset for this device.")
        self.db.global.presetIndexOnLogin = 0
    end
end

function DLP:OnLayoutAdded()
    self:Print("New layout detected! Visit the addon options (/dlp) to change your preset to your new layout.")
end

function DLP:GetLayouts()
    layouts = EditModeManagerFrame:GetLayouts()
    local values = {}
    for i, l in ipairs(layouts) do
        values[i] = l.layoutName
    end
    return values
end

function DLP:InitializeOptions()
    if self.optionsFrame == nil then
        self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)
    end
end

function DLP:SetPreset(info, value)
    self.db.global.presetIndexOnLogin = value
end

function DLP:GetPreset(info)
    return self.db.global.presetIndexOnLogin
end

function DLP:SlashCommand(msg, editBox)
    LibStub("AceConfigDialog-3.0"):Open(addonName)
end
