local PREFIX_CLIPS = "ShowClips"
local PREFIX_TRIGGERS = "ShowTriggers"
local COLOR_CLIPS = Color(255, 0, 123, 200)
local COLOR_TRIGGERS = Color(255, 192, 0, 200)

local MaterialEnum = {
	WIREFRAME = 0,
	DEFAULT = 1, -- trigger or player-clip texture
	SOLID = 2, -- solid color material
}

local function ChatMessage(prefix, phrase)
	local color = (prefix == PREFIX_CLIPS and COLOR_CLIPS or COLOR_TRIGGERS)
	chat.AddText(color_white, "[", color, prefix, color_white, "] ", language.GetPhrase(phrase))
end

-- TODO: refactor this file

-- [[ ShowTriggers ]] --

local ShowHidden, TriggerType = ShowHidden, ShowHidden.TriggerType
local render, ipairs, IsValid = render, ipairs, IsValid

local TRACE_TIMEOUT = 5
local DEFAULT_TRIGGERS_COLORS = {
	[TriggerType.PUSH] =        { color = Color(128, 255, 0, 255),  material = MaterialEnum.DEFAULT },
	[TriggerType.BASEVEL] =     { color = Color(0, 255, 0, 255),    material = MaterialEnum.DEFAULT },
	[TriggerType.GRAVITY] =     { color = Color(0, 255, 128, 255),  material = MaterialEnum.DEFAULT },
	[TriggerType.TELEPORT] =    { color = Color(255, 0, 0, 255),    material = MaterialEnum.DEFAULT },
	[TriggerType.TELE_FILTER] = { color = Color(255, 0, 128, 128),  material = MaterialEnum.DEFAULT },
	[TriggerType.ANTIPRE] =     { color = Color(192, 0, 255, 64),   material = MaterialEnum.SOLID },
	[TriggerType.PLATFORM] =    { color = Color(0, 128, 255, 128),  material = MaterialEnum.WIREFRAME },
	[TriggerType.OTHER] =       { color = Color(255, 192, 0, 128),  material = MaterialEnum.WIREFRAME },
}
local TRIGGERS_MATERIAL_NAMES = {
	[MaterialEnum.WIREFRAME] = "models/wireframe",
	[MaterialEnum.DEFAULT] = "tools/toolstrigger",
	[MaterialEnum.SOLID] = "!triggers_solid",
}

local TRIGGERS_SOLID_MATERIAL = CreateMaterial("triggers_solid", "LightmappedGeneric", {
	["$basetexture"] = "color/white",
})

-- Convars
local cv_triggers = CreateClientConVar("showtriggers_enabled", "0", false, true, "Show or hide trigger brushes", 0, 1)
local cv_triggerTypes = CreateClientConVar("showtriggers_types", tostring(ShowHidden.ALL_TYPES),
true, false, "Enabled trigger types bit-mask", 0, ShowHidden.ALL_TYPES)

local g_triggersCount = {}
local g_triggersColors = DEFAULT_TRIGGERS_COLORS

local function SaveTriggersColors()
	file.Write("showtriggers_colors.json", util.TableToJSON(g_triggersColors, true))
end

-- Read and sanitize triggers materials and colors from config file
local function LoadTriggersColors()
	local colors = util.JSONToTable(file.Read("showtriggers_colors.json", "DATA") or "") or {}
	g_triggersColors = {}

	for _, t in pairs(TriggerType) do
		local default = DEFAULT_TRIGGERS_COLORS[t]
		local col = colors[t]

		if not istable(col) then
			g_triggersColors[t] = table.Copy(default)
			continue
		end

		g_triggersColors[t] = {
			material = math.floor(math.Clamp(tonumber(col.material) or default.material, 0, 2)),
			color = istable(col.color) and Color(
			math.floor(math.Clamp(tonumber(col.color.r) or default.color.r, 0, 255)),
			math.floor(math.Clamp(tonumber(col.color.g) or default.color.g, 0, 255)),
			math.floor(math.Clamp(tonumber(col.color.b) or default.color.b, 0, 255)),
			math.floor(math.Clamp(tonumber(col.color.a) or default.color.a, 0, 255))
		) or table.Copy(default.color),
	}
end
end

