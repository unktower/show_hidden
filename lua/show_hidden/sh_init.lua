ShowHidden.TriggerType = {
	OTHER = 1, -- Unusual trigger_multiple
	TELEPORT = 2, -- Absolute or relative teleport
	TELE_FILTER = 3, -- Teleport with filter
	PUSH = 4, -- trigger_push based booster
	BASEVEL = 5, -- https://gamebanana.com/prefabs/7118
	GRAVITY = 6, -- https://gamebanana.com/prefabs/6677
	ANTIPRE = 7, -- https://gamebanana.com/prefabs/6760
	PLATFORM = 8, -- Any targetname manipulating thing
	MAX = 8,
}

ShowHidden.TRACK_TRIGGERS = {
	["trigger_teleport_relative"] = true,
	["trigger_teleport"] = true,
	["trigger_push"] = true,
	["trigger_multiple"] = true,
}

-- Calculate bitmask with all triggers enabled
ShowHidden.ALL_TYPES = math.pow(2, ShowHidden.TriggerType.MAX) - 1

function ShowHidden.CheckMask(mask, shift)
	return bit.band(mask, bit.rol(1, shift - 1)) ~= 0
end
