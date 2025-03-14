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
            disabled = function()
                return DLP.db.char.specs.enabled
            end,
            order = 2,
        },
        specs = {
            type = "group",
            name = G_DLP.L["OPTIONS_SPECS_NAME"],
            inline = true,
            args = {
                desc = {
                    type = "description",
                    name = G_DLP.L["OPTIONS_SPECS_DESC"],
                    order = 1
                },
                enable = {
                    type = "toggle",
                    name = G_DLP.L["OPTIONS_SPECS_ENABLE"],
                    desc = G_DLP.L["OPTIONS_SPECS_ENABLE_DESC"],
                    width = "full",
                    get = function()
                        return DLP.db.char.specs.enabled
                    end,
                    set = function(info, value)
                        DLP.db.char.specs.enabled = value
                    end,
                    order = 2
                }
            },
            order = 3
        }
    }
}

local defaults = {
    global = {
        presetIndexOnLogin = 0,
        lastVersionLoaded = "v1.0.0"
    },
    char = {
        specs = {
            enabled = false,
        }
    },
}

local layouts = nil
local repoUrl = "https://github.com/McTalian/DeviceLayoutPreset"
local currentVersion = "@project-version@"

function DLP:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("DeviceLayoutPresetDB", defaults, true)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options)
    self:InitializeOptions()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.bucketHandle = self:RegisterBucketEvent("EDIT_MODE_LAYOUTS_UPDATED", 0.2, "EDIT_MODE_LAYOUTS_UPDATED")
    self:RegisterBucketEvent("PLAYER_SPECIALIZATION_CHANGED", 0.2)
    self:SecureHook(C_EditMode, "OnLayoutDeleted", "OnLayoutDeleted")
    self:SecureHook(C_EditMode, "OnLayoutAdded", "OnLayoutAdded")
    self:RegisterChatCommand("dlp", "SlashCommand")
    self:RegisterChatCommand("devicelayoutpreset", "SlashCommand")
    self:RegisterChatCommand("deviceLayoutPreset", "SlashCommand")
end

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
    local type = G_DLP.L["LAYOUT_TYPE_DEVICE"]
    if self.db.char.specs.enabled then
        local specId = PlayerUtil.GetCurrentSpecID()
        if self.db.char.specs[specId] ~= nil then
            desired = self.db.char.specs[specId]
            type = G_DLP.L["LAYOUT_TYPE_SPEC"]
        end
    end
    layouts = EditModeManagerFrame:GetLayouts()
    if desired <= 0 or desired > #layouts then
        self:Print(G_DLP.L["ERROR_LAYOUT_INVALID"])
        self.db.global.presetIndexOnLogin = 0
    elseif layoutInfo.activeLayout ~= desired then
        EditModeManagerFrame:SelectLayout(desired)
        self:Printf(G_DLP.L["SUCCESS_LOADED_LAYOUT"], type, layouts[desired].layoutName)
    else
        local isNewVersion = currentVersion ~= self.db.global.lastVersionLoaded
        if isNewVersion then
            self:Printf(G_DLP.L["WELCOME_NEW_VERSION"], currentVersion)
            self.db.global.lastVersionLoaded = currentVersion
        end
    end
    self:UnregisterBucket(self.bucketHandle)
end

function DLP:PLAYER_SPECIALIZATION_CHANGED()
    if not self.db.char.specs.enabled then
        return
    end
    local type = G_DLP.L["LAYOUT_TYPE_SPEC"]
    local specId = PlayerUtil.GetCurrentSpecID()
    if self.db.char.specs[specId] == nil then
        self:Print(G_DLP.L["ERROR_LAYOUT_INVALID"])
        self.db.char.specs[specId] = 0
        return
    end
    layouts = EditModeManagerFrame:GetLayouts()
    local desired = self.db.char.specs[specId]
    if desired <= 0 or desired > #layouts then
        self:Print(G_DLP.L["ERROR_LAYOUT_INVALID"])
        self.db.char.specs[specId] = 0
    else
        EditModeManagerFrame:SelectLayout(desired)
        self:Printf(G_DLP.L["SUCCESS_LOADED_LAYOUT"], type, layouts[desired].layoutName)
    end
end

---@class Spec
---@field specId number
---@field specName string
---@field specDesc string
---@field specIcon number
---@field specRole string
---@field specPrimaryStat number

function DLP:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
    local numSpecs = GetNumSpecializations()
    ---@type table<number, Spec>
    self.specs = {}
    for i = 1, numSpecs do
        local specID, specName, specDesc, specIcon, specRole, specPrimaryStat = GetSpecializationInfo(i)
        self.specs[specID] = {
            specId = specID,
            specName = specName,
            specDesc = specDesc,
            specIcon = specIcon,
            specRole = specRole,
            specPrimaryStat = specPrimaryStat
        }
    end

    local i = 0
    for k, v in pairs(self.specs) do
        i = i + 1
        options.args.specs.args["spec" .. k] = {
            type = "select",
            name = v.specName,
            desc = v.specDesc,
            icon = v.specIcon,
            disabled = function()
                return not DLP.db.char.specs.enabled
            end,
            values = function()
                return DLP:GetLayouts()
            end,
            get = function()
                return DLP.db.char.specs[k]
            end,
            set = function(info, value)
                DLP.db.char.specs[k] = value
            end,
            order = 2 + i
        }
    end

    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
end

function DLP:OnLayoutDeleted(deletedIndex)
    if deletedIndex == self.db.global.presetIndexOnLogin then
        self:Print(G_DLP.L["EVENT_DELETED_LAYOUT"])
        self.db.global.presetIndexOnLogin = 0
    end
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
end

function DLP:OnLayoutAdded()
    self:Print(G_DLP.L["EVENT_CREATED_LAYOUT"])
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
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
        self.optionsFrame = acd:AddToBlizOptions(addonName)
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