local function SetTriggerColor(ent, triggerType)
	local col = g_triggersColors[triggerType]
	if col then
		ent:RemoveEffects(EF_NODRAW)
		ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
		ent:SetMaterial(TRIGGERS_MATERIAL_NAMES[col.material])
		ent:SetColor(col.color)

		--[[ local text = language.GetPhrase("showtriggers.type." .. triggerType)
		debugoverlay.Cross(ent:GetPos(), 8, TRACE_TIMEOUT, col.color, true)
		debugoverlay.EntityTextAtPosition(ent:GetPos(), 1, text, TRACE_TIMEOUT) ]]
	end
end

local function NetTriggerTypeProxy(ent, name, old, new)
	if not IsValid(ent) or ent:IsDormant() or not cv_triggers:GetBool()
	or not ShowHidden.CheckMask(cv_triggerTypes:GetInt(), new) then return end
	SetTriggerColor(ent, new)
end

local function HandleVisibleTrigger(ent, show)
	if show == false or not IsValid(ent) or not ShowHidden.TRACK_TRIGGERS[ent:GetClass()] then return end

	local triggerType = ent:GetNWInt("showtriggers_type", 0)
	if triggerType == 0 or not cv_triggers:GetBool() or not ShowHidden.CheckMask(cv_triggerTypes:GetInt(), triggerType) then
		ent:AddEffects(EF_NODRAW)
		ent:SetNWVarProxy("showtriggers_type", NetTriggerTypeProxy)
	else
		SetTriggerColor(ent, triggerType)
	end
end
hook.Add("NetworkEntityCreated", "ShowHidden.HandleCreatedTrigger", HandleVisibleTrigger)
hook.Add("NotifyShouldTransmit", "ShowHidden.HandleCreatedTrigger", HandleVisibleTrigger)

local function UpdateVisibleTriggers()
	local triggers = ents.FindByClass("trigger_*")
	for _, ent in ipairs(triggers) do
		if IsValid(ent) and not ent:IsDormant() then
			HandleVisibleTrigger(ent, true)
		end
	end
end

-- Recieve triggers triggers count from server
net.Receive("ShowHidden.ShowTriggers", function()
	local enabledTypes = cv_triggerTypes:GetInt()
	local total = 0
	local enabled = 0

	for triggerType = 1, TriggerType.MAX do
		local count = net.ReadUInt(16)
		g_triggersCount[triggerType] = count

		total = total + count
		if ShowHidden.CheckMask(enabledTypes, triggerType) then
			enabled = enabled + count
		end
	end

	g_triggersCount[0] = total
	UpdateVisibleTriggers()
	ShowHidden.UpdateCountTooltips()

	print("[ShowTriggers]\tEnabled triggers: " .. enabled .. " / " .. total)
end)

local function ToggleTriggers(cv, old, new)
	local enabled = cv_triggers:GetBool()
	local types = cv_triggerTypes:GetInt()
	local toggle = cv == cv_triggers:GetName()

	if not enabled and not toggle then return end
	if not enabled or types > ShowHidden.ALL_TYPES or types < 0 then types = 0 end

	net.Start("ShowHidden.ShowTriggers")
	net.WriteUInt(types, 16)
	net.SendToServer()

	if old ~= new and toggle then
		ChatMessage(PREFIX_TRIGGERS, enabled and "showtriggers.msg.enabled" or "showtriggers.msg.disabled")
	end
end

-- Update material and color of trigger type
local function UpdateTriggerTypeMaterial(ply, cmd, args)
	if #args < 1 then
		print("Usage: " .. cmd .. " TRIGGER_TYPE MATERIAL_TYPE \"R G B A\"")
		return
	end

	local triggerType = math.floor(tonumber(args[1]) or 0)
	if not table.KeyFromValue(TriggerType, triggerType) then
		PrintTable(TriggerType)
		return
	end

	local default = DEFAULT_TRIGGERS_COLORS[triggerType]
	local material = math.floor(math.Clamp(tonumber(args[2]) or default.material, 0, 2))
	local color = args[3] and string.ToColor(args[3]) or table.Copy(default.color)

	g_triggersColors[triggerType] = { material = material, color = color }
	UpdateVisibleTriggers()
	SaveTriggersColors()
end
concommand.Add("showtriggers_material", UpdateTriggerTypeMaterial, nil, "Sets material and color for trigger type")

