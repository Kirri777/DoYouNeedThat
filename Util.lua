local _, AddOn = ...
local UnitGUID, GetRealmName, GetPlayerInfoByGUID = UnitGUID, GetRealmName, GetPlayerInfoByGUID
local tonumber, strmatch = tonumber, strmatch
local Utils = {}

-- Item Type
Utils.LE_ITEM_CLASS_ARMOR = Enum.ItemClass.Armor
Utils.LE_ITEM_CLASS_WEAPON = Enum.ItemClass.Weapon
Utils.LE_ITEM_CLASS_MISCELLANEOUS = Enum.ItemArmorSubclass.Generic

-- Weapon
local LE_ITEM_ARMOR_GENERIC = Enum.ItemWeaponSubclass.Generic
local LE_ITEM_WEAPON_AXE1H = Enum.ItemWeaponSubclass.Axe1H
local LE_ITEM_WEAPON_MACE1H = Enum.ItemWeaponSubclass.Mace1H
local LE_ITEM_WEAPON_POLEARM = Enum.ItemWeaponSubclass.Polearm
local LE_ITEM_WEAPON_SWORD1H = Enum.ItemWeaponSubclass.Sword1H
local LE_ITEM_WEAPON_MACE2H = Enum.ItemWeaponSubclass.Mace2H
local LE_ITEM_WEAPON_SWORD2H = Enum.ItemWeaponSubclass.Sword2H
local LE_ITEM_WEAPON_WARGLAIVE = Enum.ItemWeaponSubclass.Warglaive
local LE_ITEM_WEAPON_STAFF = Enum.ItemWeaponSubclass.Staff
local LE_ITEM_WEAPON_UNARMED = Enum.ItemWeaponSubclass.Unarmed
local LE_ITEM_WEAPON_DAGGER = Enum.ItemWeaponSubclass.Dagger
local LE_ITEM_WEAPON_BOWS = Enum.ItemWeaponSubclass.Bows
local LE_ITEM_WEAPON_CROSSBOW = Enum.ItemWeaponSubclass.Crossbow
local LE_ITEM_WEAPON_GUNS = Enum.ItemWeaponSubclass.Guns
local LE_ITEM_WEAPON_WAND = Enum.ItemWeaponSubclass.Wand
local LE_ITEM_WEAPON_AXE2H = Enum.ItemWeaponSubclass.Axe2H

-- Armor
local LE_ITEM_ARMOR_CLOTH = Enum.ItemArmorSubclass.Cloth
local LE_ITEM_ARMOR_LEATHER = Enum.ItemArmorSubclass.Leather
local LE_ITEM_ARMOR_MAIL = Enum.ItemArmorSubclass.Mail
local LE_ITEM_ARMOR_PLATE = Enum.ItemArmorSubclass.Plate
local LE_ITEM_ARMOR_SHIELD = Enum.ItemArmorSubclass.Shield

AddOn.Utils = Utils

function Utils.GetUnitNameWithRealm(unit)
	local guid = UnitGUID(unit)
	if guid ~= nil then
		local _, _, _, _, _, name, realm = GetPlayerInfoByGUID(guid)
		if not realm or realm == '' then
			realm = GetRealmName()
		end
		return name .. '-' .. realm
	else
		return nil
	end
end

