local addonName, ns = ...
local DLP = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0",
    "AceBucket-3.0")
ns.DLP = DLP

local acd = LibStub("AceConfigDialog-3.0")

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
        howToDesc = {
            type = "group",
            name = "How to Use",
            inline = true,
            args = {
                step0 = {
                    type = "description",
                    name = "0. Have multiple Edit Mode presets, one for each device (i.e. Steam Deck, Laptop, PC, etc.)",
                    order = 1
                },
                step1 = {
                    type = "description",
                    name = "1. Install this addon on all of the devices you play on.",
                    order = 2
                },
                step2 = {
                    type = "description",
                    name = "2. Set the \"Preset to Load\" below to the layout you want for each device.",
                    order = 3
                },
                conclusion = {
                    type = "description",
                    name = "\nNow when you play on your SteamDeck in the morning and your PC in the evening, you don't need to manually change the Edit Mode presets!",
                    order = 4
                }
            },
            order = 1
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
        migratedFromProfile = false,
        lastVersionLoaded = "v1.0.0"
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
    self.bucketHandle = self:RegisterBucketEvent("EDIT_MODE_LAYOUTS_UPDATED", 0.2, "EDIT_MODE_LAYOUTS_UPDATED")
    self:SecureHook(C_EditMode, "OnLayoutDeleted", OnLayoutDeleted)
    self:SecureHook(C_EditMode, "OnLayoutAdded", OnLayoutAdded)
    self:RegisterChatCommand("dlp", "SlashCommand")
    self:RegisterChatCommand("devicelayoutpreset", "SlashCommand")
    self:RegisterChatCommand("deviceLayoutPreset", "SlashCommand")
end

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local currentVersion = "@project-version@"
function DLP:EDIT_MODE_LAYOUTS_UPDATED(bucketedArgs)
    local layoutInfo = nil
    for k, v in pairs(bucketedArgs) do
        if k ~= nil then
            layoutInfo = k
            break
        end
    end

    if layoutInfo == nil then
        self:Print("There was an issue retrieving layoutInfo on startup, please report this issue on github @ McTalian/DeviceLayoutPreset")
        return
    end

    local desired = self.db.global.presetIndexOnLogin
    layouts = EditModeManagerFrame:GetLayouts()
    if desired <= 0 or desired > table.getn(layouts) then
        self:Print("Visit the addon options (/dlp) to select the Edit Mode preset for this device.")
        self.db.global.presetIndexOnLogin = 0
    elseif layoutInfo.activeLayout ~= desired then
        EditModeManagerFrame:SelectLayout(desired)
        self:Print("Successfully loaded your device layout: \"" .. layouts[desired].layoutName .. "\" - Have a fun session!")
    else
        local isNewVersion = currentVersion ~= self.db.global.lastVersionLoaded
        if isNewVersion then
            self:Print("Welcome! Have a fun session! (" .. currentVersion .. ")")
            self.db.global.lastVersionLoaded = currentVersion
        end
    end
    self:UnregisterBucket(self.bucketHandle)
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
        self.optionsFrame = acd:AddToBlizOptions(addonName, addonName)
    end
end

function DLP:SetPreset(info, value)
    self.db.global.presetIndexOnLogin = value
end

function DLP:GetPreset(info)
    return self.db.global.presetIndexOnLogin
end

function DLP:SlashCommand(msg, editBox)
    acd:Open(addonName)
end
