-- настройки: правь тут, меню нет специально
local SHOW_BOX    = true
local SHOW_NAME   = false
local SHOW_DIST   = true
local SHOW_TRACER = false
local MAX_DIST    = 900
local BOX_COLOR   = Color3.fromRGB(255, 255, 255)
local LINE_COLOR  = Color3.fromRGB(205, 205, 210)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local drawings = {}

local function getDraw(model)
	local d = drawings[model]
	if not d then
		d = {}
		d.box = Drawing.new("Square")
		d.box.Thickness = 1
		d.box.Filled = false
		d.box.Transparency = 1
		d.box.Visible = false
		d.text = Drawing.new("Text")
		d.text.Size = 13
		d.text.Center = true
		d.text.Outline = true
		d.text.Transparency = 1
		d.text.Visible = false
		d.line = Drawing.new("Line")
		d.line.Thickness = 1
		d.line.Transparency = 1
		d.line.Visible = false
		drawings[model] = d
	end
	return d
end

local function hide(d)
	d.box.Visible = false
	d.text.Visible = false
	d.line.Visible = false
end

local function alive(model)
	local hum = model:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

local function bounds(model)
	local ok, cf, size = pcall(function() return model:GetBoundingBox() end)
	if not ok or not cf then return nil end
	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	for xi = -0.5, 0.5, 1 do
		for yi = -0.5, 0.5, 1 do
			for zi = -0.5, 0.5, 1 do
				local sp, on = Camera:WorldToViewportPoint(cf * Vector3.new(xi * size.X, yi * size.Y, zi * size.Z))
				if on then
					if sp.X < minX then minX = sp.X end
					if sp.X > maxX then maxX = sp.X end
					if sp.Y < minY then minY = sp.Y end
					if sp.Y > maxY then maxY = sp.Y end
				end
			end
		end
	end
	if minX == math.huge then return nil end
	return minX, minY, maxX, maxY
end

local function step()
	Camera = Workspace.CurrentCamera
	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local myPos = myRoot and myRoot.Position or Camera.CFrame.Position

	local seen = {}
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("Model") and obj ~= myChar and alive(obj) then
			seen[obj] = true
			local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj.PrimaryPart
			local d = getDraw(obj)
			local x0, y0, x1, y1
			if root then
				local dist = (myPos - root.Position).Magnitude
				if dist <= MAX_DIST then
					x0, y0, x1, y1 = bounds(obj)
				end
			end

			if not x0 then
				hide(d)
			else
				local cx = (x0 + x1) / 2
				if SHOW_BOX then
					d.box.Size = Vector2.new(x1 - x0, y1 - y0)
					d.box.Position = Vector2.new(x0, y0)
					d.box.Color = BOX_COLOR
					d.box.Visible = true
				else
					d.box.Visible = false
				end

				if SHOW_DIST or SHOW_NAME then
					local label = ""
					if SHOW_NAME then label = obj.Name .. "  " end
					if SHOW_DIST then
						local dist = (myPos - root.Position).Magnitude
						label = label .. math.floor(dist + 0.5) .. "m"
					end
					d.text.Text = label
					d.text.Position = Vector2.new(cx, y1 + 2)
					d.text.Color = BOX_COLOR
					d.text.Visible = true
				else
					d.text.Visible = false
				end

				if SHOW_TRACER then
					local vs = Camera.ViewportSize
					d.line.From = Vector2.new(vs.X / 2, vs.Y)
					d.line.To = Vector2.new(cx, y1)
					d.line.Color = LINE_COLOR
					d.line.Visible = true
				else
					d.line.Visible = false
				end
			end
		end
	end

	for model, d in pairs(drawings) do
		if not seen[model] then hide(d) end
	end
end

RunService.RenderStepped:Connect(function()
	pcall(step)
end)
