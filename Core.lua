local addonName, ns = ...

---@class DLP_ns
local G_DLP = ns

---@class DeviceLayoutPreset: AceAddon, AceConsole-3.0, AceEvent-3.0, AceTimer-3.0, AceHook-3.0, AceBucket-3.0
local DLP = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0",
    "AceBucket-3.0")

G_DLP.DLP = DLP

---@type AceConfigDialog-3.0
local acd = LibStub("AceConfigDialog-3.0")

local options = {
    name = addonName,
    handler = DLP,
    type = "group",
    args = {
        desc = {
            type = "description",
            name = G_DLP.L["OPTIONS_DESC"],
            order = 0
        },
        howToDesc = {
            type = "group",
            name = G_DLP.L["OPTIONS_HOWTO_NAME"],
            inline = true,
            args = {
                step0 = {
                    type = "description",
                    name = G_DLP.L["OPTIONS_HOWTO_STEP0"],
                    order = 1
                },
                step1 = {
                    type = "description",
                    name = G_DLP.L["OPTIONS_HOWTO_STEP1"],
                    order = 2
                },
                step2 = {
                    type = "description",
                    name = G_DLP.L["OPTIONS_HOWTO_STEP2"],
                    order = 3
                },
                conclusion = {
                    type = "description",
                    name = G_DLP.L["OPTIONS_HOWTO_CONCLUSION"],
                    order = 4
                }
            },
            order = 1
        },
        preset = {
            type = "select",
            name = G_DLP.L["OPTIONS_PRESET_NAME"],
            desc = G_DLP.L["OPTIONS_PRESET_DESC"],
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
    global = {
        presetIndexOnLogin = 0,
        lastVersionLoaded = "v1.0.0"
    }
}

local layouts = nil

function DLP:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("DeviceLayoutPresetDB", defaults, true)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options)
    self:InitializeOptions()
    self.bucketHandle = self:RegisterBucketEvent("EDIT_MODE_LAYOUTS_UPDATED", 0.2, "EDIT_MODE_LAYOUTS_UPDATED")
    self:SecureHook(C_EditMode, "OnLayoutDeleted", "OnLayoutDeleted")
    self:SecureHook(C_EditMode, "OnLayoutAdded", "OnLayoutAdded")
    self:RegisterChatCommand("dlp", "SlashCommand")
    self:RegisterChatCommand("devicelayoutpreset", "SlashCommand")
    self:RegisterChatCommand("deviceLayoutPreset", "SlashCommand")
end

local repoUrl = "https://github.com/McTalian/DeviceLayoutPreset"
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
        self:Printf("%s @ %s", G_DLP.L["ERROR_NO_LAYOUT_INFO"], repoUrl)
        return
    end

    local desired = self.db.global.presetIndexOnLogin
    layouts = EditModeManagerFrame:GetLayouts()
    if desired <= 0 or desired > #layouts then
        self:Print(G_DLP.L["ERROR_LAYOUT_INVALID"])
        self.db.global.presetIndexOnLogin = 0
    elseif layoutInfo.activeLayout ~= desired then
        EditModeManagerFrame:SelectLayout(desired)
        self:Printf(G_DLP.L["SUCCESS_LOADED_LAYOUT"], layouts[desired].layoutName)
    else
        local isNewVersion = currentVersion ~= self.db.global.lastVersionLoaded
        if isNewVersion then
            self:Printf(G_DLP.L["WELCOME_NEW_VERSION"], currentVersion)
            self.db.global.lastVersionLoaded = currentVersion
        end
    end
    self:UnregisterBucket(self.bucketHandle)
end

function DLP:OnLayoutDeleted(deletedIndex)
    if deletedIndex == self.db.global.presetIndexOnLogin then
        self:Print(G_DLP.L["EVENT_DELETED_LAYOUT"])
        self.db.global.presetIndexOnLogin = 0
    end
end

function DLP:OnLayoutAdded()
    self:Print(G_DLP.L["EVENT_CREATED_LAYOUT"])
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
