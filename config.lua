
local AddonName, Addon = ...

Addon.auraList = {
	["SHAMAN"]	= {
		[1] = { --water shield
			spellID = 52127,
			canCastOther = false,
			alertSound = "Sound\\Doodad\\G_GongTroll01.wav",
			alertChargeNum = 1,
			referrID = {52128},
			useRaidWarn = true,
			useChatWarn = true,
			warnTextColor = { 0.4, 0.70, 0.96 },
		},
		[2] = { --earth shield
			spellID = 974,
			canCastOther = true,
			showTargetName = true,
			alertSound = "Sound\\Doodad\\BellTollHorde.wav",
			alertChargeNum = 3,
			referrID = {379},
			useRaidWarn = true,
			useChatWarn = true,
			warnTextColor = { 0.52, 0.96, 0.23 },
		},
		[3] = { --lightning shield
			spellID = 324,
			canCastOther = false,
			alertSound = "Sound\\Doodad\\BellTollAlliance.wav",
			alertChargeNum = 1,
			referrID = {26364, 88765}, --88765=rolling thudner
			useRaidWarn = true,
			useChatWarn = true,
			warnTextColor = { 0.15, 0.49, 1 },
		},
	},
	["PALADIN"]	= {
		[1] = { --beacon of light
			spellID = 53563,
			canCastOther = true,
			showTargetName = true,
			alertSound = "Sound\\Doodad\\BellTollHorde.wav",
			useRaidWarn = true,
			useChatWarn = true,
		},
	},
	["MAGE"] = {
		[1] = { --molten armor
			spellID = 30482,
			canCastOther = false,
			alertSound = "Sound\\Doodad\\G_GongTroll01.wav",
			useRaidWarn = true,
			useChatWarn = true,
		},
		[2] = { --frost armor
			spellID = 7302,
			canCastOther = false,
			alertSound = "Sound\\Doodad\\G_GongTroll01.wav",
			useRaidWarn = true,
			useChatWarn = true,
		},
		[3] = { --mage armor
			spellID = 6117,
			canCastOther = false,
			alertSound = "Sound\\Doodad\\G_GongTroll01.wav",
			useRaidWarn = true,
			useChatWarn = true,
		},
	},
}

local playerClass = select(2, UnitClass("player"))
if not Addon.auraList[playerClass] then Addon.auraList = nil return end --don't run unless we have to