-- TODO: show targetname, filter and teleport dest? (+ outputs)
concommand.Add("showtriggers_trace", function()
	if not cv_triggers:GetBool() or cv_triggerTypes:GetInt() == 0 then return end
	local ply = LocalPlayer()
	local tr = util.TraceLine({
		start = ply:EyePos(),
		endpos = ply:EyePos() + ply:LocalEyeAngles():Forward() * 32768,
		mask = MASK_PLAYERSOLID_BRUSHONLY,
	})

	if not tr.Hit then return end
	debugoverlay.Line(tr.StartPos, tr.HitPos, TRACE_TIMEOUT)
	debugoverlay.Cross(tr.HitPos, 16, TRACE_TIMEOUT)

	local tbl = ents.FindAlongRay(tr.StartPos, tr.HitPos)
	for _, ent in ipairs(tbl) do
		if IsValid(ent) and ShowHidden.TRACK_TRIGGERS[ent:GetClass()] then
			local pos = ent:GetPos()
			local triggerType = ent:GetNWInt("showtriggers_type", 0)

			if triggerType ~= 0 then
				local color = g_triggersColors[triggerType].color
				local text = language.GetPhrase("showtriggers.type." .. triggerType)
				debugoverlay.Cross(pos, 8, TRACE_TIMEOUT, color, true)
				debugoverlay.EntityTextAtPosition(pos, 1, text, TRACE_TIMEOUT)
				print("[ShowTriggers]", text, ent, ent:GetPos())
			end
		end
	end
end, nil, "Show triggers info. Use: developer 1")

-- Convar callbacks
cvars.AddChangeCallback(cv_triggers:GetName(), ToggleTriggers, "showtriggers_enabled")
cvars.AddChangeCallback(cv_triggerTypes:GetName(), ToggleTriggers, "showtriggers_types")
LoadTriggersColors()

-- [[ ShowClips ]] --

local luabsp = ShowHidden.luabsp

local DEFAULT_CLIPS_COLOR = { material = 1, color = ColorAlpha(color_white, 128) }
local CLIPS_MATERIALS = {
	[MaterialEnum.WIREFRAME] = CreateMaterial("showclips_0", "Wireframe", {
		["$vertexalpha"] = 1,
	}),
	[MaterialEnum.SOLID] = CreateMaterial("showclips_2", "UnlitGeneric", {
		["$basetexture"] = "color/white",
		["$vertexalpha"] = 1,
	}),
	[MaterialEnum.DEFAULT] = CreateMaterial("showclips_1", "UnlitGeneric", {
		["$basetexture"] = "tools/toolsplayerclip",
		["$vertexalpha"] = 1,
	}),
}

local cv_enabled = CreateClientConVar("showclips", "0", false, true, "Show or hide player-clip brushes", 0, 1)
local cv_material = CreateClientConVar("showclips_material", "1", true, false, "0 = wireframe, 1 = playerclip, 2 = solid color", 0, 2)
local cv_color = CreateClientConVar("showclips_color", "255 255 255 255", true, false, "Clips brush draw color \"R G B A\"")

local g_clipBrushes = nil
local g_clipsMaterial = CLIPS_MATERIALS[MaterialEnum.DEFAULT]

local function UpdateMaterial(cv, old, new)
	if cv and new == old then return end
	local col = string.ToColor(cv_color:GetString())

	g_clipsMaterial = CLIPS_MATERIALS[cv_material:GetInt()] or CLIPS_MATERIALS[MaterialEnum.DEFAULT]
	g_clipsMaterial:SetFloat("$alpha", col.a / 255)
	g_clipsMaterial:SetVector("$color", col:ToVector())
end

