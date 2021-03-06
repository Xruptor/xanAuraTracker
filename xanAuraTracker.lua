local band = bit.band
local playerName = UnitName("player")
local iconSpellList = {}
local totalFrames = 0
local playerSpec = GetActiveSpecGroup()
local xdb = {}

--trigger scans
local triggers = {
	["CHARACTER_POINTS_CHANGED"] = true,
	["PLAYER_DEAD"] = true,
	["PLAYER_ALIVE"] = true,
	["ZONE_CHANGED_NEW_AREA"] = true,
	--["PLAYER_REGEN_DISABLED"] = true,
	--["PLAYER_REGEN_ENABLED"] = true,
	["GLYPH_ADDED"] = true,
	["GLYPH_REMOVED"] = true,
	["GLYPH_UPDATED"] = true,
	["ACTIVE_TALENT_GROUP_CHANGED"] = true,  --changed talents
}

local f = CreateFrame("frame","xanAuraTracker",UIParent)
f:SetScript("OnEvent", function(self, event, ...) 
	if self[event] then 
		return self[event](self, event, ...)
	elseif triggers[event] and self["doFullScan"] then
		return self["doFullScan"]()
	end 
end)

local debugf = tekDebug and tekDebug:GetFrame("xanAuraTracker")
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

----------------------
--      Enable      --
----------------------

function f:PLAYER_LOGIN()

	if not xanAT_DB then xanAT_DB = {} end
	if not xanAT_DB[playerName] then xanAT_DB[playerName] = {} end
	
	xdb = xanAT_DB[playerName]
	if xdb.size == nil then xdb.size = 35 end
	if xdb.enable == nil then xdb.enable = true end
	if xdb.auraList == nil then xdb.auraList = { buffs = {}, debuffs = {} } end

	self:CreateAnchor("XAT_Anchor", UIParent, "xanAuraTracker Anchor")
	--self:BuildAuraListFrames()
	self:RestoreLayout("XAT_Anchor")
	
	--just in case
	playerName = UnitName("player")
	playerSpec = GetActiveSpecGroup()
	
	SLASH_XANAURATRACKER1 = "/xanat";
	SlashCmdList["XANAURATRACKER"] = xanAT_SlashCommand;
	
	local ver = GetAddOnMetadata("xanAuraTracker","Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFFDF2B2B%s|r] loaded:   /xanat", "xanAuraTracker", ver or "1.0"))
	
	self:doFullScan() --do initial scan
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	
	--activate triggers
	self:RegisterEvent("CHARACTER_POINTS_CHANGED")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("GLYPH_ADDED")
	self:RegisterEvent("GLYPH_REMOVED")
	self:RegisterEvent("GLYPH_UPDATED")
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

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
			if xdb.enable then
				xdb.enable = false
				xanAuraTracker:disableAddon()
				DEFAULT_CHAT_FRAME:AddMessage("xanAuraTracker: addon disabled!");
			else
				xdb.enable = true
				xanAuraTracker:doFullScan()
				DEFAULT_CHAT_FRAME:AddMessage("xanAuraTracker: addon enabled!");
			end
			return true
		elseif c and c:lower() == "size" then
			if b then
				local sizenum = strsub(cmd, b+2)
				if sizenum and sizenum ~= "" and tonumber(sizenum) then
					xdb.size = tonumber(sizenum)
					ReloadUI()
					return true
				end
			end
		elseif c and c:lower() == "settings" then
			if XanAuraTracker_SettingsFrame:IsVisible() then
				XanAuraTracker_SettingsFrame:Hide()
			else
				XanAuraTracker_SettingsFrame:Show()
			end
			return true
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage("xanAuraTracker");
	DEFAULT_CHAT_FRAME:AddMessage("/xanat settings - displays the buff/debuff settings window");
	DEFAULT_CHAT_FRAME:AddMessage("/xanat reset - resets the frame position");
	DEFAULT_CHAT_FRAME:AddMessage("/xanat enable - toggles on/off the addon for current player");
	DEFAULT_CHAT_FRAME:AddMessage("/xanat lock - toggles locked frame");
	DEFAULT_CHAT_FRAME:AddMessage("/xanat size # - Set the size of the xanAuraTracker icons")
end

function f:ACTIVE_TALENT_GROUP_CHANGED(self, spec)
	playerSpec = GetActiveSpecGroup()
	f:BuildAuraListFrames()
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


local function GetTimeText(timeLeft)
	local hours, minutes, seconds = 0, 0, 0
	if( timeLeft >= 3600 ) then
		hours = ceil(timeLeft / 3600)
		timeLeft = mod(timeLeft, 3600)
	end

	if( timeLeft >= 60 ) then
		minutes = ceil(timeLeft / 60)
		timeLeft = mod(timeLeft, 60)
	end

	seconds = timeLeft > 0 and timeLeft or 0

	if hours > 0 then
		return string.format("%dh",hours)
	elseif minutes > 0 then
		return string.format("%dm",minutes)
	elseif seconds > 0 then
		return string.format("%ds",seconds)
	else
		return nil
	end
end

local TimerOnUpdate = function(self, time)

	if self.active then
		self.OnUpdateCounter = (self.OnUpdateCounter or 0) + time
		if self.OnUpdateCounter < 0.05 then return end
		self.OnUpdateCounter = 0

		local beforeEnd = self.endTime - GetTime()
		
		if beforeEnd < 0 then
			self.active = false
			self:Hide()
			return               
		end
		
		self.bottomtext:SetText(GetTimeText(beforeEnd))
	end
	
end

