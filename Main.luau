-- TERMINAL: LocalScript em StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local GREEN = Color3.fromRGB(0, 255, 70)
local DIM = Color3.fromRGB(0, 110, 35)
local DARK = Color3.fromRGB(0, 45, 15)
local BLACK = Color3.new(0, 0, 0)
local FONT = Enum.Font.Code
local LEFT = Enum.TextXAlignment.Left
local CENTER = Enum.TextXAlignment.Center
local RIGHT = Enum.TextXAlignment.Right
local W, H = 230, 236
local KEY_SFX = "rbxasset://sounds/clickfast.wav"
local ENTER_SFX = "rbxasset://sounds/electronicpingshort.wav"

local VIM
pcall(function()
	VIM = game:GetService("VirtualInputManager")
end)

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------
local function make(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local function border(parent, color)
	return make("UIStroke", {
		Color = color or GREEN,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function label(parent, text, x, y, w, h, align)
	return make("TextLabel", {
		Size = UDim2.fromOffset(w, h or 16),
		Position = UDim2.fromOffset(x, y),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = GREEN,
		Font = FONT,
		TextSize = 11,
		TextXAlignment = align or LEFT,
	}, parent)
end

local function btn(parent, text, x, y, w, h)
	local b = make("TextButton", {
		Size = UDim2.fromOffset(w, h or 18),
		Position = UDim2.fromOffset(x, y),
		BackgroundColor3 = BLACK,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = GREEN,
		Font = FONT,
		TextSize = 11,
		AutoButtonColor = false,
	}, parent)
	border(b)
	return b
end

local function setOn(b, on, text)
	b.Text = text
	b.BackgroundColor3 = on and GREEN or BLACK
	b.BackgroundTransparency = on and 0.2 or 0.6
	b.TextColor3 = on and BLACK or GREEN
end

local function bind(f, conn)
	f.Destroying:Connect(function()
		if conn.Connected then
			conn:Disconnect()
		end
	end)
end

local function center(dx, dy)
	return UDim2.new(0.5, -115 + dx, 0.5, -118 + dy)
end

local function sfx(id)
	pcall(function()
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = 0.4
		s.Parent = SoundService
		s:Play()
		Debris:AddItem(s, 2)
	end)
end

local function getParent()
	local ok, h = pcall(function()
		return gethui and gethui()
	end)
	if ok and h then
		return h
	end
	return player:WaitForChild("PlayerGui")
end

local guiParent = getParent()
local old = guiParent:FindFirstChild("TerminalUI")
if old then
	old:Destroy()
end
local screen = make("ScreenGui", {
	Name = "TerminalUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)

local function drag(handle, frame, canDrag)
	local dragging, start, startPos = false, nil, nil
	handle.InputBegan:Connect(function(i)
		local t = i.UserInputType
		if (t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch) and (not canDrag or canDrag()) then
			dragging = true
			start = i.Position
			startPos = frame.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if not dragging or not frame.Parent then
			return
		end
		local t = i.UserInputType
		if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
			local d = i.Position - start
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
end

-- Janela 230x236 com 60% de transparência no fundo
local function createWindow(name, title, pos, cleanup)
	local f = make("Frame", {
		Name = name,
		Size = UDim2.fromOffset(W, H),
		Position = pos,
		BackgroundColor3 = BLACK,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Active = true,
		ClipsDescendants = true,
	}, screen)
	border(f)

	local bar = make("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundColor3 = BLACK,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
	}, f)
	local t = label(bar, "C:\\" .. title .. ">", 4, 0, 190, 16)
	t.TextColor3 = GREEN

	local function barBtn(text, x)
		return make("TextButton", {
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.new(1, x, 0, 0),
			BackgroundTransparency = 1,
			Text = text,
			TextColor3 = GREEN,
			Font = FONT,
			TextSize = 12,
			AutoButtonColor = false,
		}, bar)
	end
	local minBtn = barBtn("—", -34)
	local closeBtn = barBtn("X", -17)

	local body = make("Frame", {
		Size = UDim2.new(1, -8, 1, -22),
		Position = UDim2.fromOffset(4, 18),
		BackgroundTransparency = 1,
	}, f)

	drag(bar, f)

	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		body.Visible = not minimized
		f.Size = UDim2.fromOffset(W, minimized and 16 or H)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		f:Destroy()
	end)
	if cleanup then
		f.Destroying:Connect(cleanup)
	end
	return f, body
end

-- Slider quadrado
local function slider(parent, x, y, w, minV, maxV, step, initial, onChange)
	local track = make("Frame", {
		Size = UDim2.fromOffset(w, 6),
		Position = UDim2.fromOffset(x, y + 7),
		BackgroundColor3 = DARK,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
	}, parent)
	border(track, DIM)
	local fill = make("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = GREEN,
		BorderSizePixel = 0,
	}, track)
	local knob = make("Frame", {
		Size = UDim2.fromOffset(6, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = GREEN,
		BorderSizePixel = 0,
	}, track)
	local hit = make("TextButton", {
		Size = UDim2.fromOffset(w, 22),
		Position = UDim2.fromOffset(x, y),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	}, parent)

	local value
	local function setAlpha(a)
		a = math.clamp(a, 0, 1)
		local v = minV + math.floor(a * (maxV - minV) / step + 0.5) * step
		local pos = (v - minV) / (maxV - minV)
		fill.Size = UDim2.new(pos, 0, 1, 0)
		knob.Position = UDim2.new(pos, 0, 0.5, 0)
		if v ~= value then
			value = v
			onChange(v)
		end
	end

	local dragging = false
	local function fromX(px)
		setAlpha((px - track.AbsolutePosition.X) / track.AbsoluteSize.X)
	end

	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			fromX(i.Position.X)
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and track.Parent and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			fromX(i.Position.X)
		end
	end)

	setAlpha((initial - minV) / (maxV - minV))
end

---------------------------------------------------------------------
-- SCRIPT: VELOCIDADE
---------------------------------------------------------------------
local function openVelocidade()
	local MIN_V, MAX_V, STEP = 30, 90, 10
	local LOW_GRAVITY, MAX_EXTRA = 60, 20
	local speed, jump, extra = MIN_V, MIN_V, 0
	local speedOn, jumpOn, gravOn = false, false, false
	local used, airSince, lastExtra = 0, nil, 0
	local orig = { speed = 16, jump = 50, useJump = true, gravity = workspace.Gravity }

	local function getHum()
		local c = player.Character
		return c and c:FindFirstChildOfClass("Humanoid")
	end

	local function restore()
		local h = getHum()
		if h then
			if speedOn then
				h.WalkSpeed = orig.speed
			end
			if jumpOn then
				h.JumpPower = orig.jump
				h.UseJumpPower = orig.useJump
			end
		end
		if gravOn then
			workspace.Gravity = orig.gravity
		end
	end

	local f, body = createWindow("VELOCIDADE", "VELOCIDADE.EXE", center(-80, 40), restore)

	local speedBtn = btn(body, "", 0, 0, 222)
	local jumpBtn = btn(body, "", 0, 48, 222)
	label(body, "PULOS EXTRA", 0, 98, 110, 16)
	local minus = btn(body, "-", 118, 96, 22)
	local numL = label(body, "0", 142, 96, 30, 18, CENTER)
	local plus = btn(body, "+", 176, 96, 22)
	local gravBtn = btn(body, "", 0, 120, 222)
	label(body, "pulo extra funciona no ar", 0, 144, 222, 16)

	local function paint()
		setOn(speedBtn, speedOn, "VELOCIDADE " .. (speedOn and "ON " or "OFF ") .. "[" .. speed .. "]")
		setOn(jumpBtn, jumpOn, "PULO " .. (jumpOn and "ON " or "OFF ") .. "[" .. jump .. "]")
		setOn(gravBtn, gravOn, "GRAVIDADE BAIXA " .. (gravOn and "ON" or "OFF"))
	end

	slider(body, 0, 22, 222, MIN_V, MAX_V, STEP, speed, function(v)
		speed = v
		paint()
	end)
	slider(body, 0, 70, 222, MIN_V, MAX_V, STEP, jump, function(v)
		jump = v
		paint()
	end)

	local function setExtra(n)
		extra = math.clamp(n, 0, MAX_EXTRA)
		numL.Text = tostring(extra)
	end
	minus.MouseButton1Click:Connect(function()
		setExtra(extra - 1)
	end)
	plus.MouseButton1Click:Connect(function()
		setExtra(extra + 1)
	end)

	speedBtn.MouseButton1Click:Connect(function()
		speedOn = not speedOn
		local h = getHum()
		if speedOn then
			if h then
				orig.speed = h.WalkSpeed
			end
		elseif h then
			h.WalkSpeed = orig.speed
		end
		paint()
	end)

	jumpBtn.MouseButton1Click:Connect(function()
		jumpOn = not jumpOn
		local h = getHum()
		if jumpOn then
			if h then
				orig.jump = h.JumpPower
				orig.useJump = h.UseJumpPower
			end
		elseif h then
			h.JumpPower = orig.jump
			h.UseJumpPower = orig.useJump
		end
		paint()
	end)

	gravBtn.MouseButton1Click:Connect(function()
		gravOn = not gravOn
		if gravOn then
			orig.gravity = workspace.Gravity
		else
			workspace.Gravity = orig.gravity
		end
		paint()
	end)

	bind(f, RunService.Heartbeat:Connect(function()
		local h = getHum()
		if h then
			if speedOn and h.WalkSpeed ~= speed then
				h.WalkSpeed = speed
			end
			if jumpOn then
				if not h.UseJumpPower then
					h.UseJumpPower = true
				end
				if h.JumpPower ~= jump then
					h.JumpPower = jump
				end
			end
			if h.FloorMaterial ~= Enum.Material.Air then
				used = 0
				airSince = nil
			elseif not airSince then
				airSince = os.clock()
			end
		end
		if gravOn and workspace.Gravity ~= LOW_GRAVITY then
			workspace.Gravity = LOW_GRAVITY
		end
	end))

	bind(f, UIS.JumpRequest:Connect(function()
		if extra <= 0 then
			return
		end
		local h = getHum()
		if not h or h.Health <= 0 or h.FloorMaterial ~= Enum.Material.Air then
			return
		end
		if not airSince or os.clock() - airSince < 0.12 then
			return
		end
		if os.clock() - lastExtra < 0.2 or used >= extra then
			return
		end
		used += 1
		lastExtra = os.clock()
		h:ChangeState(Enum.HumanoidStateType.Jumping)
	end))

	paint()
end

---------------------------------------------------------------------
-- SCRIPT: AUTO CLICK
---------------------------------------------------------------------
local function openAutoClick()
	local MIN_T, MAX_T = 0.1, 10
	local interval, clicking, runId = 1, false, 0
	local ball

	local function doClick(x, y)
		if VIM then
			local ok = pcall(function()
				VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
				VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
			end)
			if ok then
				return
			end
		end
		if fireclickdetector then
			pcall(function()
				local ray = workspace.CurrentCamera:ViewportPointToRay(x, y)
				local res = workspace:Raycast(ray.Origin, ray.Direction * 1000)
				local cd = res and res.Instance:FindFirstChildOfClass("ClickDetector")
				if cd then
					fireclickdetector(cd)
				end
			end)
		end
	end

	local f, body = createWindow("AUTOCLICK", "AUTOCLICK.EXE", center(80, 40), function()
		clicking = false
		runId += 1
		if ball then
			ball:Destroy()
		end
	end)

	local ballBtn = btn(body, "", 0, 0, 106)
	local clickBtn = btn(body, "", 116, 0, 106)
	local intervalL = label(body, "", 0, 26, 222, 14)
	local statusL = label(body, "", 0, 82, 222, 14)
	label(body, "arraste a bola sobre o alvo", 0, 104, 222, 14)

	local function status(t)
		statusL.Text = t
	end

	ball = make("Frame", {
		Name = "Alvo",
		Size = UDim2.fromOffset(22, 22),
		Position = UDim2.new(0.5, -11, 0.5, -11),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = true,
		Visible = false,
		ZIndex = 5,
	}, screen)
	border(ball)
	make("Frame", {
		Size = UDim2.fromOffset(4, 4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = GREEN,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, ball)
	drag(ball, ball, function()
		return not clicking
	end)

	local function setClicking(on)
		clicking = on
		runId += 1
		local id = runId
		ball.Active = not on
		setOn(clickBtn, on, "CLICAR " .. (on and "ON" or "OFF"))
		if on then
			task.spawn(function()
				while clicking and runId == id do
					local c = ball.AbsolutePosition + ball.AbsoluteSize / 2
					doClick(c.X, c.Y)
					task.wait(interval)
				end
			end)
		end
	end

	setOn(ballBtn, false, "BOLA OFF")
	setOn(clickBtn, false, "CLICAR OFF")

	ballBtn.MouseButton1Click:Connect(function()
		local show = not ball.Visible
		ball.Visible = show
		setOn(ballBtn, show, "BOLA " .. (show and "ON" or "OFF"))
		if not show then
			setClicking(false)
		end
	end)

	clickBtn.MouseButton1Click:Connect(function()
		if not ball.Visible then
			status("ATIVE A BOLA PRIMEIRO")
			return
		end
		status("")
		setClicking(not clicking)
	end)

	slider(body, 0, 44, 222, MIN_T, MAX_T, 0.1, interval, function(v)
		interval = math.floor(v * 10 + 0.5) / 10
		intervalL.Text = string.format("INTERVALO: %.1fs", interval)
	end)
end

---------------------------------------------------------------------
-- SCRIPT: TELETRANSPORTE
---------------------------------------------------------------------
local function openTeleport()
	local MAX_DISTANCE, COOLDOWN = 5000, 9.5
	local enabled, cooldownEnd = false, 0

	local function teleportTo(position, normal)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return false
		end

		local boxCF, boxSize = char:GetBoundingBox()
		local feetToRoot = hrp.Position.Y - (boxCF.Position.Y - boxSize.Y / 2)
		local width = math.max(hrp.Size.X, hrp.Size.Z) + 1.5
		local radius = width / 2
		local checkSize = Vector3.new(width, math.max(boxSize.Y - 0.4, 1), width)

		local flat = Vector3.new(normal.X, 0, normal.Z)
		local dir = flat.Magnitude > 0.1 and flat.Unit or Vector3.zero
		local feet = position + dir * (radius + 0.3)

		local overlap = OverlapParams.new()
		overlap.FilterType = Enum.RaycastFilterType.Exclude
		overlap.FilterDescendantsInstances = { char }
		overlap.RespectCanCollide = true

		local chosen = feet
		for i = 0, 30 do
			local candidate = feet + Vector3.new(0, i * 0.5, 0) + dir * (i * 0.15)
			local center = candidate + Vector3.new(0, checkSize.Y / 2 + 0.2, 0)
			if #workspace:GetPartBoundsInBox(CFrame.new(center), checkSize, overlap) == 0 then
				chosen = candidate
				break
			end
		end

		local rotation = hrp.CFrame - hrp.CFrame.Position
		char:PivotTo(CFrame.new(chosen + Vector3.new(0, feetToRoot + 0.1, 0)) * rotation)
		hrp.AssemblyLinearVelocity = Vector3.zero
		return true
	end

	local f, body = createWindow("TELEPORTE", "TELETRANSPORTE.EXE", center(-60, 60))

	local tBtn = btn(body, "", 0, 0, 222)
	local stat = label(body, "PRONTO", 0, 26, 222, 14)
	label(body, "ative e clique no mapa", 0, 46, 222, 14)
	label(body, "espera de " .. COOLDOWN .. "s entre usos", 0, 62, 222, 14)

	setOn(tBtn, false, "TELEPORTE OFF")
	tBtn.MouseButton1Click:Connect(function()
		enabled = not enabled
		setOn(tBtn, enabled, "TELEPORTE " .. (enabled and "ON" or "OFF"))
	end)

	bind(f, RunService.Heartbeat:Connect(function()
		local r = cooldownEnd - os.clock()
		stat.Text = r > 0 and string.format("AGUARDE %.1fs", r) or "PRONTO"
	end))

	bind(f, UIS.InputBegan:Connect(function(input, gp)
		if gp or not enabled or os.clock() < cooldownEnd then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local cam = workspace.CurrentCamera
		local char = player.Character
		local ray = cam:ScreenPointToRay(input.Position.X, input.Position.Y)

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = char and { char } or {}

		local result = workspace:Raycast(ray.Origin, ray.Direction * MAX_DISTANCE, params)
		if result and teleportTo(result.Position, result.Normal) then
			cooldownEnd = os.clock() + COOLDOWN
		end
	end))
end

---------------------------------------------------------------------
-- SCRIPT: ÁUDIO
---------------------------------------------------------------------
local function openAudio()
	local RADIUS_STEPS = { 1, 5, 10, 20, 30, 40, 50 }
	local SCAN_INTERVAL = 0.5
	local radiusIdx = 6
	local scanRadius = RADIUS_STEPS[radiusIdx]
	local detectOn = false
	local records = {}
	local trackedSounds = {}
	local playingId = nil

	local previewSound = Instance.new("Sound")
	previewSound.Volume = 0.5
	previewSound.Parent = SoundService

	local circle = Instance.new("Part")
	circle.Name = "AreaScan"
	circle.Shape = Enum.PartType.Cylinder
	circle.Size = Vector3.new(0.2, scanRadius * 2, scanRadius * 2)
	circle.Anchored = true
	circle.CanCollide = false
	circle.CanQuery = false
	circle.CanTouch = false
	circle.CastShadow = false
	circle.Material = Enum.Material.Neon
	circle.Color = GREEN
	circle.Transparency = 1
	circle.Parent = workspace

	local f, body = createWindow("AUDIO", "AUDIO.EXE", center(80, -40), function()
		previewSound:Destroy()
		circle:Destroy()
	end)

	local detectBtn = btn(body, "", 0, 0, 72)
	local radBtn = btn(body, "RAIO " .. scanRadius, 76, 0, 72)
	local clearBtn = btn(body, "LIMPAR", 152, 0, 70)
	local stopBtn = btn(body, "PARAR", 0, 24, 56)
	local statusL = label(body, "", 62, 24, 160, 18)
	statusL.TextTruncate = Enum.TextTruncate.AtEnd

	local list = make("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 1, -48),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = GREEN,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, body)
	make("UIListLayout", {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)

	local function status(t)
		statusL.Text = t
	end

	local function refreshRows()
		for _, row in ipairs(list:GetChildren()) do
			if row:IsA("Frame") then
				local playing = playingId ~= nil and row:GetAttribute("SongId") == playingId
				row.BackgroundTransparency = playing and 0.4 or 0.8
				row.BackgroundColor3 = DARK
				local pb = row:FindFirstChild("Play")
				if pb then
					setOn(pb, playing, playing and "STOP" or "PLAY")
				end
			end
		end
	end

	local function stopPreview()
		previewSound:Stop()
		playingId = nil
		refreshRows()
	end

	local function playSong(id)
		if playingId == id then
			stopPreview()
			return
		end
		previewSound:Stop()
		previewSound.SoundId = "rbxassetid://" .. id
		previewSound:Play()
		playingId = id
		status("TOCANDO " .. id)
		refreshRows()
	end

	previewSound.Ended:Connect(function()
		playingId = nil
		refreshRows()
	end)

	local function copyId(id)
		if setclipboard then
			setclipboard(id)
			status("ID COPIADO: " .. id)
		else
			status("ID: " .. id)
		end
	end

	local function addDetected(sound, owner)
		local id = string.match(sound.SoundId, "%d+")
		if not id or records[id] then
			return
		end
		records[id] = true

		local name = sound.Name ~= "Sound" and sound.Name or "Musica"
		if owner then
			name = name .. " - " .. owner.DisplayName
		end

		local row = make("Frame", {
			Size = UDim2.new(1, -4, 0, 24),
			BackgroundColor3 = BLACK,
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
		}, list)
		border(row, DIM)
		row:SetAttribute("SongId", id)

		local t = label(row, name .. " " .. id, 4, 0, 140, 24)
		t.TextTruncate = Enum.TextTruncate.AtEnd

		local pb = btn(row, "PLAY", 146, 3, 34, 18)
		pb.Name = "Play"
		pb.MouseButton1Click:Connect(function()
			playSong(id)
		end)
		btn(row, "COPY", 184, 3, 34, 18).MouseButton1Click:Connect(function()
			copyId(id)
		end)

		refreshRows()
	end

	setOn(detectBtn, false, "DETECT OFF")
	detectBtn.MouseButton1Click:Connect(function()
		detectOn = not detectOn
		setOn(detectBtn, detectOn, "DETECT " .. (detectOn and "ON" or "OFF"))
		circle.Transparency = detectOn and 0.7 or 1
	end)

	radBtn.MouseButton1Click:Connect(function()
		radiusIdx = radiusIdx % #RADIUS_STEPS + 1
		scanRadius = RADIUS_STEPS[radiusIdx]
		radBtn.Text = "RAIO " .. scanRadius
		circle.Size = Vector3.new(0.2, scanRadius * 2, scanRadius * 2)
		status("RAIO: " .. scanRadius .. " studs")
	end)

	clearBtn.MouseButton1Click:Connect(function()
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("Frame") then
				c:Destroy()
			end
		end
		records = {}
	end)

	stopBtn.MouseButton1Click:Connect(function()
		if playingId then
			stopPreview()
			status("MUSICA PARADA")
		end
	end)

	local function trackSound(d)
		if d:IsA("Sound") then
			trackedSounds[d] = true
		end
	end
	for _, d in ipairs(workspace:GetDescendants()) do
		trackSound(d)
	end
	bind(f, workspace.DescendantAdded:Connect(trackSound))
	bind(f, workspace.DescendantRemoving:Connect(function(d)
		trackedSounds[d] = nil
	end))

	local function getSoundPosition(sound)
		local p = sound.Parent
		if not p then
			return nil
		end
		if p:IsA("BasePart") then
			return p.Position
		elseif p:IsA("Attachment") then
			return p.WorldPosition
		elseif p:IsA("Model") then
			return p:GetPivot().Position
		elseif p.Parent and p.Parent:IsA("BasePart") then
			return p.Parent.Position
		end
		return nil
	end

	local function getOwner(inst)
		local cur = inst
		while cur and cur ~= workspace do
			local p = Players:GetPlayerFromCharacter(cur)
			if p then
				return p
			end
			cur = cur.Parent
		end
		return nil
	end

	local function scan(root)
		for sound in pairs(trackedSounds) do
			if sound.IsPlaying and sound.SoundId ~= "" and sound:IsDescendantOf(workspace) then
				local pos = getSoundPosition(sound)
				if pos and (pos - root.Position).Magnitude <= scanRadius then
					local owner = getOwner(sound)
					if owner ~= player then
						addDetected(sound, owner)
					end
				end
			end
		end
	end

	local groundParams = RaycastParams.new()
	groundParams.FilterType = Enum.RaycastFilterType.Exclude
	local scanAcc = 0

	bind(f, RunService.Heartbeat:Connect(function(dt)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end

		groundParams.FilterDescendantsInstances = { char, circle }
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -100, 0), groundParams)
		local y = hit and hit.Position.Y or (root.Position.Y - 3)
		circle.CFrame = CFrame.new(root.Position.X, y + 0.1, root.Position.Z) * CFrame.Angles(0, 0, math.rad(90))

		scanAcc += dt
		if scanAcc >= SCAN_INTERVAL meen
			scanAcc = 0
			if detectOn then
				scan(root)
			end
		end
	end))
end

---------------------------------------------------------------------
-- TERMINAL
---------------------------------------------------------------------
local SCRIPTS = {
	{ win = "VELOCIDADE", title = "Velocidade", names = { "velocidade" }, open = openVelocidade },
	{ win = "AUTOCLICK", title = "Auto click", names = { "auto click", "autoclick" }, open = openAutoClick },
	{ win = "TELEPORTE", title = "Teletransporte", names = { "teletransporte", "teleporte" }, open = openTeleport },
	{ win = "AUDIO", title = "Áudio", names = { "áudio", "Áudio", "audio" }, open = openAudio },
}

local function findScript(cmd)
	local low = cmd:lower()
	for _, s in ipairs(SCRIPTS) do
		for _, n in ipairs(s.names) do
			if n == cmd or n == low then
				return s
			end
		end
	end
	return nil
end

local _, body = createWindow("TERMINAL", "TERMINAL.EXE", center(0, -60))

local lines = {}
local logBox = make("Frame", {
	Size = UDim2.new(1, 0, 0, 172),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
}, body)
local log = make("TextLabel", {
	Size = UDim2.new(1, -4, 1, 0),
	Position = UDim2.fromOffset(2, 0),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = GREEN,
	Font = FONT,
	TextSize = 11,
	TextXAlignment = LEFT,
	TextYAlignment = Enum.TextYAlignment.Bottom,
	TextWrapped = true,
}, logBox)

local function out(t)
	table.insert(lines, t)
	if #lines > 60 then
		table.remove(lines, 1)
	end
	log.Text = table.concat(lines, "\n")
end

label(body, "C:\\>", 0, 192, 30, 20)
local box = make("TextBox", {
	Size = UDim2.new(1, -34, 0, 20),
	Position = UDim2.fromOffset(32, 192),
	BackgroundColor3 = BLACK,
	BackgroundTransparency = 0.6,
	BorderSizePixel = 0,
	Text = "",
	TextColor3 = GREEN,
	PlaceholderText = "digite um script",
	PlaceholderColor3 = DIM,
	Font = FONT,
	TextSize = 11,
	ClearTextOnFocus = false,
	TextXAlignment = LEFT,
}, body)
border(box)

local busy = false
local function setBusy(b)
	busy = b
	box.TextEditable = not b
end

-- Carregamento falso (de 5 em 5)
local function loadScript(s)
	setBusy(true)
	out("carregando " .. s.title .. "...")
	out("")
	local idx = #lines
	local BAR = 16

	task.spawn(function()
		local pct = 0
		while pct < 100 do
			pct = math.min(100, pct + 5)
			local filled = math.floor(pct / 100 * BAR)
			lines[idx] = string.format("[%s%s] %3d%%", string.rep("#", filled), string.rep(".", BAR - filled), pct)
			log.Text = table.concat(lines, "\n")
			task.wait(0.04)
		end
		out("OK")
		local ok, err = pcall(s.open)
		if not ok then
			out("erro: " .. tostring(err))
		end
		setBusy(false)
	end)
end

-- Função central de teletransporte
local function doTp(dest)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		out("erro: personagem nao encontrado")
		return
	end

	if dest == "obby" then
		hrp.CFrame = CFrame.new(268.144379, 564.02533, -395.471619, 0.985219181, 1.49917927e-08, -0.171298385, -5.62155899e-13, 1, 8.75153532e-08)
		hrp.AssemblyLinearVelocity = Vector3.zero
		out("tp: obby concluido!")
	elseif dest == "mm2" then
		hrp.CFrame = CFrame.new(4.62986183, 200.773758, -84.0759659, 0.999350965, -1.16016832e-08, 0.0360236466, 8.67450112e-09, 1, 8.14135461e-08)
		hrp.AssemblyLinearVelocity = Vector3.zero
		out("tp: mm2 concluido!")
	else
		out("destino desconhecido: " .. dest)
	end
end

-- Som só ao digitar
local prevLen = 0
box:GetPropertyChangedSignal("Text"):Connect(function()
	local len = #box.Text
	if len > prevLen then
		sfx(KEY_SFX)
	end
	prevLen = len
end)

local tpState = false

-- Enter envia o comando
box.FocusLost:Connect(function(enter)
	if not enter or busy then
		return
	end

	local cmd = (box.Text:match("^%s*(.-)%s*$")) or ""
	box.Text = ""
	prevLen = 0
	sfx(ENTER_SFX)

	local low = cmd:lower()

	if cmd == "" then
		-- nada
	elseif tpState then
		tpState = false
		doTp(low)
	elseif low == "tp obby" then
		doTp("obby")
	elseif low == "tp mm2" then
		doTp("mm2")
	elseif low == "tp" then
		tpState = true
		out("escolha: obby / mm2")
	elseif low == "help" or low == "ajuda" then
		out("velocidade | auto click | teletransporte | áudio")
		out("tp = obby / mm2")
		out("clear = limpa a tela")
	elseif low == "clear" or low == "limpar" then
		lines = {}
		log.Text = ""
	else
		local s = findScript(cmd)
		if not s then
			out("comando nao encontrado: " .. cmd)
		elseif screen:FindFirstChild(s.win) then
			out(s.title .. " ja esta aberto")
		else
			loadScript(s)
		end
	end

	task.defer(function()
		if not busy then
			box:CaptureFocus()
		end
	end)
end)
