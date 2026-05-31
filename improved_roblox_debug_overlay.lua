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
		instance,
		TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		properties
	):Play()
end

local function toHex(color)
	return string.format(
		"#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

local function isPointerInput(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function makeLabel(parent, text, position, size, color, textSize, bold)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = color or THEME.Text
	label.TextSize = textSize or 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.ZIndex = 20
	label.Parent = parent
	return label
end

local function makeButton(parent, text, position, size)
	local button = Instance.new("TextButton")
	button.AutoButtonColor = false
	button.BackgroundColor3 = THEME.PanelSoft
	button.BorderSizePixel = 0
	button.Position = position
	button.Size = size
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = THEME.Muted
	button.TextSize = 13
	button.ZIndex = 20
	button.Parent = parent
	addCorner(button, 8)
	local stroke = addStroke(button, THEME.Dim)
	return button, stroke
end

local function setButtonState(button, stroke, enabled, onText, offText, color)
	button.Text = enabled and onText or offText
	button.TextColor3 = enabled and color or THEME.Muted
	tween(button, {
		BackgroundColor3 = enabled and Color3.fromRGB(24, 38, 28) or THEME.PanelSoft,
	})
	tween(stroke, {
		Color = enabled and color or THEME.Dim,
	})
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ConExDebugOverlay"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PLAYER_GUI

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Active = true
panel.BackgroundColor3 = THEME.Panel
panel.BorderSizePixel = 0
panel.Position = CONFIG.PanelPosition
panel.Size = CONFIG.PanelSize
panel.ZIndex = 10
panel.Parent = screenGui
addCorner(panel, 10)
addStroke(panel, Color3.fromRGB(55, 55, 65))

local header = Instance.new("Frame")
header.Name = "Header"
header.Active = true
header.BackgroundColor3 = THEME.PanelAlt
header.BorderSizePixel = 0
header.Size = UDim2.new(1, 0, 0, 42)
header.ZIndex = 15
header.Parent = panel
addCorner(header, 10)

local headerSquare = Instance.new("Frame")
headerSquare.BackgroundColor3 = THEME.PanelAlt
headerSquare.BorderSizePixel = 0
headerSquare.Position = UDim2.new(0, 0, 1, -10)
headerSquare.Size = UDim2.new(1, 0, 0, 10)
headerSquare.ZIndex = 15
headerSquare.Parent = header

makeLabel(header, CONFIG.Title, UDim2.fromOffset(14, 0), UDim2.new(1, -28, 1, 0), THEME.Text, 13, true)

local body = Instance.new("Frame")
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(0, 42)
body.Size = UDim2.new(1, 0, 1, -42)
body.ZIndex = 15
body.Parent = panel

local y = 14
local function section(title)
	makeLabel(body, title, UDim2.fromOffset(18, y), UDim2.new(1, -36, 0, 16), THEME.Dim, 11, true)
	y += 24
end

section("VISIBILITY")

local labelsButton, labelsStroke = makeButton(
	body,
	"PLAYER LABELS  OFF",
	UDim2.fromOffset(18, y),
	UDim2.new(1, -36, 0, 38)
)
y += 48

local healthButton, healthStroke = makeButton(
	body,
	"HEALTH  ON",
	UDim2.fromOffset(18, y),
	UDim2.new(0.5, -23, 0, 36)
)

local distanceButton, distanceStroke = makeButton(
	body,
	"DISTANCE  ON",
	UDim2.new(0.5, 5, 0, y),
	UDim2.new(0.5, -23, 0, 36)
)
y += 52

section("LABEL COLOR")

local colorTrack = Instance.new("Frame")
colorTrack.BackgroundColor3 = Color3.new(1, 1, 1)
colorTrack.BorderSizePixel = 0
colorTrack.Position = UDim2.fromOffset(18, y)
colorTrack.Size = UDim2.new(1, -36, 0, 14)
colorTrack.ZIndex = 20
colorTrack.Parent = body
addCorner(colorTrack, 999)

local colorGradient = Instance.new("UIGradient")
colorGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
	ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
	ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
	ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
	ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
	ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
	ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
})
colorGradient.Parent = colorTrack

local colorKnob = Instance.new("Frame")
colorKnob.BackgroundColor3 = state.labelColor
colorKnob.BorderSizePixel = 0
colorKnob.Position = UDim2.new(0.56, -10, 0.5, -10)
colorKnob.Size = UDim2.fromOffset(20, 20)
colorKnob.ZIndex = 21
colorKnob.Parent = colorTrack
addCorner(colorKnob, 999)
addStroke(colorKnob, Color3.new(1, 1, 1), 2, 0.35)
y += 20

