
local AddonName, Addon = ...
if not Addon.auraList then return end --don't run if we have nothing to work with

local band = bit.band
local playerClass = select(2, UnitClass("player"))
local playerName = UnitName("player")
local playerGUID = UnitGUID("player")
local iconSpellList = {}
local spellNameList = {}
local lastCastTarget
local lastCastID
local hasCasted
local lastPlayerTime = GetTime()
local doUpdate = false

local auraList = Addon.auraList[playerClass]

--trigger scans
local triggers = {
	["PARTY_LEADER_CHANGED"] = true,
	["PARTY_MEMBERS_CHANGED"] = true,
	["RAID_ROSTER_UPDATE"] = true,
	["CHARACTER_POINTS_CHANGED"] = true,
	["PLAYER_TALENT_UPDATE"] = true,
	["PLAYER_DEAD"] = true,
	["PLAYER_ALIVE"] = true,
	["ZONE_CHANGED_NEW_AREA"] = true,
	["PLAYER_REGEN_DISABLED"] = true,
	["PLAYER_REGEN_ENABLED"] = true,
}

local f = CreateFrame("frame","xanAuraTracker",UIParent)
f:SetScript("OnEvent", function(self, event, ...) 
	if self[event] then 
		return self[event](self, event, ...)
	elseif triggers[event] and self["doFullScan"] then
		return self["doFullScan"](self, event, ...)
	end 
end)

----------------------
--      Enable      --
----------------------

function f:PLAYER_LOGIN()

	if not xanAT_DB then xanAT_DB = {} end
	if xanAT_DB.size == nil then xanAT_DB.size = 35 end
	if xanAT_DB.enable == nil then xanAT_DB.enable = true end

	self:CreateAnchor("XAT_Anchor", UIParent, "xanAuraTracker Anchor")
	self:CreateFrames()
	self:RestoreLayout("XAT_Anchor")
	
	--just in case
	playerName = UnitName("player")
	playerClass = select(2, UnitClass("player"))
	playerGUID = UnitGUID("player")
	
	SLASH_XANAURATRACKER1 = "/xanat";
	SlashCmdList["XANAURATRACKER"] = xanAT_SlashCommand;
	
	local ver = GetAddOnMetadata("xanAuraTracker","Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFFDF2B2B%s|r] loaded:   /xanat", "xanAuraTracker", ver or "1.0"))
	
	self:doFullScan("PLAYER_LOGIN") --do initial scan
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	
	--activate triggers
	self:RegisterEvent("PARTY_LEADER_CHANGED")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("CHARACTER_POINTS_CHANGED")
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("UNIT_SPELLCAST_SENT")

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

function xanAT_SlashCommand(cmd)

	local a,b,c=strfind(cmd, "(%S+)"); --contiguous string of non-space characters
	
	if a then
		if c and c:lower() == "lock" then
			if not InCombatLockdown() and _G["XAT_Anchor"] then
				if _G["XAT_Anchor"]:IsVisible() then
					_G["XAT_Anchor"]:Hide()
				else
					_G["XAT_Anchor"]:Show()
				end
			end
			return true
		elseif c and c:lower() == "reset" then
			DEFAULT_CHAT_FRAME:AddMessage("xanAuraTracker: Frame position has been reset!");
			XAT_Anchor:ClearAllPoints()
			XAT_Anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			return true
		elseif c and c:lower() == "enable" then
			if xanAT_DB.enable then
				xanAT_DB.enable = false
				xanAuraTracker:disableAddon()
				DEFAULT_CHAT_FRAME:AddMessage("xanAuraTracker: addon disabled!");
			else
				xanAT_DB.enable = true
				xanAuraTracker:doFullScan("PLAYER_LOGIN")
				DEFAULT_CHAT_FRAME:AddMessage("xanAuraTracker: addon enabled!");
			end
			return true
		elseif c and c:lower() == "size" then
			if b then
				local sizenum = strsub(cmd, b+2)
				if sizenum and sizenum ~= "" and tonumber(sizenum) then
					xanAT_DB.size = tonumber(sizenum)
					ReloadUI()
					return true
				end
			end
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage("xanAuraTracker");
	DEFAULT_CHAT_FRAME:AddMessage("/xanat reset - resets the frame position");
	DEFAULT_CHAT_FRAME:AddMessage("/xanat enable - toggles on/off the addon for current player");
	DEFAULT_CHAT_FRAME:AddMessage("/xanat lock - toggles locked frame");
	DEFAULT_CHAT_FRAME:AddMessage("/xanat size # - Set the size of the xanAuraTracker icons")
