local _, AddOn = ...
local UnitGUID, GetRealmName, GetPlayerInfoByGUID = UnitGUID, GetRealmName, GetPlayerInfoByGUID
local tonumber, strmatch = tonumber, strmatch
local Utils = {}

-- Item Type
local LE_ITEM_CLASS_ARMOR = Enum.ItemClass.Armor
local LE_ITEM_CLASS_WEAPON = Enum.ItemClass.Weapon

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
		[LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_PLATE,
			LE_ITEM_ARMOR_GENERIC
		},
		[LE_ITEM_CLASS_WEAPON] = {
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
		[LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_LEATHER,
			LE_ITEM_ARMOR_GENERIC
		},
		[LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_AXE1H,
			LE_ITEM_WEAPON_DAGGER,
			LE_ITEM_WEAPON_UNARMED,
			LE_ITEM_WEAPON_MACE1H,
			LE_ITEM_WEAPON_SWORD1H,
			LE_ITEM_WEAPON_WARGLAIVE
		}
	},
	["DRUID"] = {
		[LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_LEATHER,
			LE_ITEM_ARMOR_GENERIC
		},
		[LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_DAGGER,
			LE_ITEM_WEAPON_UNARMED,
			LE_ITEM_WEAPON_MACE1H,
			LE_ITEM_WEAPON_POLEARM,
			LE_ITEM_WEAPON_STAFF,
			LE_ITEM_WEAPON_MACE2H
		}
	},
	["HUNTER"] = {
		[LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_MAIL,
			LE_ITEM_ARMOR_GENERIC
		},
		[LE_ITEM_CLASS_WEAPON] = {
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
		[LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_CLOTH,
			LE_ITEM_ARMOR_GENERIC
		},
		[LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_DAGGER,
			LE_ITEM_WEAPON_STAFF,
			LE_ITEM_WEAPON_SWORD1H,
			LE_ITEM_WEAPON_WAND
		}
	},
	["MONK"] = {
		[LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_LEATHER,
			LE_ITEM_ARMOR_GENERIC
		},
		[LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_AXE1H,
			LE_ITEM_WEAPON_UNARMED,
			LE_ITEM_WEAPON_MACE1H,
			LE_ITEM_WEAPON_POLEARM,
			LE_ITEM_WEAPON_STAFF,
			LE_ITEM_WEAPON_SWORD1H
		}
	},
	["PALADIN"] = {
		[LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_PLATE,
			LE_ITEM_ARMOR_GENERIC,
			LE_ITEM_ARMOR_SHIELD
		},
		[LE_ITEM_CLASS_WEAPON] = {
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
		[LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_CLOTH,
			LE_ITEM_ARMOR_GENERIC
		},
		[LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_DAGGER,
			LE_ITEM_WEAPON_MACE1H,
			LE_ITEM_WEAPON_STAFF,
			LE_ITEM_WEAPON_WAND
		}
	},
	["ROGUE"] = {
		[LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_LEATHER,
			LE_ITEM_ARMOR_GENERIC
		},
		[LE_ITEM_CLASS_WEAPON] = {
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
		[LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_MAIL,
			LE_ITEM_ARMOR_GENERIC,
			LE_ITEM_ARMOR_SHIELD
		},
		[LE_ITEM_CLASS_WEAPON] = {
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
		[LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_CLOTH,
			LE_ITEM_ARMOR_GENERIC
		},
		[LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_DAGGER,
			LE_ITEM_WEAPON_SWORD1H,
			LE_ITEM_WEAPON_STAFF,
			LE_ITEM_WEAPON_WAND
		}
	},
	["WARRIOR"] = {
		[LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_PLATE,
			LE_ITEM_ARMOR_GENERIC,
			LE_ITEM_ARMOR_SHIELD
		},
		[LE_ITEM_CLASS_WEAPON] = {
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
		[LE_ITEM_CLASS_ARMOR] = {
			LE_ITEM_ARMOR_MAIL,
			LE_ITEM_ARMOR_GENERIC
		},
		[LE_ITEM_CLASS_WEAPON] = {
			LE_ITEM_WEAPON_AXE1H,
			LE_ITEM_WEAPON_DAGGER,
			LE_ITEM_WEAPON_MACE1H,
			LE_ITEM_WEAPON_STAFF,
			LE_ITEM_WEAPON_SWORD1H
		}
	}
}

function Utils.GetItemIDFromLink(link)
	return tonumber(strmatch(link or "", "item:(%d+):"))
end