local colorValue = makeLabel(body, toHex(state.labelColor), UDim2.fromOffset(18, y), UDim2.new(1, -36, 0, 16), THEME.Muted, 11)
y += 34

section("DISTANCE")

local distanceLabel = makeLabel(
	body,
	"MAX DISTANCE  (" .. state.labelDistance .. " studs)",
	UDim2.fromOffset(18, y),
	UDim2.new(1, -36, 0, 18),
	THEME.Muted,
	12,
	true
)
y += 24

local distanceTrack = Instance.new("Frame")
distanceTrack.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
distanceTrack.BorderSizePixel = 0
distanceTrack.Position = UDim2.fromOffset(18, y)
distanceTrack.Size = UDim2.new(1, -36, 0, 14)
distanceTrack.ZIndex = 20
distanceTrack.Parent = body
addCorner(distanceTrack, 999)

local distanceFill = Instance.new("Frame")
distanceFill.BackgroundColor3 = THEME.Accent
distanceFill.BorderSizePixel = 0
distanceFill.Size = UDim2.new(0, 0, 1, 0)
distanceFill.ZIndex = 21
distanceFill.Parent = distanceTrack
addCorner(distanceFill, 999)

local distanceKnob = Instance.new("Frame")
distanceKnob.BackgroundColor3 = THEME.Accent
distanceKnob.BorderSizePixel = 0
distanceKnob.Size = UDim2.fromOffset(20, 20)
distanceKnob.ZIndex = 22
distanceKnob.Parent = distanceTrack
addCorner(distanceKnob, 999)
addStroke(distanceKnob, Color3.new(1, 1, 1), 2, 0.45)
y += 40

section("GRAPHICS")

local lightingButton, lightingStroke = makeButton(
	body,
	"CLEAN LIGHTING  OFF",
	UDim2.fromOffset(18, y),
	UDim2.new(1, -36, 0, 38)
)
y += 54

section("STATUS")

local statusLabel = makeLabel(
	body,
	"Players tracked: 0",
	UDim2.fromOffset(18, y),
	UDim2.new(1, -36, 0, 18),
	THEME.Muted,
	11
)

local function setCleanLighting(enabled)
	state.lightingEnabled = enabled

	if enabled then
		Lighting.Technology = Enum.Technology.Future
		Lighting.Brightness = 2.5
		Lighting.Ambient = Color3.fromRGB(95, 95, 105)
		Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 135)

		if not Lighting:FindFirstChild("ConExDebugBloom") then
			local bloom = Instance.new("BloomEffect")
			bloom.Name = "ConExDebugBloom"
			bloom.Intensity = 0.35
			bloom.Size = 28
			bloom.Threshold = 1.1
			bloom.Parent = Lighting
		end
	else
		Lighting.Technology = originalLighting.Technology
		Lighting.Brightness = originalLighting.Brightness
		Lighting.Ambient = originalLighting.Ambient
		Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient

		local bloom = Lighting:FindFirstChild("ConExDebugBloom")
		if bloom then
			bloom:Destroy()
		end
	end

	setButtonState(lightingButton, lightingStroke, enabled, "CLEAN LIGHTING  ON", "CLEAN LIGHTING  OFF", THEME.Warn)
end

local function getCharacterParts(player)
	local character = player.Character
	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return character, root, humanoid
end

local function removePlayerLabel(player)
	local data = state.labelData[player]
	if not data then
		return
	end

	if data.healthConnection then
		data.healthConnection:Disconnect()
	end

	if data.gui then
		data.gui:Destroy()
	end

	state.labelData[player] = nil
end

local function updateHealthBar(data)
	if not data.humanoid or not data.humanoid.Parent then
		return
	end

	local pct = math.clamp(data.humanoid.Health / math.max(data.humanoid.MaxHealth, 1), 0, 1)
	data.healthBar.Size = UDim2.new(pct, 0, 1, 0)
	data.healthBar.BackgroundColor3 = Color3.new(1 - pct, pct, 0.12)
end

