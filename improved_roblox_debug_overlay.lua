-- Roblox LocalScript: Debug/Admin Overlay
-- Put this in StarterPlayerScripts or StarterGui in your own experience.
-- This version avoids aim-assist and through-wall targeting behavior.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LOCAL_PLAYER = Players.LocalPlayer
local PLAYER_GUI = LOCAL_PLAYER:WaitForChild("PlayerGui")

local CONFIG = {
	Title = "Con Ex Debug  [L]",
	PanelSize = UDim2.fromOffset(320, 430),
	PanelPosition = UDim2.new(1, -340, 0, 80),
	ToggleKey = Enum.KeyCode.L,

	-- Leave empty to allow Studio testing. Add your Roblox UserIds for live use.
	AdminUserIds = {},

	DefaultLabelDistance = 250,
	MaxLabelDistance = 1000,
	MinLabelDistance = 25,
}

local THEME = {
	Panel = Color3.fromRGB(12, 12, 14),
	PanelAlt = Color3.fromRGB(18, 18, 22),
	PanelSoft = Color3.fromRGB(28, 28, 34),
	Text = Color3.fromRGB(235, 235, 240),
	Muted = Color3.fromRGB(145, 145, 155),
	Dim = Color3.fromRGB(85, 85, 95),
	Good = Color3.fromRGB(95, 220, 120),
	Warn = Color3.fromRGB(255, 210, 80),
	Accent = Color3.fromRGB(90, 180, 255),
}

local state = {
	visible = true,
	labelsEnabled = false,
	showHealth = true,
	showDistance = true,
	labelDistance = CONFIG.DefaultLabelDistance,
	labelColor = Color3.fromRGB(90, 180, 255),
	lightingEnabled = false,
	connections = {},
	labelData = {},
}

local originalLighting = {
	Technology = Lighting.Technology,
	Brightness = Lighting.Brightness,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
}

local function isAdmin()
	if RunService:IsStudio() then
		return true
	end

	for _, userId in ipairs(CONFIG.AdminUserIds) do
		if LOCAL_PLAYER.UserId == userId then
			return true
		end
	end

	return false
end

if not isAdmin() then
	return
end

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(state.connections, connection)
	return connection
end

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = instance
	return corner
end

local function addStroke(instance, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or THEME.Dim
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = instance
	return stroke
end

local function tween(instance, properties, duration)
	TweenService:Create(