end

------------------------------
--        UTF8 Fix          --
------------------------------

--SOURCE: http://wowprogramming.com/snippets/UTF-8_aware_stringsub_7

-- UTF-8 Reference:
-- 0xxxxxxx - 1 byte UTF-8 codepoint (ASCII character)
-- 110yyyxx - First byte of a 2 byte UTF-8 codepoint
-- 1110yyyy - First byte of a 3 byte UTF-8 codepoint
-- 11110zzz - First byte of a 4 byte UTF-8 codepoint
-- 10xxxxxx - Inner byte of a multi-byte UTF-8 codepoint
 
local function chsize(char)
    if not char then
        return 0
    elseif char > 240 then
        return 4
    elseif char > 225 then
        return 3
    elseif char > 192 then
        return 2
    else
        return 1
    end
end
 
-- This function can return a substring of a UTF-8 string, properly handling
-- UTF-8 codepoints.  Rather than taking a start index and optionally an end
-- index, it takes the string, the starting character, and the number of
-- characters to select from the string.
 
local function utf8sub(str, startChar, numChars)
  local startIndex = 1
  while startChar > 1 do
      local char = string.byte(str, startIndex)
      startIndex = startIndex + chsize(char)
      startChar = startChar - 1
  end
 
  local currentIndex = startIndex
 
  while numChars > 0 and currentIndex <= #str do
    local char = string.byte(str, currentIndex)
    currentIndex = currentIndex + chsize(char)
    numChars = numChars -1
  end
  return str:sub(startIndex, currentIndex - 1)
end

------------------------------
--         Frames           --
------------------------------

function f:CreateAnchor(name, parent, desc)

	--create the anchor
	local frameAnchor = CreateFrame("Frame", name, parent)
	
	frameAnchor:SetWidth(25)
	frameAnchor:SetHeight(25)
	frameAnchor:SetMovable(true)
	frameAnchor:SetClampedToScreen(true)
	frameAnchor:EnableMouse(true)

	frameAnchor:ClearAllPoints()
	frameAnchor:SetPoint("CENTER", parent, "CENTER", 0, 0)
	frameAnchor:SetFrameStrata("DIALOG")
	
	frameAnchor:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 5, right = 5, top = 5, bottom = 5 }
	})
	frameAnchor:SetBackdropColor(0.75,0,0,1)
	frameAnchor:SetBackdropBorderColor(0.75,0,0,1)

	frameAnchor:SetScript("OnLeave",function(self)
		GameTooltip:Hide()
	end)

	frameAnchor:SetScript("OnEnter",function(self)
	
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		GameTooltip:SetPoint(self:SetTip(self))
		GameTooltip:ClearLines()
		
		GameTooltip:AddLine(name)
		if desc then
			GameTooltip:AddLine(desc)
		end
		GameTooltip:Show()
	end)

	frameAnchor:SetScript("OnMouseDown", function(frame, button)
		if frame:IsMovable() then
			frame.isMoving = true
			frame:StartMoving()
		end
	end)

	frameAnchor:SetScript("OnMouseUp", function(frame, button) 
		if( frame.isMoving ) then
			frame.isMoving = nil
			frame:StopMovingOrSizing()
			f:SaveLayout(frame:GetName())
		end
	end)
	
	function frameAnchor:SetTip(frame)
		local x,y = frame:GetCenter()
		if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
		local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
		local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
		return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
	end

	frameAnchor:Hide() -- hide it by default
	
	f:RestoreLayout(name)
