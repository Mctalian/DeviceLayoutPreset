local addonName, ns = ...

---@class DLP_ns
local G_DLP = ns

---@class DeviceLayoutPreset: AceAddon, AceConsole-3.0, AceEvent-3.0, AceTimer-3.0, AceHook-3.0, AceBucket-3.0
local DLP = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0",
    "AceBucket-3.0")

G_DLP.DLP = DLP

-- From https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_PlayerSpells/ClassSpecializations/Blizzard_ClassSpecializationsFrame.lua#L13C1-L55C2
-- Will need to keep an eye out for changes in future patches
local SPEC_TEXTURE_FORMAT = "spec-thumbnail-%s";

local SPEC_FORMAT_STRINGS = {
	[62] = "mage-arcane",
	[63] = "mage-fire",
	[64] = "mage-frost",
	[65] = "paladin-holy",
	[66] = "paladin-protection",
	[70] = "paladin-retribution",
	[71] = "warrior-arms",
	[72] = "warrior-fury",
	[73] = "warrior-protection",
	[102] = "druid-balance",
	[103] = "druid-feral",
	[104] = "druid-guardian",
	[105] = "druid-restoration",
	[250] = "deathknight-blood",
	[251] = "deathknight-frost",
	[252] = "deathknight-unholy",
	[253] = "hunter-beastmastery",
	[254] = "hunter-marksmanship",
	[255] = "hunter-survival",
	[256] = "priest-discipline",
	[257] = "priest-holy",
	[258] = "priest-shadow",
	[259] = "rogue-assassination",
	[260] = "rogue-outlaw",
	[261] = "rogue-subtlety",
	[262] = "shaman-elemental",
	[263] = "shaman-enhancement",
	[264] = "shaman-restoration",
	[265] = "warlock-affliction",
	[266] = "warlock-demonology",
	[267] = "warlock-destruction",
	[268] = "monk-brewmaster",
	[269] = "monk-windwalker",
	[270] = "monk-mistweaver",
	[577] = "demonhunter-havoc",
	[581] = "demonhunter-vengeance",
	[1467] = "evoker-devastation",
	[1468] = "evoker-preservation",
	[1473] = "evoker-augmentation",
}

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
            },
            order = 3
        }
    }
}

local layouts = nil
local repoUrl = "https://github.com/McTalian/DeviceLayoutPreset"
local currentVersion = "@project-version@"
local SPEC_DEFAULT = -1
local DEVICE_DEFAULT = 0

local defaults = {
    global = {
        presetIndexOnLogin = DEVICE_DEFAULT,
        lastVersionLoaded = "v1.0.0"
    },
    char = {
        specs = {
            enabled = false,
        }
    },
}

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
        else
            self:Print(G_DLP.L["ERROR_LAYOUT_INVALID"])
            self.db.char.specs[specId] = SPEC_DEFAULT
            return
        end
        if desired == SPEC_DEFAULT then
            desired = self.db.global.presetIndexOnLogin
            type = G_DLP.L["LAYOUT_TYPE_DEVICE"]
        end
    end
    layouts = EditModeManagerFrame:GetLayouts()
    if desired <= DEVICE_DEFAULT or desired > #layouts then
        self:Print(G_DLP.L["ERROR_LAYOUT_INVALID"])
        self.db.global.presetIndexOnLogin = DEVICE_DEFAULT
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
    local type = G_DLP.L["LAYOUT_TYPE_SPEC"]
    local specId = PlayerUtil.GetCurrentSpecID()
    if self.db.char.specs[specId] == nil then
        self.db.char.specs[specId] = SPEC_DEFAULT
        return
    end
    layouts = EditModeManagerFrame:GetLayouts()
    local desired = self.db.char.specs[specId]
    if desired == SPEC_DEFAULT then
        desired = self.db.global.presetIndexOnLogin
        type = G_DLP.L["LAYOUT_TYPE_DEVICE"]
    end
    if desired <= DEVICE_DEFAULT or desired > #layouts then
        self:Print(G_DLP.L["ERROR_LAYOUT_INVALID"])
        self.db.char.specs[specId] = SPEC_DEFAULT
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
---@field specAtlasString string

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
            specPrimaryStat = specPrimaryStat,
            specAtlasString = string.format(
                "|A:%s:16:16:0:0|a",
                string.format(SPEC_TEXTURE_FORMAT, SPEC_FORMAT_STRINGS[specID])
            )
        }
    end

    local i = 0
    for k, v in pairs(self.specs) do
        i = i + 1
        if self.db.char.specs[k] == nil then
            self.db.char.specs[k] = SPEC_DEFAULT
        end
        options.args.specs.args["spec" .. k] = {
            type = "select",
            name = v.specName .. " " .. v.specAtlasString,
            desc = string.format(G_DLP.L["OPTIONS_SPECS_PRESET_DESC"], v.specName),
            values = function()
                return DLP:GetLayouts(true)
            end,
            get = function()
                return DLP.db.char.specs[k]
            end,
            set = function(info, value)
                DLP.db.char.specs[k] = value
            end,
            width = 1.5,
            order = 1 + i
        }
        i = i + 1
        options.args.specs.args["spacer" .. k] = {
            type = "description",
            name = "",
            order = 1 + i
        }
    end

    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
end

function DLP:OnLayoutDeleted(deletedIndex)
    if deletedIndex == self.db.global.presetIndexOnLogin then
        self:Print(G_DLP.L["EVENT_DELETED_LAYOUT"])
        self.db.global.presetIndexOnLogin = DEVICE_DEFAULT
    end
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
end

function DLP:OnLayoutAdded()
    self:Print(G_DLP.L["EVENT_CREATED_LAYOUT"])
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
end

---Get EditMode layouts
---@param forSpecs? boolean for specs, we will add a "Same as above" option
function DLP:GetLayouts(forSpecs)
    layouts = EditModeManagerFrame:GetLayouts()
    local values = {}
    if forSpecs then
        values[SPEC_DEFAULT] = G_DLP.L["DO_NOT_OVERRIDE"]
    end
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