function Utils.GetSlotID(itemEquipLoc)
	if itemEquipLoc == 'INVTYPE_HEAD' then return INVSLOT_HEAD
	elseif itemEquipLoc == 'INVTYPE_NECK' then return INVSLOT_NECK
	elseif itemEquipLoc == 'INVTYPE_SHOULDER' then return INVSLOT_SHOULDER
	elseif itemEquipLoc == 'BODY' then return INVSLOT_BODY
	elseif itemEquipLoc == 'INVTYPE_CHEST' then return INVSLOT_CHEST
	elseif itemEquipLoc == 'INVTYPE_ROBE' then return INVSLOT_CHEST
	elseif itemEquipLoc == 'INVTYPE_WAIST' then return INVSLOT_WAIST
	elseif itemEquipLoc == 'INVTYPE_LEGS' then return INVSLOT_LEGS
	elseif itemEquipLoc == 'INVTYPE_FEET' then return INVSLOT_FEET
	elseif itemEquipLoc == 'INVTYPE_WRIST' then return INVSLOT_WRIST
	elseif itemEquipLoc == 'INVTYPE_HAND' then return INVSLOT_HAND
	elseif itemEquipLoc == 'INVTYPE_FINGER' then return INVSLOT_FINGER1
	elseif itemEquipLoc == 'INVTYPE_TRINKET' then return INVSLOT_TRINKET1
	elseif itemEquipLoc == 'INVTYPE_CLOAK' then return INVSLOT_BACK
	elseif itemEquipLoc == 'INVTYPE_WEAPON' then return INVSLOT_MAINHAND
	elseif itemEquipLoc == 'INVTYPE_SHIELD' then return INVSLOT_OFFHAND
	elseif itemEquipLoc == 'INVTYPE_2HWEAPON' then return INVSLOT_MAINHAND
	elseif itemEquipLoc == 'INVTYPE_WEAPONMAINHAND' then return INVSLOT_MAINHAND
	elseif itemEquipLoc == 'INVTYPE_WEAPONOFFHAND' then return INVSLOT_OFFHAND
	elseif itemEquipLoc == 'INVTYPE_HOLDABLE' then return INVSLOT_OFFHAND
	elseif itemEquipLoc == 'INVTYPE_RANGED' then return INVSLOT_MAINHAND
	elseif itemEquipLoc == 'INVTYPE_THROWN' then return INVSLOT_MAINHAND
	elseif itemEquipLoc == 'INVTYPE_RANGEDRIGHT' then return INVSLOT_MAINHAND
	elseif itemEquipLoc == 'INVTYPE_RELIC' then return INVSLOT_MAINHAND
	elseif itemEquipLoc == 'INVTYPE_TABARD' then return INVSLOT_TABARD
	else return nil
	end
end