end

function f:CreateFrames()
	
	local sWdith = xanAT_DB.size
	local sHeight = xanAT_DB.size
	local adj = 0

	--loop de loop for frame creation
	for i=1, #auraList do
	
		local valChk = auraList[i]
		local name, _, icon = GetSpellInfo(valChk.spellID)
		
		if name then
			if i == 1 then
				local tmp = CreateFrame("frame", "xanAT"..i, UIParent)
				tmp:SetWidth(sWdith)
				tmp:SetHeight(sHeight)
				tmp:SetPoint("TOPLEFT", XAT_Anchor, "BOTTOMRIGHT", 0, 0)
				tmp.canCastOther = valChk.canCastOther or false
				tmp.alertChargeNum = valChk.alertChargeNum or nil
				tmp.showTargetName = valChk.showTargetName or nil
				tmp.useRaidWarn = valChk.useRaidWarn or false
				tmp.useChatWarn = valChk.useChatWarn or false
				tmp.warnTextColor = valChk.warnTextColor or {0.52, 0.96, 0.23}
				local t = tmp:CreateTexture("$parentIcon", "ARTWORK")
				t:SetTexture(icon)
				t:SetWidth(sWdith)
				t:SetHeight(sHeight)
				t:SetPoint("TOPLEFT", XAT_Anchor, "BOTTOMRIGHT", 0, 0)
				local g = tmp:CreateFontString("$parentCount", "OVERLAY")
				g:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
				g:SetTextColor( 0.52, 0.96, 0.23)
				g:SetJustifyH("LEFT")
				g:SetPoint("CENTER",0)
				local w = tmp:CreateFontString("$parentTopName", "OVERLAY")
				w:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
				w:SetWidth(sWdith+15)
				w:SetNonSpaceWrap(false)
				w:SetTextColor( 0.52, 0.96, 0.23)
				w:SetJustifyH("LEFT")
				w:SetPoint("TOPLEFT",-2, 15)
				tmp:Show()
				adj = adj + (sWdith + 3)
			else
				local tmp = CreateFrame("frame", "xanAT"..i, UIParent)
				tmp:SetWidth(sWdith)
				tmp:SetHeight(sHeight)
				tmp:SetPoint("TOPLEFT", XAT_Anchor, "BOTTOMRIGHT", adj, 0)
				tmp.canCastOther = valChk.canCastOther or false
				tmp.alertChargeNum = valChk.alertChargeNum or nil
				tmp.showTargetName = valChk.showTargetName or nil
				tmp.useRaidWarn = valChk.useRaidWarn or false
				tmp.useChatWarn = valChk.useChatWarn or false
				tmp.warnTextColor = valChk.warnTextColor or {0.52, 0.96, 0.23}
				local t = tmp:CreateTexture("$parentIcon", "ARTWORK")
				t:SetTexture(icon)
				t:SetWidth(sWdith)
				t:SetHeight(sHeight)
				t:SetPoint("TOPLEFT", XAT_Anchor, "BOTTOMRIGHT", adj, 0)
				local g = tmp:CreateFontString("$parentCount", "OVERLAY")
				g:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
				g:SetTextColor( 0.52, 0.96, 0.23)
				g:SetJustifyH("CENTER")
				g:SetPoint("CENTER",0)
				local w = tmp:CreateFontString("$parentTopName", "OVERLAY")
				w:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
				w:SetWidth(sWdith+15)
				w:SetNonSpaceWrap(false)
				w:SetTextColor( 0.52, 0.96, 0.23)
				w:SetJustifyH("LEFT")
				w:SetPoint("TOPLEFT",-2, 15)
				tmp:Show()
				adj = adj + (sWdith + 3)
			end
			
			--add spell to check list including referrID's
			iconSpellList[valChk.spellID] = i
			if valChk.referrID then
				for q=1, #valChk.referrID do
					iconSpellList[valChk.referrID[q]] = i
				end
			end
			
			--store spellname
			spellNameList[name] = valChk.spellID
		end
	end
