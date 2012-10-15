
local AddonName, Addon = ...
if not Addon.auraList then return end --don't run if we have nothing to work with

local band = bit.band
local playerClass = select(2, UnitClass("player"))
local playerName = UnitName("player")
local playerGUID = UnitGUID("player")
local playerSpec = GetSpecialization()
local iconSpellList = {}

local auraList = Addon.auraList[playerClass]

--trigger scans
local triggers = {
	["CHARACTER_POINTS_CHANGED"] = true,
	["PLAYER_TALENT_UPDATE"] = true,
	["PLAYER_DEAD"] = true,
	["PLAYER_ALIVE"] = true,
	["ZONE_CHANGED_NEW_AREA"] = true,
	["PLAYER_REGEN_DISABLED"] = true,
	["PLAYER_REGEN_ENABLED"] = true,
	["GLYPH_ADDED"] = true,
	["GLYPH_REMOVED"] = true,
	["GLYPH_UPDATED"] = true,
	["PLAYER_SPECIALIZATION_CHANGED"] = true,
}

local f = CreateFrame("frame","xanAuraTracker",UIParent)
f:SetScript("OnEvent", function(self, event, ...) 
	if self[event] then 
		return self[event](self, event, ...)
	elseif triggers[event] and self["doFullScan"] then
		return self["doFullScan"]()
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
	self:BuildAuraListFrames()
	self:RestoreLayout("XAT_Anchor")
	
	--just in case
	playerName = UnitName("player")
	playerClass = select(2, UnitClass("player"))
	playerGUID = UnitGUID("player")
	playerSpec = GetSpecialization()
	
	SLASH_XANAURATRACKER1 = "/xanat";
	SlashCmdList["XANAURATRACKER"] = xanAT_SlashCommand;
	
	local ver = GetAddOnMetadata("xanAuraTracker","Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFFDF2B2B%s|r] loaded:   /xanat", "xanAuraTracker", ver or "1.0"))
	
	self:doFullScan() --do initial scan
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	
	--activate triggers
	self:RegisterEvent("CHARACTER_POINTS_CHANGED")
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("GLYPH_ADDED")
	self:RegisterEvent("GLYPH_REMOVED")
	self:RegisterEvent("GLYPH_UPDATED")
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

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
				xanAuraTracker:doFullScan()
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

function f:BuildAuraListFrames()
	
	local count = 0
	iconSpellList = {} --empty it out
	
	--loop de loop for frame creation
	for i=1, #auraList do
		local valChk = auraList[i]
		--only use the ones that match the player spec or if the spec is set to 0
		if valChk.spec == playerSpec or valChk.spec <= 0 then
			local name, _, icon = GetSpellInfo(valChk.spellID)
			if name then
				count = count + 1
				local tmp = f:CreateAuraFrame(count)
				tmp.icon:SetTexture(icon)
				tmp:Show()
				--add spell to check list including referrID's
				iconSpellList[valChk.spellID] = count
				if valChk.referrID then
					for q=1, #valChk.referrID do
						iconSpellList[valChk.referrID[q]] = count
					end
				end
			end
		end

	end
end

local adj = 0

function f:CreateAuraFrame(sFrameIndex)
	
	local sWdith = xanAT_DB.size
	local sHeight = xanAT_DB.size

	if _G["xanAT"..sFrameIndex] then return _G["xanAT"..sFrameIndex] end
	
	local tmp = CreateFrame("frame", "xanAT"..sFrameIndex, UIParent)
	
	if sFrameIndex == 1 then
		tmp:SetWidth(sWdith)
		tmp:SetHeight(sHeight)
		tmp:SetPoint("TOPLEFT", XAT_Anchor, "BOTTOMRIGHT", 0, 0)
		local t = tmp:CreateTexture("$parentIcon", "ARTWORK")
		t:SetWidth(sWdith)
		t:SetHeight(sHeight)
		t:SetPoint("TOPLEFT", XAT_Anchor, "BOTTOMRIGHT", 0, 0)
		tmp.icon = t
		local g = tmp:CreateFontString("$parentCount", "OVERLAY")
		g:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
		g:SetTextColor( 0.52, 0.96, 0.23)
		g:SetJustifyH("LEFT")
		g:SetPoint("CENTER",0)
		tmp.count = g
		local w = tmp:CreateFontString("$parentTopName", "OVERLAY")
		w:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
		w:SetWidth(sWdith+15)
		w:SetNonSpaceWrap(false)
		w:SetTextColor( 0.52, 0.96, 0.23)
		w:SetJustifyH("LEFT")
		w:SetPoint("TOPLEFT",-2, 15)
		tmp.toptext = w
	else
		tmp:SetWidth(sWdith)
		tmp:SetHeight(sHeight)
		tmp:SetPoint("TOPLEFT", XAT_Anchor, "BOTTOMRIGHT", adj, 0)
		local t = tmp:CreateTexture("$parentIcon", "ARTWORK")
		t:SetWidth(sWdith)
		t:SetHeight(sHeight)
		t:SetPoint("TOPLEFT", XAT_Anchor, "BOTTOMRIGHT", adj, 0)
		tmp.icon = t
		local g = tmp:CreateFontString("$parentCount", "OVERLAY")
		g:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
		g:SetTextColor( 0.52, 0.96, 0.23)
		g:SetJustifyH("CENTER")
		g:SetPoint("CENTER",0)
		tmp.count = g
		local w = tmp:CreateFontString("$parentTopName", "OVERLAY")
		w:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
		w:SetWidth(sWdith+15)
		w:SetNonSpaceWrap(false)
		w:SetTextColor( 0.52, 0.96, 0.23)
		w:SetJustifyH("LEFT")
		w:SetPoint("TOPLEFT",-2, 15)
		tmp.toptext = w
	end
	
	adj = adj + (sWdith + 3)
	
	return tmp
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

function f:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, hideCaster, sourceGUID, sourceName, srcFlags, sourceRaidFlags, dstGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, auraType, amount)
	if not xanAT_DB.enable then return end
	if sourceGUID ~= playerGUID then return end
	
	if eventSwitch[eventType] and spellID and iconSpellList[spellID] then
		f:doFullScan(spellID)
    end
end

function f:doFullScan(p_SpellID)
	if not xanAT_DB.enable then return end
	
	if p_SpellID and iconSpellList[p_SpellID] then
		--update the icon based on the timer
		--_G["xanAT"..iconSpellList[p_SpellID]]
		return
	end

	for i=1, 40 do -- loop through max 40 buffs
	
		local name, _, icon, charges, _, duration, expTime, unitCaster, _, _, spellId = UnitAura("player", i)
		if not name then return end
		
		if spellId and iconSpellList[spellId] and _G["xanAT"..iconSpellList[spellId]] then
			--_G["xanAT"..i]:SetAlpha(1)
			--_G["xanAT"..i.."Count"]:SetText(charges)
			--_G["xanAT"..i].charges = charges or nil
		end

	end
	
end

function f:disableAddon()
	for i=1, #auraList do
		if _G["xanAT"..i] then
			_G["xanAT"..i]:SetAlpha(0)
		end
	end
end

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