Utils.ValidGear = {
	["DEATHKNIGHT"] = {
		[Utils.LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_PLATE,
			LE_ITEM_ARMOR_GENERIC
		},
		[Utils.LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_AXE1H,
			LE_ITEM_WEAPON_MACE1H,
			LE_ITEM_WEAPON_POLEARM,
			LE_ITEM_WEAPON_SWORD1H,
			LE_ITEM_WEAPON_AXE2H,
			LE_ITEM_WEAPON_MACE2H,
			LE_ITEM_WEAPON_SWORD2H
		}
	},
	["DEMONHUNTER"] = {
		[Utils.LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_LEATHER,
			LE_ITEM_ARMOR_GENERIC
		},
		[Utils.LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_AXE1H,
			LE_ITEM_WEAPON_DAGGER,
			LE_ITEM_WEAPON_UNARMED,
			LE_ITEM_WEAPON_MACE1H,
			LE_ITEM_WEAPON_SWORD1H,
			LE_ITEM_WEAPON_WARGLAIVE
		}
	},
	["DRUID"] = {
		[Utils.LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_LEATHER,
			LE_ITEM_ARMOR_GENERIC
		},
		[Utils.LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_DAGGER,
			LE_ITEM_WEAPON_UNARMED,
			LE_ITEM_WEAPON_MACE1H,
			LE_ITEM_WEAPON_POLEARM,
			LE_ITEM_WEAPON_STAFF,
			LE_ITEM_WEAPON_MACE2H
		}
	},
	["HUNTER"] = {
		[Utils.LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_MAIL,
			LE_ITEM_ARMOR_GENERIC
		},
		[Utils.LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_AXE1H,
			LE_ITEM_WEAPON_DAGGER,
			LE_ITEM_WEAPON_UNARMED,
			LE_ITEM_WEAPON_POLEARM,
			LE_ITEM_WEAPON_STAFF,
			LE_ITEM_WEAPON_SWORD1H,
			LE_ITEM_WEAPON_AXE2H,
			LE_ITEM_WEAPON_SWORD2H,
			LE_ITEM_WEAPON_BOWS,
			LE_ITEM_WEAPON_CROSSBOW,
			LE_ITEM_WEAPON_GUNS
		}
	},
	["MAGE"] = {
		[Utils.LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_CLOTH,
			LE_ITEM_ARMOR_GENERIC
		},
		[Utils.LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_DAGGER,
			LE_ITEM_WEAPON_STAFF,
			LE_ITEM_WEAPON_SWORD1H,
			LE_ITEM_WEAPON_WAND
		}
	},
	["MONK"] = {
		[Utils.LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_LEATHER,
			LE_ITEM_ARMOR_GENERIC
		},
		[Utils.LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_AXE1H,
			LE_ITEM_WEAPON_UNARMED,
			LE_ITEM_WEAPON_MACE1H,
			LE_ITEM_WEAPON_POLEARM,
			LE_ITEM_WEAPON_STAFF,
			LE_ITEM_WEAPON_SWORD1H
		}
	},
	["PALADIN"] = {
		[Utils.LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_PLATE,
			LE_ITEM_ARMOR_GENERIC,
			LE_ITEM_ARMOR_SHIELD
		},
		[Utils.LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_AXE1H,
			LE_ITEM_WEAPON_MACE1H,
			LE_ITEM_WEAPON_POLEARM,
			LE_ITEM_WEAPON_SWORD1H,
			LE_ITEM_WEAPON_AXE2H,
			LE_ITEM_WEAPON_MACE2H,
			LE_ITEM_WEAPON_SWORD2H
		}
	},
	["PRIEST"] = {
		[Utils.LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_CLOTH,
			LE_ITEM_ARMOR_GENERIC
		},
		[Utils.LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_DAGGER,
			LE_ITEM_WEAPON_MACE1H,
			LE_ITEM_WEAPON_STAFF,
			LE_ITEM_WEAPON_WAND
		}
	},
	["ROGUE"] = {
		[Utils.LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_LEATHER,
			LE_ITEM_ARMOR_GENERIC
		},
		[Utils.LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_AXE1H,
			LE_ITEM_WEAPON_DAGGER,
			LE_ITEM_WEAPON_UNARMED,
			LE_ITEM_WEAPON_MACE1H,
			LE_ITEM_WEAPON_SWORD1H,
			LE_ITEM_WEAPON_BOWS,
			LE_ITEM_WEAPON_CROSSBOW,
			LE_ITEM_WEAPON_GUNS
		}
	},
	["SHAMAN"] = {
		[Utils.LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_MAIL,
			LE_ITEM_ARMOR_GENERIC,
			LE_ITEM_ARMOR_SHIELD
		},
		[Utils.LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_AXE1H,
			LE_ITEM_WEAPON_DAGGER,
			LE_ITEM_WEAPON_UNARMED,
			LE_ITEM_WEAPON_MACE1H,
			LE_ITEM_WEAPON_STAFF,
			LE_ITEM_WEAPON_AXE2H,
			LE_ITEM_WEAPON_MACE2H
		}
	},
	["WARLOCK"] = {
		[Utils.LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_CLOTH,
			LE_ITEM_ARMOR_GENERIC
		},
		[Utils.LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_DAGGER,
			LE_ITEM_WEAPON_SWORD1H,
			LE_ITEM_WEAPON_STAFF,
			LE_ITEM_WEAPON_WAND
		}
	},
	["WARRIOR"] = {
		[Utils.LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_PLATE,
			LE_ITEM_ARMOR_GENERIC,
			LE_ITEM_ARMOR_SHIELD
		},
		[Utils.LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_AXE1H,
			LE_ITEM_WEAPON_DAGGER,
			LE_ITEM_WEAPON_UNARMED,
			LE_ITEM_WEAPON_MACE1H,
			LE_ITEM_WEAPON_POLEARM,
			LE_ITEM_WEAPON_STAFF,
			LE_ITEM_WEAPON_SWORD1H,
			LE_ITEM_WEAPON_AXE2H,
			LE_ITEM_WEAPON_MACE2H,
			LE_ITEM_WEAPON_SWORD2H,
			LE_ITEM_WEAPON_BOWS,
			LE_ITEM_WEAPON_CROSSBOW,
			LE_ITEM_WEAPON_GUNS
		}
	},
	["EVOKER"] = {
		[Utils.LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_MAIL,
			LE_ITEM_ARMOR_GENERIC
		},
		[Utils.LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_AXE1H,
			LE_ITEM_WEAPON_DAGGER,
			LE_ITEM_WEAPON_MACE1H,
			LE_ITEM_WEAPON_STAFF,
			LE_ITEM_WEAPON_SWORD1H
		}
	}
}