local function createPlayerLabel(player)
	if player == LOCAL_PLAYER or state.labelData[player] then
		return
	end

	local _, root, humanoid = getCharacterParts(player)
	if not root or not humanoid then
		return
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "ConExPlayerLabel"
	gui.Adornee = root
	gui.AlwaysOnTop = false
	gui.MaxDistance = state.labelDistance
	gui.ResetOnSpawn = false
	gui.Size = UDim2.fromOffset(150, 52)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.Parent = PLAYER_GUI

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.Size = UDim2.new(1, 0, 0, 22)
	name.Text = player.DisplayName
	name.TextColor3 = state.labelColor
	name.TextSize = 13
	name.TextStrokeColor3 = Color3.new(0, 0, 0)
	name.TextStrokeTransparency = 0.35
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Parent = gui

	local healthBg = Instance.new("Frame")
	healthBg.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	healthBg.BorderSizePixel = 0
	healthBg.Position = UDim2.new(0.15, 0, 0, 25)
	healthBg.Size = UDim2.new(0.7, 0, 0, 4)
	healthBg.Parent = gui
	addCorner(healthBg, 999)

	local healthBar = Instance.new("Frame")
	healthBar.BackgroundColor3 = THEME.Good
	healthBar.BorderSizePixel = 0
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.Parent = healthBg
	addCorner(healthBar, 999)

	local distance = Instance.new("TextLabel")
	distance.BackgroundTransparency = 1
	distance.Font = Enum.Font.Code
	distance.Position = UDim2.new(0, 0, 0, 32)
	distance.Size = UDim2.new(1, 0, 0, 16)
	distance.Text = ""
	distance.TextColor3 = THEME.Muted
	distance.TextSize = 10
	distance.TextStrokeColor3 = Color3.new(0, 0, 0)
	distance.TextStrokeTransparency = 0.55
	distance.Parent = gui

	local data = {
		gui = gui,
		root = root,
		humanoid = humanoid,
		name = name,
		healthBg = healthBg,
		healthBar = healthBar,
		distance = distance,
	}

	data.healthConnection = humanoid.HealthChanged:Connect(function()
		updateHealthBar(data)
	end)

	state.labelData[player] = data
	updateHealthBar(data)
end

local function refreshLabels()
	for player in pairs(state.labelData) do
		removePlayerLabel(player)
	end

	if not state.labelsEnabled then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		createPlayerLabel(player)
	end
end

local function setLabelsEnabled(enabled)
	state.labelsEnabled = enabled
	setButtonState(labelsButton, labelsStroke, enabled, "PLAYER LABELS  ON", "PLAYER LABELS  OFF", state.labelColor)
	refreshLabels()
end

local function setHealthVisible(enabled)
	state.showHealth = enabled
	setButtonState(healthButton, healthStroke, enabled, "HEALTH  ON", "HEALTH  OFF", THEME.Good)
end

local function setDistanceVisible(enabled)
	state.showDistance = enabled
	setButtonState(distanceButton, distanceStroke, enabled, "DISTANCE  ON", "DISTANCE  OFF", THEME.Accent)
end

local function updateLabelColor(hue)
	hue = math.clamp(hue, 0, 1)
	state.labelColor = Color3.fromHSV(hue, 0.75, 1)
	colorKnob.Position = UDim2.new(hue, -10, 0.5, -10)
	colorKnob.BackgroundColor3 = state.labelColor
	colorValue.Text = toHex(state.labelColor)

	if state.labelsEnabled then
		labelsButton.TextColor3 = state.labelColor
		labelsStroke.Color = state.labelColor
	end

	for _, data in pairs(state.labelData) do
		data.name.TextColor3 = state.labelColor
	end
end

local function distanceToAlpha(distance)
	return math.clamp(
		(distance - CONFIG.MinLabelDistance) / (CONFIG.MaxLabelDistance - CONFIG.MinLabelDistance),
		0,
		1
	)
end

local function updateLabelDistanceFromAlpha(alpha)
	alpha = math.clamp(alpha, 0, 1)
	state.labelDistance = math.floor(CONFIG.MinLabelDistance + alpha * (CONFIG.MaxLabelDistance - CONFIG.MinLabelDistance))
	distanceKnob.Position = UDim2.new(alpha, -10, 0.5, -10)
	distanceFill.Size = UDim2.new(alpha, 0, 1, 0)
	distanceLabel.Text = "MAX DISTANCE  (" .. state.labelDistance .. " studs)"

	for _, data in pairs(state.labelData) do
		data.gui.MaxDistance = state.labelDistance
	end
end

