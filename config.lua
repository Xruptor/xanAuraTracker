
local AddonName, Addon = ...

Addon.auraList = {
	["MONK"]	= {
		[1] = { --shuffle
			spec = 1, --(first of the dual spec, can only have 2, so this can be either 1 or 2)
			spellID = 115307,
		},
		[2] = { --Elusive Brew Stacks
			spec = 1,
			spellID = 128939,
		},
		[3] = { --Guard
			spec = 1,
			spellID = 115295,
		},
		[4] = { --Light/Moderate/Heavy Stagger.  parent is Light Stagger.
			spec = 1,
			spellID = 124275,
			referrID = {124274,124273},
		},
		[5] = { --Power Guard
			spec = 1,
			spellID = 118636,
		},
	},
}

local playerClass = select(2, UnitClass("player"))
if not Addon.auraList[playerClass] then Addon.auraList = nil return end --don't run unless we have to