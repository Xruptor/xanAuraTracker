local settingsTable = {}
local tRows, tAnchor = {}
local currentPlayer = UnitName('player')
local currentRealm = GetRealmName()
local playerSpec = GetActiveSpecGroup()
local GetSpellInfo = _G['GetSpellInfo']
local SILVER = '|cffc7c7cf%s|r'
local MOSS = '|cFF80FF00%s|r'

local xatSettings = CreateFrame("Frame","XanAuraTracker_SettingsFrame", UIParent)

local debugf = tekDebug and tekDebug:GetFrame("xanAuraTracker")
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

local function LoadSlider()
	
	local function OnEnter(self)
		if self.name and self.tooltip then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetSpellByID(self.tooltip)
			GameTooltip:Show()
		end
	end
	
	local function OnLeave() GameTooltip:Hide() end

	local EDGEGAP, ROWHEIGHT, ROWGAP, GAP = 40, 20, 2, 4
	local FRAME_HEIGHT = xatSettings:GetHeight() - 50
	local SCROLL_TOP_POSITION = -80
	local totaltRows = math.floor((FRAME_HEIGHT-22)/(ROWHEIGHT + ROWGAP))
	
	for i=1, totaltRows do
		if not tRows[i] then
			local row = CreateFrame("Button", nil, xatSettings)
			if not tAnchor then row:SetPoint("BOTTOMLEFT", xatSettings, "TOPLEFT", 0, SCROLL_TOP_POSITION)
			else row:SetPoint("TOP", tAnchor, "BOTTOM", 0, -ROWGAP) end
			row:SetPoint("LEFT", EDGEGAP, 0)
			row:SetPoint("RIGHT", -EDGEGAP*1-8, 0)
			row:SetHeight(ROWHEIGHT)
			row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
			tAnchor = row
			tRows[i] = row

			local title = row:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
			title:SetPoint("LEFT")
			title:SetJustifyH("LEFT") 
			title:SetWidth(row:GetWidth())
			title:SetHeight(ROWHEIGHT)
			row.title = title

			local icon = row:CreateTexture(nil,"OVERLAY")
			icon:SetPoint("LEFT", (ROWHEIGHT * -1) -3, 0)
			icon:SetWidth(ROWHEIGHT)
			icon:SetHeight(ROWHEIGHT)
			icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			icon:Hide()
			row.icon = icon
	
			row:SetScript("OnEnter", OnEnter)
			row:SetScript("OnLeave", OnLeave)
		end
	end

	local offset = 0
	local RefreshSettings = function()
		if not XanAuraTracker_SettingsFrame:IsVisible() then return end
		
		for i,row in ipairs(tRows) do
			if (i + offset) <= #settingsTable then
				if settingsTable[i + offset] then

					if settingsTable[i + offset].isHeader then
						row.title:SetText("|cFFFFFFFF"..settingsTable[i + offset].name.."|r")
					else
						row.title:SetText(settingsTable[i + offset].name)
					end
					
					--header texture and parameters
					if settingsTable[i + offset].isHeader then
						row:LockHighlight()
						row.title:SetJustifyH("CENTER") 
						row.tooltip = nil
					else
						row:UnlockHighlight()
						row.title:SetJustifyH("LEFT")
						row.name = row.title:GetText()
						row.tooltip = settingsTable[i + offset].tooltip
					end
					
					row.icon:SetTexture(settingsTable[i + offset].icon or nil)
					row.icon:Show()
					row:Show()
				end
			else
				row.icon:SetTexture(nil)
				row.icon:Hide()
				row:Hide()
			end
		end
	end

	RefreshSettings()

	if not xatSettings.scrollbar then
		xatSettings.scrollbar = LibStub("tekKonfig-Scroll").new(xatSettings, nil, #tRows/2)
		xatSettings.scrollbar:ClearAllPoints()
		xatSettings.scrollbar:SetPoint("TOP", tRows[1], 0, -16)
		xatSettings.scrollbar:SetPoint("BOTTOM", tRows[#tRows], 0, 16)
		xatSettings.scrollbar:SetPoint("RIGHT", -16, 0)
	end
	
	if #settingsTable > 0 then
		xatSettings.scrollbar:SetMinMaxValues(0, math.max(0, #settingsTable - #tRows))
		xatSettings.scrollbar:SetValue(0)
		xatSettings.scrollbar:Show()
	else
		xatSettings.scrollbar:Hide()
	end

	local f = xatSettings.scrollbar:GetScript("OnValueChanged")
	xatSettings.scrollbar:SetScript("OnValueChanged", function(self, value, ...)
		offset = math.floor(value)
		RefreshSettings()
		return f(self, value, ...)
	end)

	xatSettings:EnableMouseWheel()
	xatSettings:SetScript("OnMouseWheel", function(self, val)
		xatSettings.scrollbar:SetValue(xatSettings.scrollbar:GetValue() - val*#tRows/2)
	end)
end

local function BuildSettingsFrame()
	if not xanAT_DB or not xanAT_DB[currentPlayer] then return end
	
	local xdb = xanAT_DB[currentPlayer]
	if not xdb.auraList then return end
	Debug("Building Settings")
	settingsTable = {} --reset
	local tmp = {}
	
	--loop through our characters auras
	-----------------------------------
	for k, v in pairs(xdb.auraList) do
		tmp = {}
		--buffs/debuffs
		for q, r in pairs(v) do
			local spellName, spellRank, spellIcon = GetSpellInfo(q)
			if spellName then
				--Debug("Spell Found", spellName, spellIcon, k, q, r)
				table.insert(settingsTable, {name=spellName, icon=spellIcon, header=k, tooltip=q, specInfo=r})
			end
		end
	end
	-----------------------------------
	
	--sort it
	table.sort(settingsTable, function(a,b)
		if a.header < b.header then
			return true;
		elseif a.header == b.header then
			return (a.name < b.name);
		end
	end)
	
	--add headers
	local lastHeader = ""
	tmp = {} --reset
	
	for i=1, #settingsTable do
		if settingsTable[i].header ~= lastHeader then
			lastHeader = settingsTable[i].header
			table.insert(tmp, { name=lastHeader, header=lastHeader, isHeader=true } )
			table.insert(tmp, settingsTable[i])
		else
			table.insert(tmp, settingsTable[i])
		end
	end
	settingsTable = tmp

	LoadSlider()
end

xatSettings:SetFrameStrata("HIGH")
xatSettings:SetToplevel(true)
xatSettings:EnableMouse(true)
xatSettings:SetMovable(true)
xatSettings:SetClampedToScreen(true)
xatSettings:SetWidth(380)
xatSettings:SetHeight(500)

xatSettings:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 32,
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
})

xatSettings:SetBackdropColor(0,0,0,1)
xatSettings:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

local addonTitle = xatSettings:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
addonTitle:SetPoint("CENTER", xatSettings, "TOP", 0, -20)
addonTitle:SetText("|cFF99CC33xanAuraTracker|r")

local closeButton = CreateFrame("Button", nil, xatSettings, "UIPanelCloseButton");
closeButton:SetPoint("TOPRIGHT", xatSettings, -15, -8);

xatSettings:SetScript("OnShow", function(self) BuildSettingsFrame(); LoadSlider(); end)
xatSettings:SetScript("OnHide", function(self)
	settingsTable = {}
end)

xatSettings:SetScript("OnMouseDown", function(frame, button)
	if frame:IsMovable() then
		frame.isMoving = true
		frame:StartMoving()
	end
end)

xatSettings:SetScript("OnMouseUp", function(frame, button) 
	if( frame.isMoving ) then
		frame.isMoving = nil
		frame:StopMovingOrSizing()
	end
end)

xatSettings:Hide()