local function alphaForTrack(track, inputX)
	return math.clamp((inputX - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
end

setLabelsEnabled(false)
setHealthVisible(true)
setDistanceVisible(true)
setCleanLighting(false)
updateLabelColor(0.56)
updateLabelDistanceFromAlpha(distanceToAlpha(state.labelDistance))

connect(labelsButton.MouseButton1Click, function()
	setLabelsEnabled(not state.labelsEnabled)
end)

connect(healthButton.MouseButton1Click, function()
	setHealthVisible(not state.showHealth)
end)

connect(distanceButton.MouseButton1Click, function()
	setDistanceVisible(not state.showDistance)
end)

connect(lightingButton.MouseButton1Click, function()
	setCleanLighting(not state.lightingEnabled)
end)

local draggingPanel = false
local panelDragStart
local panelStartPosition
local activeSlider

connect(header.InputBegan, function(input)
	if isPointerInput(input) then
		draggingPanel = true
		panelDragStart = Vector2.new(input.Position.X, input.Position.Y)
		panelStartPosition = panel.Position
	end
end)

local function beginSlider(name, track, input)
	activeSlider = name
	local alpha = alphaForTrack(track, input.Position.X)

	if name == "color" then
		updateLabelColor(alpha)
	elseif name == "distance" then
		updateLabelDistanceFromAlpha(alpha)
	end
end

connect(colorTrack.InputBegan, function(input)
	if isPointerInput(input) then
		beginSlider("color", colorTrack, input)
	end
end)

connect(colorKnob.InputBegan, function(input)
	if isPointerInput(input) then
		activeSlider = "color"
	end
end)

connect(distanceTrack.InputBegan, function(input)
	if isPointerInput(input) then
		beginSlider("distance", distanceTrack, input)
	end
end)

connect(distanceKnob.InputBegan, function(input)
	if isPointerInput(input) then
		activeSlider = "distance"
	end
end)

connect(UserInputService.InputChanged, function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	if draggingPanel then
		local delta = Vector2.new(input.Position.X, input.Position.Y) - panelDragStart
		panel.Position = UDim2.new(
			panelStartPosition.X.Scale,
			panelStartPosition.X.Offset + delta.X,
			panelStartPosition.Y.Scale,
			panelStartPosition.Y.Offset + delta.Y
		)
	elseif activeSlider == "color" then
		updateLabelColor(alphaForTrack(colorTrack, input.Position.X))
	elseif activeSlider == "distance" then
		updateLabelDistanceFromAlpha(alphaForTrack(distanceTrack, input.Position.X))
	end
end)

connect(UserInputService.InputEnded, function(input)
	if isPointerInput(input) then
		draggingPanel = false
		activeSlider = nil
	end
end)

connect(UserInputService.InputBegan, function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == CONFIG.ToggleKey then
		state.visible = not state.visible
		panel.Visible = state.visible
		panel.Active = state.visible
	end
end)

local function onPlayerAdded(player)
	connect(player.CharacterAdded, function()
		task.wait(0.5)
		if state.labelsEnabled then
			removePlayerLabel(player)
			createPlayerLabel(player)
		end
	end)

	if state.labelsEnabled then
		createPlayerLabel(player)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	if player ~= LOCAL_PLAYER then
		onPlayerAdded(player)
	end
end

connect(Players.PlayerAdded, function(player)
	if player ~= LOCAL_PLAYER then
		onPlayerAdded(player)
	end
end)

connect(Players.PlayerRemoving, function(player)
	removePlayerLabel(player)
end)

connect(RunService.RenderStepped, function()
	local localCharacter = LOCAL_PLAYER.Character
	local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
	local tracked = 0

	for player, data in pairs(state.labelData) do
		local _, root, humanoid = getCharacterParts(player)
		if not root or not humanoid then
			removePlayerLabel(player)
			continue
		end

		data.root = root
		data.humanoid = humanoid
		data.gui.Adornee = root
		data.gui.Enabled = state.labelsEnabled
		data.name.Text = player.DisplayName
		data.name.TextColor3 = state.labelColor
		data.healthBg.Visible = state.showHealth
		data.distance.Visible = state.showDistance
		tracked += 1

		if localRoot then
			local studs = math.floor((root.Position - localRoot.Position).Magnitude)
			data.distance.Text = studs .. " studs"
		else
			data.distance.Text = ""
		end
	end

	statusLabel.Text = "Players tracked: " .. tracked
end)

screenGui.Destroying:Connect(function()
	for _, connection in ipairs(state.connections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end

	for player in pairs(state.labelData) do
		removePlayerLabel(player)
	end

	setCleanLighting(false)
end)