Utils.GearForClass = {
	["DEATHKNIGHT"] = LE_ITEM_ARMOR_PLATE,
	["DEMONHUNTER"] = LE_ITEM_ARMOR_LEATHER,
	["DRUID"] = LE_ITEM_ARMOR_LEATHER,
	["HUNTER"] = LE_ITEM_ARMOR_MAIL,
	["MAGE"] = LE_ITEM_ARMOR_CLOTH,
	["MONK"] = LE_ITEM_ARMOR_LEATHER,
	["PALADIN"] = LE_ITEM_ARMOR_PLATE,
	["PRIEST"] = LE_ITEM_ARMOR_CLOTH,
	["ROGUE"] = LE_ITEM_ARMOR_LEATHER,
	["SHAMAN"] = LE_ITEM_ARMOR_MAIL,
	["WARLOCK"] = LE_ITEM_ARMOR_CLOTH,
	["WARRIOR"] = LE_ITEM_ARMOR_PLATE,
	["EVOKER"] = LE_ITEM_ARMOR_MAIL
}

Utils.ValidGearTokens = {
	["ALL"] = {
		203647, -- Primalist Ring
		203649, -- Primalist Trinket
		203650, -- Primalist Weapon
		203646, -- Primalist Cloak
		203648, -- Primalist Necklace
	},
	[LE_ITEM_ARMOR_PLATE] = {
		203615, -- Primalist Plate Chestpiece
		203611, -- Primalist Plate Helm
		203626, -- Primalist Plate Spaulders
		203633, -- Primalist Plate Bracers
		203643, -- Primalist Plate Gloves
		203634, -- Primalist Plate Belt
		203623, -- Primalist Plate Leggings
		203640, -- Primalist Plate Boots
	},
	[LE_ITEM_ARMOR_MAIL] = {
		203617, -- Primalist Leather Chestpiece
		203613, -- Primalist Leather Helm
		203628, -- Primalist Leather Spaulders
		203631, -- Primalist Leather Bracers
		203644, -- Primalist Leather Gloves
		203636, -- Primalist Leather Belt
		203620, -- Primalist Leather Leggings
		203639, -- Primalist Leather Boots
	},
	[LE_ITEM_ARMOR_LEATHER] = {
		203618, -- Primalist Leather Chestpiece
		203614, -- Primalist Leather Helm
		203629, -- Primalist Leather Spaulders
		203630, -- Primalist Leather Bracers
		203645, -- Primalist Leather Gloves
		203637, -- Primalist Leather Belt
		203619, -- Primalist Leather Leggings
		203638, -- Primalist Leather Boots
	},
	[LE_ITEM_ARMOR_CLOTH] = {
		203616, -- Primalist Cloth Chestpiece
		203612, -- Primalist Cloth Helm
		203627, -- Primalist Cloth Spaulders
		203632, -- Primalist Cloth Bracers
		203642, -- Primalist Cloth Gloves
		203635, -- Primalist Cloth Belt
		203622, -- Primalist Cloth Leggings
		203641, -- Primalist Cloth Boots
	},
}

function Utils.GetItemIDFromLink(link)
	return tonumber(strmatch(link or "", "item:(%d+):"))
end