end

function f:SaveLayout(frame)
	if type(frame) ~= "string" then return end
	if not _G[frame] then return end
	if not xanAT_DB then xanAT_DB = {} end
	
	local opt = xanAT_DB[frame] or nil

	if not opt then
		xanAT_DB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = xanAT_DB[frame]
		return
	end

	local point, relativeTo, relativePoint, xOfs, yOfs = _G[frame]:GetPoint()
	opt.point = point
	opt.relativePoint = relativePoint
	opt.xOfs = xOfs
	opt.yOfs = yOfs
end

function f:RestoreLayout(frame)
	if type(frame) ~= "string" then return end
	if not _G[frame] then return end
	if not xanAT_DB then xanAT_DB = {} end

	local opt = xanAT_DB[frame] or nil

	if not opt then
		xanAT_DB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = xanAT_DB[frame]
	end

	_G[frame]:ClearAllPoints()
	_G[frame]:SetPoint(opt.point, UIParent, opt.relativePoint, opt.xOfs, opt.yOfs)
end

------------------------------
--         AURAS            --
------------------------------

local eventSwitch = {
	["SPELL_AURA_APPLIED"] = true,
	["SPELL_AURA_REMOVED"] = true,
	["SPELL_AURA_REFRESH"] = true,
	["SPELL_AURA_APPLIED_DOSE"] = true,
	["SPELL_AURA_APPLIED_REMOVED_DOSE"] = true,
	["SPELL_AURA_REMOVED_DOSE"] = true,
	["SPELL_AURA_BROKEN"] = true,
	["SPELL_AURA_BROKEN_SPELL"] = true,
	["ENCHANT_REMOVED"] = true,
	["ENCHANT_APPLIED"] = true,
	["SPELL_CAST_SUCCESS"] = true,
	["SPELL_PERIODIC_ENERGIZE"] = true,
	["SPELL_ENERGIZE"] = true,
	["SPELL_PERIODIC_HEAL"] = true,
	["SPELL_HEAL"] = true,
	["SPELL_DAMAGE"] = true,
	["SPELL_PERIODIC_DAMAGE"] = true,
}