local function LoadClipBrushes(cb)
	if g_clipBrushes then return cb(true) end
	ChatMessage(PREFIX_CLIPS, "showclips.msg.lags")

	timer.Simple(0.1, function()
		-- Handle errors
		local ok, err = pcall(function()
			local bsp = luabsp.LoadMap(game.GetMap())
			if bsp then
				g_clipBrushes = bsp:GetClipBrushes(false)
			end
			print("[ShowClips]", "Found " .. #g_clipBrushes .. " playerclip brushes")
		end)
		if not ok then
			ChatMessage(PREFIX_CLIPS, "showclips.msg.error")
			print("[ShowClips]\tError:", err)
		end
		cb(ok)
	end)
end

local function DrawClipBrushes()
	render.OverrideDepthEnable(true, true)
	render.SetMaterial(g_clipsMaterial)
	for _, mesh in ipairs(g_clipBrushes) do
		mesh:Draw()
	end
	render.OverrideDepthEnable(false)
end

local function ToggleClipBrushes()
	if cv_enabled:GetBool() then
		LoadClipBrushes(function(ok)
			if not ok then return cv_enabled:SetBool(false) end
			hook.Add("PostDrawOpaqueRenderables", "bhop_showclips", DrawClipBrushes)
			ChatMessage(PREFIX_CLIPS, "showclips.msg.enabled")
			UpdateMaterial()
			ShowHidden.UpdateCountTooltips()
		end)
	else
		hook.Remove("PostDrawOpaqueRenderables", "bhop_showclips")
		ChatMessage(PREFIX_CLIPS, "showclips.msg.disabled")
	end
end

-- Convar callbacks
cvars.AddChangeCallback(cv_enabled:GetName(), ToggleClipBrushes, "showclips")
cvars.AddChangeCallback(cv_material:GetName(), UpdateMaterial, "showclips_material")
cvars.AddChangeCallback(cv_color:GetName(), UpdateMaterial, "showclips_color")
UpdateMaterial()

-- [[ GUI ]] --

local MAT_ALPHA_GRID = Material("gui/alpha_grid.png", "noclamp")

local g_configMenu = nil

local PANEL_MATCOLOR = {}

function PANEL_MATCOLOR:Init()
	self.Material = nil
	self.AutoSize = false
	self:SetColor(color_white)

	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(false)
end

function PANEL_MATCOLOR:SetMaterial(mat, color, triggerType)
	local texture = triggerType and "tools/toolstrigger" or "tools/toolsplayerclip"
	if mat == MaterialEnum.WIREFRAME then
		texture = "models/wireframe"
	elseif mat == MaterialEnum.SOLID then
		texture = "color/white"
	end

	local name = "ShowHidden2_" .. mat .. "_" .. (triggerType or "")
	self.Material = CreateMaterial(name, mat == MaterialEnum.WIREFRAME and "Wireframe" or "UnlitGeneric", {
		["$basetexture"] = texture,
		["$vertexalpha"] = 1,
	})

	self.Color = color
	self.Material:SetFloat("$alpha", self.Color.a / 255)
	self.Material:SetVector("$color", self.Color:ToVector())
	-- TODO: i18n for Material and Color
	self:SetTooltip("Material: " .. language.GetPhrase("showhidden.mat." .. mat) .. "\nColor: " .. string.FromColor(color))
end

function PANEL_MATCOLOR:Paint(w, h)
	surface.SetMaterial(MAT_ALPHA_GRID)
	surface.SetDrawColor(color_white:Unpack())
	surface.DrawTexturedRectUV(0, 0, w, h, 0, 0, w / 128, h / 128)

	if self.Material then
		surface.SetMaterial(self.Material)
		surface.SetDrawColor(self.Color:Unpack())
		surface.DrawTexturedRect(0, 0, w, h)
	end

	surface.SetDrawColor(color_black:Unpack())
	self:DrawOutlinedRect()
	return true
end

vgui.RegisterTable(PANEL_MATCOLOR, "Material")

local function OpenMaterialPicker(triggerType, cb)
	local clip = not triggerType
	local default = table.Copy(clip and DEFAULT_CLIPS_COLOR or DEFAULT_TRIGGERS_COLORS[triggerType])
	local initial = clip and {
		color = string.ToColor(cv_color:GetString()),
		material = cv_material:GetInt(),
	} or table.Copy(g_triggersColors[triggerType])
	local current = table.Copy(initial)

	local mixer = nil
	local matPanels = {}

	local function update(material, color)
		local new = {
			material = material or current.material,
			color = color or current.color,
		}
		new.color = ColorAlpha(new.color, new.color.a)

		if current.material == new.material and current.color == new.color then return end
		current = new

		mixer:SetColor(new.color)
		mixer:SetBaseColor(new.color)
		for mat, matPan in ipairs(matPanels) do
			matPan:SetMaterial(mat, new.color, triggerType)
		end

		if isfunction(cb) then cb(new.material, new.color) end
	end

	local pan = vgui.Create("DPanel")
	pan:SetPaintBorderEnabled(true)
	pan:DockPadding(2, 2, 2, 2)
	pan:SetSize(300, 300)

	local m = DermaMenu()
	m:AddPanel(pan)

	local mats = vgui.Create("DPanel", pan)
	mats:SetPaintBackground(false)
	mats:SetHeight(32)
	mats:DockMargin(2, 2, 2, 2)
	mats:Dock(TOP)

	for _, material in pairs(MaterialEnum) do
		local mat = vgui.CreateFromTable(PANEL_MATCOLOR, mats)
		mat:SetMaterial(material, current.color, triggerType)
		mat:SetSize(32, 32)
		mat:Dock(RIGHT)
		mat:DockMargin(4, 0, 0, 0)
		mat:SetTooltip("#showhidden.mat." .. material)
		mat.DoClick = function() update(material, nil) end
		matPanels[material] = mat
	end

	local matLab = vgui.Create("DLabel", mats)
	matLab:SetText(clip and "#showclips" or "#showtriggers.type." .. triggerType)
	matLab:Dock(FILL)
	matLab:SetTextColor(color_black)
	matLab:SetContentAlignment(6) -- right center

	mixer = vgui.Create("DColorMixer", pan)
	mixer:Dock(FILL)
	mixer:SetPalette(true)
	mixer:SetAlphaBar(true)
	mixer:SetWangs(true)
	mixer:SetColor(current.color)
	mixer:SetBaseColor(current.color)
	mixer:DockMargin(2, 2, 2, 2)
	mixer.ValueChanged = function(self, color)
		update(nil, color)
	end

	local buttons = vgui.Create("DPanel", pan)
	buttons:SetPaintBackground(false)
	buttons:SetHeight(24)
	buttons:DockMargin(2, 2, 2, 2)
	buttons:Dock(BOTTOM)

	local def = buttons:Add("DButton")
	def:SetText("#default")
	def:Dock(LEFT)
	def:DockMargin(0, 0, 4, 0)
	def.DoClick = function() update(default.material, default.color) end

	local reset = buttons:Add("DButton")
	reset:SetText("#showhidden.reset")
	reset:Dock(LEFT)
	reset.DoClick = function() update(initial.material, initial.color) end

	local close = buttons:Add("DButton")
	close:SetText("#close")
	close:Dock(RIGHT)
	close.DoClick = function()
		m:Hide()
		m:Remove()
	end

	m:Open()
	return m
end

local function OpenConfigMenu()
	local w = vgui.Create("DFrame")
	w:SetSize(250, 300)
	w:DockMargin(2, 26, 2, 2)
	w:SetTitle("#showhidden.title")
	w:SetDeleteOnClose(true)
	w:SetDraggable(true)
	w:SetSizable(true)

	local function addSiwtch(triggerType, parent)
		local col = triggerType and g_triggersColors[triggerType] or {
			color = string.ToColor(cv_color:GetString()),
			material = cv_material:GetInt(),
		}
		local enab = cv_enabled:GetBool()
		if triggerType then enab = ShowHidden.CheckMask(cv_triggerTypes:GetInt(), triggerType) end

		local pan = vgui.Create("DPanel", parent)
		pan:SetPaintBackground(false)
		pan:SetHeight(24)
		pan:DockMargin(2, 2, 2, 2)
		pan:Dock(TOP)

		local mat = vgui.CreateFromTable(PANEL_MATCOLOR, pan)
		mat:SetMaterial(col.material, col.color, triggerType)
		mat:SetSize(24, 24)
		mat:DockMargin(0, 0, 4, 0)
		mat:Dock(LEFT)

		local function update(material, color)
			mat:SetMaterial(material, color, triggerType)

			if triggerType then
				g_triggersColors[triggerType].material = material
				g_triggersColors[triggerType].color = color
				UpdateVisibleTriggers()
			else
				cv_color:SetString(string.FromColor(color))
				cv_material:SetInt(material)
			end
		end

		mat.DoClick = function()
			OpenMaterialPicker(triggerType, update)
		end
		mat.DoRightClick = function()
			local default = table.Copy(triggerType and DEFAULT_TRIGGERS_COLORS[triggerType] or DEFAULT_CLIPS_COLOR)
			update(default.material, default.color)
		end

		local check = pan:Add("DCheckBoxLabel")
		check:SetText(triggerType and ("#showtriggers.type." .. triggerType) or "#showclips.gui.enable")
		check:SetChecked(enab)
		check:DockMargin(0, 4, 0, 4)
		check:Dock(FILL)
		check:SetTextColor(color_black)

		if not triggerType then
			check:SetConVar(cv_enabled:GetName())
			return pan
		end

		check.OnChange = function(self, checked)
			local types = cv_triggerTypes:GetInt()
			if checked then
				cv_triggerTypes:SetInt(bit.bor(types, bit.rol(1, triggerType - 1)))
			else
				cv_triggerTypes:SetInt(bit.band(types, bit.bnot(bit.rol(1, triggerType - 1))))
			end
		end

		return pan
	end

	local clipsPan = w:Add("DPanel")
	clipsPan:DockPadding(2, 2, 2, 2)
	clipsPan:DockMargin(2, 2, 2, 2)
	clipsPan:Dock(TOP)

	local enabClips = addSiwtch(nil, clipsPan)

	local trigPan = w:Add("DPanel")
	trigPan:DockPadding(2, 2, 2, 2)
	trigPan:DockMargin(2, 2, 2, 2)
	trigPan:Dock(TOP)

	local enabTrig = trigPan:Add("DCheckBoxLabel")
	enabTrig:SetText("#showtriggers.gui.enable")
	enabTrig:SetChecked(cv_triggers:GetBool())
	enabTrig:SetConVar(cv_triggers:GetName())
	enabTrig:SizeToContents()
	enabTrig:DockMargin(30, 8, 2, 8)
	enabTrig:SetTextColor(color_black)
	enabTrig:Dock(TOP)

	local trigs = {}
	for triggerType = 1, TriggerType.MAX do
		trigs[triggerType] = addSiwtch(triggerType, trigPan)
	end

	local close = w:Add("DButton")
	close:SetText("#close")
	close:Dock(TOP)
	close:DockMargin(2, 2, 2, 2)
	close.DoClick = function() w:Close() end

	function w.UpdateCountTooltips()
		enabClips:SetTooltip(language.GetPhrase("showhidden.count") .. (g_clipBrushes and #g_clipBrushes or "N/A"))
		enabTrig:SetTooltip(language.GetPhrase("showhidden.count") .. (g_triggersCount[0] or "N/A"))

		for triggerType = 1, TriggerType.MAX do
			trigs[triggerType]:SetTooltip(language.GetPhrase("showhidden.count") .. (g_triggersCount[triggerType] or "N/A"))
		end
	end

	w.OnClose = function()
		g_configMenu = nil
		UpdateVisibleTriggers()
		SaveTriggersColors()
	end

	clipsPan:InvalidateLayout(true)
	clipsPan:SizeToChildren(false, true)
	trigPan:InvalidateLayout(true)
	trigPan:SizeToChildren(false, true)
	w:InvalidateLayout(true)
	w:SizeToChildren(false, true)
	w.UpdateCountTooltips()

	w:Center()
	local x, y = w:GetPos()
	w:SetPos(4, y)
	w:MakePopup()
	g_configMenu = w
	return w
end

function ShowHidden.UpdateCountTooltips()
	if g_configMenu then g_configMenu.UpdateCountTooltips() end
end

concommand.Add("showhidden", OpenConfigMenu, nil, "Open PlayerClips and ShowTriggers settings menu")

-- [[ i18n ]] --

language.Add("showhidden.title", "PlayerClips & ShowTriggers menu")
language.Add("showhidden.count", "Count: ")
language.Add("showhidden.reset", "Reset")
language.Add("showhidden.mat.0", "Wireframe")
language.Add("showhidden.mat.1", "Default")
language.Add("showhidden.mat.2", "Solid color")

language.Add("showclips.msg.lags", "Reading player clips information from map. There may be some lags...")
language.Add("showclips.msg.enabled", "Player clips are enabled. Use !clipsmenu to configure")
language.Add("showclips.msg.disabled", "Player clips are now disabled!")
language.Add("showclips.msg.error", "Cant load player clips (see error message in console ~)")
language.Add("showclips.gui.enable", "Draw player-clip brushes")
language.Add("showclips", "Player clip brushes")

language.Add("showtriggers.msg.enabled", "Triggers are enabled. Use !triggersmenu to configure")
language.Add("showtriggers.msg.disabled", "Triggers are now disabled!")
language.Add("showtriggers.gui.enable", "Show trigger brushes")
language.Add("showtriggers.type.1", "Other triggers...")
language.Add("showtriggers.type.2", "Teleports (reset)")
language.Add("showtriggers.type.3", "Teleports with filter")
language.Add("showtriggers.type.4", "Boosters: push")
language.Add("showtriggers.type.5", "Boosters: base-velocity")
language.Add("showtriggers.type.6", "Boosters: gravity")
language.Add("showtriggers.type.7", "PreSpeed prevention")
language.Add("showtriggers.type.8", "BunnyHop platforms")
