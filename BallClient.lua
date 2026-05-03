local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()
local throwEvent = ReplicatedStorage:WaitForChild("ThrowBallEvent")

local HOLD_TIME = 0.18
local THROW_POWER = 95
local THROW_UP_FORCE = 12

local LINE_SEGMENTS = 18
local LINE_WIDTH = 0.16
local LINE_TRANSPARENCY = 0.55
local TIME_STEP = 0.055

local holding = false
local aiming = false
local holdStart = 0
local renderConnection = nil
local lineParts = {}

local function getEquippedBall()
	local character = player.Character
	if not character then return nil end

	local tool = character:FindFirstChildOfClass("Tool")

	if tool and tool.Name == "Ball" then
		return tool
	end

	return nil
end

local function getStartPosition()
	local character = player.Character
	if not character then return nil end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	return root.Position + root.CFrame.LookVector * 3 + Vector3.new(0, 1.5, 0)
end

local function getMouseDirection()
	local startPosition = getStartPosition()
	if not startPosition then return camera.CFrame.LookVector end

	local mousePosition = mouse.Hit.Position
	local direction = mousePosition - startPosition

	if direction.Magnitude <= 1 then
		return camera.CFrame.LookVector
	end

	return direction.Unit
end

local function playEquipAnimation(tool)
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end

	handle.Size = Vector3.new(0.2, 0.2, 0.2)

	local tween = TweenService:Create(
		handle,
		TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = Vector3.new(1.5, 1.5, 1.5)}
	)

	tween:Play()
end

local function createLine()
	if #lineParts > 0 then return end

	for i = 1, LINE_SEGMENTS do
		local part = Instance.new("Part")
		part.Name = "AimLine"
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(255, 255, 255)
		part.Transparency = LINE_TRANSPARENCY
		part.Size = Vector3.new(LINE_WIDTH, LINE_WIDTH, 1)
		part.Parent = workspace

		table.insert(lineParts, part)
	end
end

local function removeLine()
	for _, part in lineParts do
		part:Destroy()
	end

	table.clear(lineParts)
end

local function getPoint(startPosition, velocity, time)
	local gravity = Vector3.new(0, -workspace.Gravity, 0)
	return startPosition + velocity * time + 0.5 * gravity * time * time
end

local function updateLine()
	if #lineParts == 0 then return end

	local startPosition = getStartPosition()
	if not startPosition then return end

	local direction = getMouseDirection()
	local velocity = direction * THROW_POWER + Vector3.new(0, THROW_UP_FORCE, 0)

	for i, part in lineParts do
		local t1 = (i - 1) * TIME_STEP
		local t2 = i * TIME_STEP

		local p1 = getPoint(startPosition, velocity, t1)
		local p2 = getPoint(startPosition, velocity, t2)

		local distance = (p2 - p1).Magnitude
		local middle = (p1 + p2) / 2

		part.Size = Vector3.new(LINE_WIDTH, LINE_WIDTH, distance)
		part.CFrame = CFrame.lookAt(middle, p2)
	end
end

local function stopAiming()
	holding = false
	aiming = false

	removeLine()

	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if not getEquippedBall() then return end

	holding = true
	aiming = false
	holdStart = os.clock()

	if renderConnection then
		renderConnection:Disconnect()
	end

	renderConnection = RunService.RenderStepped:Connect(function()
		if holding and not aiming and os.clock() - holdStart >= HOLD_TIME then
			aiming = true
			createLine()
		end

		if aiming then
			updateLine()
		end
	end)
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if not holding then return end

	if not getEquippedBall() then
		stopAiming()
		return
	end

	local direction = getMouseDirection()

	stopAiming()
	throwEvent:FireServer(direction)
end)

player.CharacterAdded:Connect(function(character)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == "Ball" then
			playEquipAnimation(child)
		end
	end)

	stopAiming()
end)

if player.Character then
	player.Character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == "Ball" then
			playEquipAnimation(child)
		end
	end)
end