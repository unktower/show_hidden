-- ShowClips and ShowTriggers addon for Garry's mod BunnyHop
-- By CLazStudio: steamcommunity.com/id/CLazStudio
-- luabsp.lua by h3xcat: github.com/h3xcat

ShowHidden = ShowHidden or {}
ShowHidden.Refresh = (ShowHidden.Refresh ~= nil)

if SERVER then
	AddCSLuaFile("show_hidden/lib/luabsp.lua")
	AddCSLuaFile("show_hidden/sh_init.lua")
	AddCSLuaFile("show_hidden/cl_init.lua")
	AddCSLuaFile("show_hidden/cl_lang.lua")

	include("show_hidden/sh_init.lua")
	include("show_hidden/sv_init.lua")
else
	ShowHidden.luabsp = include("show_hidden/lib/luabsp.lua")

	include("show_hidden/sh_init.lua")
	include("show_hidden/cl_init.lua")
	include("show_hidden/cl_lang.lua")
end
