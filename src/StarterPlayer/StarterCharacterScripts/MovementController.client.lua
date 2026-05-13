-- StarterCharacterScripts > MovementController (LocalScript)
-- Плавний рух, поворот, нахил при занесенні.
-- ВАЖЛИВО: читає атрибути SpeedMult / Stunned від EffectsManager,
-- щоб ефекти (Haste, Stun) впливали на швидкість.

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local character = script.Parent
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")
local animator  = humanoid:WaitForChild("Animator")
local player    = Players:GetPlayerFromCharacter(character)

-- === НАЛАШТУВАННЯ ===
local WALK_SPEED  = 16
local RUN_SPEED   = 30
local TURN_TIME   = 0.14
local TILT_AMOUNT = 8

local walkAnim = Instance.new("Animation")
walkAnim.AnimationId = "rbxassetid://139489512245120"
local runAnim = Instance.new("Animation")
runAnim.AnimationId = "rbxassetid://126024649177982"

local walkTrack = animator:LoadAnimation(walkAnim)
local runTrack  = animator:LoadAnimation(runAnim)
walkTrack.Priority = Enum.AnimationPriority.Movement
runTrack.Priority  = Enum.AnimationPriority.Movement

local animateScript = character:FindFirstChild("Animate")
if animateScript then animateScript.Enabled = false end

local function stopAll()
	if walkTrack.IsPlaying then walkTrack:Stop(0.2) end
	if runTrack.IsPlaying  then runTrack:Stop(0.2)  end
end

local currentState = "idle"
local function setState(new)
	if currentState == new then return end
	currentState = new
	if new == "idle" then
		stopAll()
	elseif new == "walk" then
		if runTrack.IsPlaying then runTrack:Stop(0.2) end
		if not walkTrack.IsPlaying then walkTrack:Play(0.2) end
	elseif new == "run" then
		if walkTrack.IsPlaying then walkTrack:Stop(0.2) end
		if not runTrack.IsPlaying then runTrack:Play(0.2) end
	end
end

-- Читаємо ефекти з атрибутів (пише EffectsManager на сервері)
local function getSpeedMult()
	return player and (player:GetAttribute("SpeedMult") or 1) or 1
end

local function isStunned()
	return player and player:GetAttribute("Stunned") == true
end

local smoothDir    = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z).Unit
local currentSpeed = WALK_SPEED

RunService.Heartbeat:Connect(function(dt)
	-- Стан — повна блокіровка
	if isStunned() then
		humanoid.WalkSpeed = 0
		setState("idle")
		return
	end

	local isRunning = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

	local moveDir = humanoid.MoveDirection
	local moving  = moveDir.Magnitude > 0.1

	local effectMult = getSpeedMult()

	if not moving then
		setState("idle")
		currentSpeed = currentSpeed + (WALK_SPEED * effectMult - currentSpeed) * 0.1
		humanoid.WalkSpeed = currentSpeed
		return
	end

	local flatMove = Vector3.new(moveDir.X, 0, moveDir.Z).Unit

	local dot   = math.clamp(smoothDir:Dot(flatMove), -1, 1)
	local angle = math.acos(dot)

	local alpha = math.clamp(dt / TURN_TIME, 0, 1)
	smoothDir = smoothDir:Lerp(flatMove, alpha)
	if smoothDir.Magnitude > 0.001 then
		smoothDir = smoothDir.Unit
	end

	local angleFactor = 1 - (angle / math.pi) * 0.6
	local baseTarget  = (isRunning and RUN_SPEED or WALK_SPEED) * angleFactor
	local targetSpeed = baseTarget * effectMult  -- <-- ось тут ефекти застосовуються

	local lerpSpeed = currentSpeed < targetSpeed and 0.07 or 0.13
	currentSpeed = currentSpeed + (targetSpeed - currentSpeed) * lerpSpeed
	humanoid.WalkSpeed = currentSpeed

	if isRunning then setState("run") else setState("walk") end

	local cross = smoothDir:Cross(flatMove).Y
	local tilt  = math.rad(-cross * TILT_AMOUNT * (angle / math.pi))

	local pos = rootPart.CFrame.Position
	rootPart.CFrame = CFrame.new(pos, pos + smoothDir)
		* CFrame.Angles(0, 0, tilt)
end)