function f:CreateAuraFrame(sFrameIndex)
	
	local sWdith = xdb.size
	local sHeight = xdb.size

	if _G["xanAT"..sFrameIndex] then return _G["xanAT"..sFrameIndex] end
	
	local tmp = CreateFrame("frame", "xanAT"..sFrameIndex, UIParent)
	totalFrames = totalFrames + 1
	
	if sFrameIndex == 1 then
		tmp:SetWidth(sWdith)
		tmp:SetHeight(sHeight)
		tmp:SetPoint("TOPLEFT", XAT_Anchor, "BOTTOMRIGHT", 0, 0)
		local t = tmp:CreateTexture("$parentIcon", "ARTWORK")
		t:SetAllPoints(tmp)
		t:SetWidth(sWdith)
		t:SetHeight(sHeight)
		tmp.icon = t
		local g = tmp:CreateFontString("$parentCount", "OVERLAY")
		g:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
		g:SetTextColor( 0.52, 0.96, 0.23)
		g:SetJustifyH("LEFT")
		g:SetPoint("CENTER",0)
		tmp.count = g
		local w = tmp:CreateFontString("$parentTopText", "OVERLAY")
		w:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
		w:SetWidth(sWdith+15)
		w:SetNonSpaceWrap(false)
		w:SetTextColor( 0.52, 0.96, 0.23)
		w:SetJustifyH("LEFT")
		w:SetPoint("TOPLEFT",-2, 15)
		tmp.toptext = w
		local z = tmp:CreateFontString("$parentBottomText", "OVERLAY")
		z:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
		z:SetWidth(sWdith+15)
		z:SetNonSpaceWrap(false)
		z:SetTextColor( 0.52, 0.96, 0.23)
		z:SetJustifyH("CENTER")
		z:SetPoint("CENTER", tmp, "BOTTOM", 0, -9)
		tmp.bottomtext = z
	else
		tmp:SetWidth(sWdith)
		tmp:SetHeight(sHeight)
		tmp:SetPoint("TOPLEFT", _G["xanAT"..sFrameIndex-1], "TOPRIGHT", 3, 0)
		local t = tmp:CreateTexture("$parentIcon", "ARTWORK")
		t:SetAllPoints(tmp)
		t:SetWidth(sWdith)
		t:SetHeight(sHeight)
		tmp.icon = t
		local g = tmp:CreateFontString("$parentCount", "OVERLAY")
		g:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
		g:SetTextColor( 0.52, 0.96, 0.23)
		g:SetJustifyH("CENTER")
		g:SetPoint("CENTER",0)
		tmp.count = g
		local w = tmp:CreateFontString("$parentTopText", "OVERLAY")
		w:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
		w:SetWidth(sWdith+15)
		w:SetNonSpaceWrap(false)
		w:SetTextColor( 0.52, 0.96, 0.23)
		w:SetJustifyH("LEFT")
		w:SetPoint("TOPLEFT",-2, 15)
		tmp.toptext = w
		local z = tmp:CreateFontString("$parentBottomText", "OVERLAY")
		z:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
		z:SetWidth(sWdith+15)
		z:SetNonSpaceWrap(false)
		z:SetTextColor( 0.52, 0.96, 0.23)
		z:SetJustifyH("CENTER")
		z:SetPoint("CENTER", tmp, "BOTTOM", 0, -9)
		tmp.bottomtext = z
	end
	
	tmp:SetScript("OnUpdate", TimerOnUpdate)
	
	return tmp
end

function f:SaveLayout(frame)
	if type(frame) ~= "string" then return end
	if not _G[frame] then return end
	if not xdb.frames then xdb.frames = {} end
	
	local opt = xdb.frames[frame] or nil

	if not opt then
		xdb.frames[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = xdb.frames[frame]
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
	if not xdb.frames then xdb.frames = {} end

	local opt = xdb.frames[frame] or nil

	if not opt then
		xdb.frames[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = xdb.frames[frame]
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
	if not xdb.enable then return end
	if sourceGUID == UnitGUID("player") or sourceGUID == UnitGUID("pet") or band(srcFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 then
		--if eventType and eventSwitch[eventType] and spellID and iconSpellList[spellID] then
			f:doFullScan()
		--end
	end
end

function f:doFullScan()
	if not xdb.enable then return end
	
	local sChk = {}
	
	if xdb.auraList == nil then xdb.auraList = { buffs = {}, debuffs = {} } end
	if xdb.auraList.buffs == nil then xdb.auraList.buffs = { } end
	if xdb.auraList.debuffs == nil then xdb.auraList.debuffs = { } end

	local xbuff = xdb.auraList.buffs
	local xdebuff = xdb.auraList.debuffs
	
	--to cover all our bases and ignore the if aura is active hide, just scan all the auras, the chance of a player having all 40 filled is remote
	for i=1, 40 do -- loop through max 40 buffs
		local name, _, icon, charges, _, duration, expTime, unitCaster, _, _, spellId = UnitAura("player", i, "HELPFUL")
		if name == nil then break end
		
		if spellId and (unitCaster == "player" or unitCaster == "pet") and not xbuff[spellId] then
			xbuff[spellId] = "0,0"
		end
	end
	
	--to cover all our bases and ignore the if aura is active hide, just scan all the auras, the chance of a player having all 40 filled is remote
	for i=1, 40 do -- loop through max 40 buffs
		local name, _, icon, charges, _, duration, expTime, unitCaster, _, _, spellId = UnitAura("player", i, "HARMFUL")
		if name == nil then break end
		
		if spellId and (unitCaster == "player" or unitCaster == "pet") and not xdebuff[spellId] then
			xdebuff[spellId] = "0,0"
		end
	end

end

function f:disableAddon()
	for i=1, totalFrames do
		if _G["xanAT"..i] then
			_G["xanAT"..i]:Hide()
		end
	end
end

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