local function rgbhex(r, g, b)
  if type(r) == "table" then
	if r.r then
	  r, g, b = r.r, r.g, r.b
	else
	  r, g, b = unpack(r)
	end
  end
  return string.format("|cff%02x%02x%02x", (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
end

function f:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, hideCaster, sourceGUID, sourceName, srcFlags, sourceRaidFlags, dstGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, auraType, amount)
	if not xanAT_DB.enable then return end

	if eventSwitch[eventType] and band(srcFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 then
		if spellID and iconSpellList[spellID] then
			--print(eventType, sourceGUID, sourceName, destName, dstGUID, spellID, spellName, auraType, amount, band(srcFlags, COMBATLOG_OBJECT_AFFILIATION_MINE))
			f:doScanUpdate(spellID, spellName, dstGUID, destName, sourceGUID, sourceName, eventType)
		end 
    end
end

--this function is used to track what was cast and when, to prevent alerts from refresh auras and replacement aura on different targets
function f:UNIT_SPELLCAST_SENT(event, unit, spell, rank, target)
	if not xanAT_DB.enable then return end
	if unit ~= "player" then return end
	if not spellNameList[spell] then
		--spell not on list so reset everything so that spell removal can be triggered because of lastCastTarget
		hasCasted = true
		lastCastID = nil
		lastCastTarget = nil
		return
	end
	--we use this to track refreshes or newly casted overwrites
	hasCasted = true
	lastCastID = spellNameList[spell]
	lastPlayerTime = GetTime()
	if target and string.len(target) > 0 then
		lastCastTarget = target:match("^([^-]+)")
	else
		lastCastTarget = playerName
	end
end

function f:doFullScan(eventType)
	if not xanAT_DB.enable then return end
	--print('doFullScan',eventType)
	
	for i=1, #auraList do
	
		local valChk = auraList[i]
		local hasShown = false
		local spellname, auraname, charges, caster, unitName = GetSpellInfo(valChk.spellID)
		
		if spellname and _G["xanAT"..i] then
		
			--lets do the player first
			unitName, auraname, charges, caster = nil, nil, nil, nil --just in case
			auraname, _, _, charges, _, _, _, caster = UnitAura("player", spellname)
			if charges and charges < 1 then charges = nil end
			if auraname and caster == "player" then
				_G["xanAT"..i]:SetAlpha(1)
				_G["xanAT"..i.."Count"]:SetText(charges)
				_G["xanAT"..i].charges = charges or nil
				if valChk.alertChargeNum and charges and charges <= valChk.alertChargeNum then
					_G["xanAT"..i.."Count"]:SetTextColor( 1, 0, 0)
				else
					_G["xanAT"..i.."Count"]:SetTextColor( 0.52, 0.96, 0.23)
				end
				if valChk.showTargetName then
					_G["xanAT"..i.."TopName"]:SetText(utf8sub(playerName, 1, 5))
				else
					_G["xanAT"..i.."TopName"]:SetText("")
				end
				_G["xanAT"..i].targetN = playerName
				hasShown = true
				--print('player', playerName, caster, charges)
			end
			
			--time to check the raid!
			if not hasShown and valChk.canCastOther and GetNumGroupMembers() > 0 then
				for q = 1, GetNumGroupMembers() do
					unitName, auraname, charges, caster = nil, nil, nil, nil --just in case
					unitName = UnitName("raid"..q) and UnitName("raid"..q):match("^([^-]+)")
					auraname, _, _, charges, _, _, _, caster = UnitAura("raid"..q, spellname)
					if charges and charges < 1 then charges = nil end
					
					if auraname and unitName ~= playerName and caster == "player" then
						_G["xanAT"..i]:SetAlpha(1)
						_G["xanAT"..i.."Count"]:SetText(charges)
						_G["xanAT"..i].charges = charges or nil
						if valChk.alertChargeNum and charges and charges <= valChk.alertChargeNum then
							_G["xanAT"..i.."Count"]:SetTextColor( 1, 0, 0)
						else
							_G["xanAT"..i.."Count"]:SetTextColor( 0.52, 0.96, 0.23)
						end
						if valChk.showTargetName then
							_G["xanAT"..i.."TopName"]:SetText(utf8sub(unitName, 1, 5))
						else
							_G["xanAT"..i.."TopName"]:SetText("")
						end
						_G["xanAT"..i].targetN = unitName
						hasShown = true
						--print("raid"..q, unitName, caster, charges)
						break
					end
					
					--check pets
					unitName, auraname, charges, caster = nil, nil, nil, nil --just in case
					unitName = UnitName("raid"..q.."pet") and UnitName("raid"..q.."pet"):match("^([^-]+)")
					auraname, _, _, charges, _, _, _, caster = UnitAura("raid"..q.."pet", spellname)
					if charges and charges < 1 then charges = nil end
					
					if auraname and unitName ~= playerName and caster == "player" then
						_G["xanAT"..i]:SetAlpha(1)
						_G["xanAT"..i.."Count"]:SetText(charges)
						_G["xanAT"..i].charges = charges or nil
						if valChk.alertChargeNum and charges and charges <= valChk.alertChargeNum then
							_G["xanAT"..i.."Count"]:SetTextColor( 1, 0, 0)
						else
							_G["xanAT"..i.."Count"]:SetTextColor( 0.52, 0.96, 0.23)
						end
						if valChk.showTargetName then
							_G["xanAT"..i.."TopName"]:SetText(utf8sub(unitName, 1, 5))
						else
							_G["xanAT"..i.."TopName"]:SetText("")
						end
						_G["xanAT"..i].targetN = unitName
						hasShown = true
						--print("raid"..q.."pet", unitName, caster, charges)
						break
					end
				end
				
			--otherwise lets check the party
			elseif not hasShown and valChk.canCastOther and GetNumGroupMembers() > 0 then
				for q = 1, GetNumGroupMembers() do
					unitName, auraname, charges, caster = nil, nil, nil, nil --just in case
					unitName = UnitName("party"..q) and UnitName("party"..q):match("^([^-]+)")
					auraname, _, _, charges, _, _, _, caster = UnitAura("party"..q, spellname)
					if charges and charges < 1 then charges = nil end
					
					if auraname and unitName ~= playerName and caster == "player" then
						_G["xanAT"..i]:SetAlpha(1)
						_G["xanAT"..i.."Count"]:SetText(charges)
						_G["xanAT"..i].charges = charges or nil
						if valChk.alertChargeNum and charges and charges <= valChk.alertChargeNum then
							_G["xanAT"..i.."Count"]:SetTextColor( 1, 0, 0)
						else
							_G["xanAT"..i.."Count"]:SetTextColor( 0.52, 0.96, 0.23)
						end
						if valChk.showTargetName then
							_G["xanAT"..i.."TopName"]:SetText(utf8sub(unitName, 1, 5))
						else
							_G["xanAT"..i.."TopName"]:SetText("")
						end
						_G["xanAT"..i].targetN = unitName
						hasShown = true
						--print("party"..q, unitName, caster, charges)
						break
					end
					
					--check pets
					unitName, auraname, charges, caster = nil, nil, nil, nil --just in case
					unitName = UnitName("party"..q.."pet") and UnitName("party"..q.."pet"):match("^([^-]+)")
					auraname, _, _, charges, _, _, _, caster = UnitAura("party"..q.."pet", spellname)
					if charges and charges < 1 then charges = nil end
					
					if auraname and unitName ~= playerName and caster == "player" then
						_G["xanAT"..i]:SetAlpha(1)
						_G["xanAT"..i.."Count"]:SetText(charges)
						_G["xanAT"..i].charges = charges or nil
						if valChk.alertChargeNum and charges and charges <= valChk.alertChargeNum then
							_G["xanAT"..i.."Count"]:SetTextColor( 1, 0, 0)
						else
							_G["xanAT"..i.."Count"]:SetTextColor( 0.52, 0.96, 0.23)
						end
						if valChk.showTargetName then
							_G["xanAT"..i.."TopName"]:SetText(utf8sub(unitName, 1, 5))
						else
							_G["xanAT"..i.."TopName"]:SetText("")
						end
						_G["xanAT"..i].targetN = unitName
						hasShown = true
						--print("party"..q.."pet", unitName, caster, charges)
						break
					end
				end
				
			end
			
			--lets check our current target as a last resort
			if not hasShown then
				unitName, auraname, charges, caster = nil, nil, nil, nil --just in case
				auraname, _, _, charges, _, _, _, caster = UnitAura("target", spellname)
				unitName = UnitName("target") and UnitName("target"):match("^([^-]+)")
				if charges and charges < 1 then charges = nil end
				
				if auraname and unitName and caster == "player" then
					_G["xanAT"..i]:SetAlpha(1)
					_G["xanAT"..i.."Count"]:SetText(charges)
					_G["xanAT"..i].charges = charges or nil
					if valChk.alertChargeNum and charges and charges <= valChk.alertChargeNum then
						_G["xanAT"..i.."Count"]:SetTextColor( 1, 0, 0)
					else
						_G["xanAT"..i.."Count"]:SetTextColor( 0.52, 0.96, 0.23)
					end
					if valChk.showTargetName then
						_G["xanAT"..i.."TopName"]:SetText(utf8sub(unitName, 1, 5))
					else
						_G["xanAT"..i.."TopName"]:SetText("")
					end
					_G["xanAT"..i].targetN = unitName
					hasShown = true
					--print("target", unitName, caster, charges)
				end
			end
			
			--finally if nothing was shown reset it
			if not hasShown then
				--hide everything first
				_G["xanAT"..i]:SetAlpha(0)
				_G["xanAT"..i.."Count"]:SetText("")
				_G["xanAT"..i.."TopName"]:SetText("")
				_G["xanAT"..i].charges = nil
				_G["xanAT"..i].targetN = nil
			end
			
		end
	end
	
end

function f:disableAddon()
	--print('disable')
	for i=1, #auraList do
		local valChk = auraList[i]
		local spellname, auraname, charges, caster, unitName = GetSpellInfo(valChk.spellID)

		if spellname and _G["xanAT"..i] then
			_G["xanAT"..i]:SetAlpha(0)
		end
	end
	
end

--sometimes SPELL_CAST_SUCCESS gets sent but the SPELL_AURA_APPLIED doesn't get transmitted
--When this happens usually UnitAura will return incorrect data.  Therefore we are going to trigger a update after SPELL_CAST_SUCCESS, SPELL_AURA_APPLIED, SPELL_AURA_REFRESH just in case!
f:SetScript("OnUpdate", function(self, elapsed)
	if self.timer and self.timer > 0 then
		self.timer = self.timer - elapsed
		if self.timer <= 0 then
			self:doFullScan("SPELL_CAST_SUCCESS")
		end
	end
end)

function f:doScanUpdate(spellID, spellName, dstGUID, destName, sourceGUID, sourceName, eventType)
	if not xanAT_DB.enable then return end
	
	--check for refreshes or overwrites
	if eventType == "SPELL_AURA_REMOVED" then
		--check for previous casts, usually means one was removed to replace another.  In which case we want to ignore the replaced to prevent alert sound
		local nameChk = destName and destName:match("^([^-]+)")
		local nameChkSrc = sourceName and sourceName:match("^([^-]+)")
		local valChk = auraList[iconSpellList[spellID]]
		local text, color
		local passChk = false
		
		if nameChk and valChk and valChk.alertSound and _G["xanAT"..iconSpellList[spellID]] then
			
			if dstGUID == playerGUID and sourceGUID == playerGUID then
				--there will be situations where a spell is being removed from us while we cast something else on us, example switching shields.
				--when this happens it's sorta hard to track that due to current api.  So we will instead check for an incoming SPELL_CAST_SUCCESS
				--if the difference between the last SPELL_AURA_REMOVED and UNIT_SPELLCAST_SENT is less then 1, that means it was done literally at the same moment.
				--which means we switched shields because one was removed while the other was applied
				if (GetTime() - lastPlayerTime) >= 1 then
					passChk = true
				end
			elseif spellID ~= lastCastID and nameChk ~= lastCastTarget and _G["xanAT"..iconSpellList[spellID]].targetN == nameChk then
				--we just recently casted something but the spell being removed isn't the one we just casted, so double check and then play sound
				--and the destination target isn't our last target
				passChk = true
			end
			
			if passChk then
				PlaySoundFile(valChk.alertSound, "Master")
				
				--do alert text notifications
				local color = valChk.warnTextColor or {0.52, 0.96, 0.23}
				
				if valChk.canCastOther then
					text = string.format("%s faded from %s!", spellName, nameChk == playerName and YOU or nameChk)
				else
					text = string.format("%s faded from %s!", spellName, YOU)
				end
					
				if valChk.useRaidWarn and text then
					RaidNotice_AddMessage(RaidWarningFrame, text, { r = color[1], g = color[2], b = color[3] })
				end
				if valChk.useChatWarn and text then
					DEFAULT_CHAT_FRAME:AddMessage(rgbhex(unpack(color))..text.."|r")
				end
			end
			
		end
		hasCasted = false
		lastCastTarget = nil
		lastCastID = nil
	end

	if hasCasted and eventType ~= "SPELL_CAST_SUCCESS" then
		hasCasted = false
		lastCastTarget = nil
		lastCastID = nil
	end

	--trigger a refresh
	f:doFullScan(eventType)
	
	--this is for slight combatlog delay
	if eventType == "SPELL_CAST_SUCCESS" or eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
		--trigger the timer
		f.timer = 0.5
	end
	
end

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
