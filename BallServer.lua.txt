local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local spawnerPart = script.Parent
local spawnerPrompt = spawnerPart:WaitForChild("ProximityPrompt")

local MAX_BALLS = 10
local THROW_POWER = 95

local throwEvent = ReplicatedStorage:FindFirstChild("ThrowBallEvent")

if not throwEvent then
	throwEvent = Instance.new("RemoteEvent")
	throwEvent.Name = "ThrowBallEvent"
	throwEvent.Parent = ReplicatedStorage
end

local function countBalls(player)
	local count = 0

	for _, item in player.Backpack:GetChildren() do
		if item.Name == "Ball" then
			count += 1
		end
	end

	if player.Character then
		for _, item in player.Character:GetChildren() do
			if item.Name == "Ball" then
				count += 1
			end
		end
	end

	return count
end

local function applyToonLook(ball)
	ball.Material = Enum.Material.SmoothPlastic
	ball.Color = Color3.fromRGB(105, 145, 255)
	ball.Reflectance = 0

	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = Color3.fromRGB(180, 225, 255)
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = ball
end

local function makeWorldBall(position, velocity)
	local ball = Instance.new("Part")
	ball.Name = "PickupBall"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(2, 2, 2)
	ball.Anchored = false
	ball.CanCollide = true
	ball.Position = position
	ball.Parent = workspace

	applyToonLook(ball)

	ball.AssemblyLinearVelocity = velocity or Vector3.new(
		math.random(-8, 8),
		18,
		math.random(-8, 8)
	)

	local pickupPrompt = Instance.new("ProximityPrompt")
	pickupPrompt.ActionText = "Pick Up"
	pickupPrompt.ObjectText = "Ball"
	pickupPrompt.KeyboardKeyCode = Enum.KeyCode.E
	pickupPrompt.HoldDuration = 0
	pickupPrompt.MaxActivationDistance = 8
	pickupPrompt.Parent = ball

	pickupPrompt.Triggered:Connect(function(player)
		if countBalls(player) >= MAX_BALLS then
			warn(player.Name .. " inventory full")
			return
		end

		local tool = Instance.new("Tool")
		tool.Name = "Ball"
		tool.RequiresHandle = true
		tool.CanBeDropped = false

		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Shape = Enum.PartType.Ball
		handle.Size = Vector3.new(1.5, 1.5, 1.5)
		handle.CanCollide = false
		handle.Massless = true
		handle.Parent = tool

		applyToonLook(handle)

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://121434237134952"
		sound.Volume = 1
		sound.Parent = handle

		tool.Parent = player.Backpack
		sound:Play()
		ball:Destroy()
	end)

	return ball
end

spawnerPrompt.ActionText = "Spawn Ball"
spawnerPrompt.ObjectText = "Ball Spawner"
spawnerPrompt.KeyboardKeyCode = Enum.KeyCode.E
spawnerPrompt.HoldDuration = 0

spawnerPrompt.Triggered:Connect(function()
	makeWorldBall(spawnerPart.Position + Vector3.new(0, 5, 0))
end)

throwEvent.OnServerEvent:Connect(function(player, direction)
	if typeof(direction) ~= "Vector3" then return end
	if direction.Magnitude <= 0 then return end

	local character = player.Character
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local tool = character:FindFirstChild("Ball")
	if not tool then return end

	tool:Destroy()

	local spawnPosition = root.Position + root.CFrame.LookVector * 3 + Vector3.new(0, 1.5, 0)
	local velocity = direction.Unit * THROW_POWER + Vector3.new(0, 12, 0)

	local thrownBall = makeWorldBall(spawnPosition, velocity)
	Debris:AddItem(thrownBall, 20)
end)