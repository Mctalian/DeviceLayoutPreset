---@type string, table
local _, ns = ...

---@class DLP_ns
local G_DLP = ns

---@diagnostic disable-next-line: param-type-mismatch
local L = LibStub("AceLocale-3.0"):NewLocale(G_DLP.localeName, "ptPT")
if not L then
	return
end
