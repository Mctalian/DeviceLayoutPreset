---@type string, table
local _, ns = ...

---@class DLP_ns
local G_DLP = ns

---@class DLP_Locale
G_DLP.L = LibStub("AceLocale-3.0"):GetLocale(G_DLP.localeName)
