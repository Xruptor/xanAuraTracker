
local AddonName, Addon = ...

Addon.auraList = {
	["MONK"]	= {
		[1] = { --shuffle
			spec = 1, --(first of the dual spec, can only have 2, so this can be either 1 or 2)
			spellID = 115307,
			--referrID = {52128},
		},
		[2] = { --shuffle
			spec = 1, --(first of the dual spec, can only have 2, so this can be either 1 or 2)
			spellID = 117666,
			referrID = {115921},
		},
		[3] = { --shuffle
			spec = 1, --(first of the dual spec, can only have 2, so this can be either 1 or 2)
			spellID = 115307,
			--referrID = {52128},
		},
	},
}

local playerClass = select(2, UnitClass("player"))
if not Addon.auraList[playerClass] then Addon.auraList = nil return end --don't run unless we have to