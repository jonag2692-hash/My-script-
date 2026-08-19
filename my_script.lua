-- my_script.lua (updated by Copilot):
-- Changes: aimbot/aim assist (sticky aim), mobility moved, car fly/drift moved to MAIN, mobile toggles manual, fixed infinite jump, UTF-8 arrows fixed

local P, RS, U = game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService")
local p = P.LocalPlayer

-- Feature flags / state
local state = {
    infiniteJump = true,
    espEnabled = false,
    espTracers = true,
    espNames = true,
    espArrows = true,
    teamCheck = true,

    hitboxSize = 2,
    hitboxTransparency = 100,
    hitboxEnabled = false,

    -- fly
    fly = false,
    flySpeed = 50,

    -- vehicle
    vehicleFly = false,
    vehicleFlySpeed = 50,
    carControl = false,
    carSpeed = 100,
    carDrift = false,

    -- mob UI
    showMobileButtons = false,

    -- sticky aim / aimbot
    aimAssist = false,
    stickyAim = false,
    stickyAimPart = "Head", -- or "Body"
    stickyTeamCheck = true,
    stickyRemove = false,
}

local ncConn, flyRc, vFlyRc, carRc, espRc, stickyRc

-- Utility creator
local function c(cl, parent, props)
    local obj = Instance.new(cl)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

-- GUI root
local g = c("ScreenGui", p:WaitForChild("PlayerGui"), {Name = "JonaHubNew", ResetOnSpawn = false})

-- Loading
local loadBg = c("Frame", g, {Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.fromRGB(10,10,10), ZIndex = 100})
local loadTitle = c("TextLabel", loadBg, {Size = UDim2.new(0,300,0,50), Position = UDim2.new(0.5, -150, 0.42, -40), BackgroundTransparency = 1, Text = "Jona hub", TextColor3 = Color3.new(1,1,1), TextSize = 24, Font = Enum.Font.SourceSansBold, ZIndex = 101})
local barBg = c("Frame", loadBg, {Size = UDim2.new(0,300,0,6), Position = UDim2.new(0.5,-150,0.52,0), BackgroundColor3 = Color3.fromRGB(30,30,30), ZIndex = 101})
c("UICorner", barBg, {CornerRadius = UDim.new(1,0)})
local barFill = c("Frame", barBg, {Size = UDim2.new(0,0,1,0), BackgroundColor3 = Color3.new(1,1,1), ZIndex = 102})
c("UICorner", barFill, {CornerRadius = UDim.new(1,0)})

-- Main window
local main = c("Frame", g, {Size = UDim2.new(0,520,0,360), Position = UDim2.new(0.5, -260, 0.5, -180), BackgroundColor3 = Color3.fromRGB(15,15,15), Active = true, Draggable = true, Visible = false})
c("UICorner", main, {CornerRadius = UDim.new(0,8)})

local leftBtn = c("Frame", main, {Size = UDim2.new(0, 120, 1, -45), Position = UDim2.new(0,8,0,40), BackgroundColor3 = Color3.fromRGB(22,22,22)})
c("UICorner", leftBtn, {CornerRadius = UDim.new(0,6)})
local content = c("Frame", main, {Size = UDim2.new(1, -146, 1, -45), Position = UDim2.new(0, 136, 0, 40), BackgroundColor3 = Color3.fromRGB(22,22,22)})
c("UICorner", content, {CornerRadius = UDim.new(0,6)})

-- Tabs
local tabMain = c("TextButton", leftBtn, {Size = UDim2.new(1,-10,0,32), Position = UDim2.new(0,5,0,5), BackgroundColor3 = Color3.fromRGB(35,35,35), Text = "MAIN", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSansBold, TextSize = 14})
c("UICorner", tabMain, {CornerRadius = UDim.new(0,4)})
local tabCombat = c("TextButton", leftBtn, {Size = UDim2.new(1,-10,0,32), Position = UDim2.new(0,5,0,42), BackgroundColor3 = Color3.fromRGB(28,28,28), Text = "COMBAT", TextColor3 = Color3.fromRGB(180,180,180), Font = Enum.Font.SourceSansBold, TextSize = 14})
c("UICorner", tabCombat, {CornerRadius = UDim.new(0,4)})
local tabExtra = c("TextButton", leftBtn, {Size = UDim2.new(1,-10,0,32), Position = UDim2.new(0,5,0,79), BackgroundColor3 = Color3.fromRGB(28,28,28), Text = "EXTRA", TextColor3 = Color3.fromRGB(180,180,180), Font = Enum.Font.SourceSansBold, TextSize = 14})
c("UICorner", tabExtra, {CornerRadius = UDim.new(0,4)})

local pageMain = c("ScrollingFrame", content, {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = true, CanvasSize = UDim2.new(0,0,0,600), ScrollBarThickness = 6})
local pageCombat = c("ScrollingFrame", content, {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false, CanvasSize = UDim2.new(0,0,0,600), ScrollBarThickness = 6})
local pageExtra = c("ScrollingFrame", content, {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false, CanvasSize = UDim2.new(0,0,0,600), ScrollBarThickness = 6})

local function switch(a,b,c)
    pageMain.Visible, pageCombat.Visible, pageExtra.Visible = a,b,c
    tabMain.BackgroundColor3, tabMain.TextColor3 = a and Color3.fromRGB(35,35,35) or Color3.fromRGB(28,28,28), a and Color3.new(1,1,1) or Color3.fromRGB(180,180,180)
    tabCombat.BackgroundColor3, tabCombat.TextColor3 = b and Color3.fromRGB(35,35,35) or Color3.fromRGB(28,28,28), b and Color3.new(1,1,1) or Color3.fromRGB(180,180,180)
    tabExtra.BackgroundColor3, tabExtra.TextColor3 = c and Color3.fromRGB(35,35,35) or Color3.fromRGB(28,28,28), c and Color3.new(1,1,1) or Color3.fromRGB(180,180,180)
end

tabMain.MouseButton1Click:Connect(function() switch(true,false,false) end)
tabCombat.MouseButton1Click:Connect(function() switch(false,true,false) end)
tabExtra.MouseButton1Click:Connect(function() switch(false,false,true) end)

local function btn(parent, text, y, color)
    local b = c("TextButton", parent, {Size = UDim2.new(0,350,0,30), Position = UDim2.new(0,12,0,y), BackgroundColor3 = color or Color3.fromRGB(35,35,35), Text = text, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.SourceSans, TextSize = 14})
    c("UICorner", b, {CornerRadius = UDim.new(0,5)})
    return b
end

-- MOBILITY section in MAIN
local walkBox = c("TextBox", pageMain, {Size = UDim2.new(0,170,0,30), Position = UDim2.new(0,12,0,12), BackgroundColor3 = Color3.fromRGB(35,35,35), Text = "16", PlaceholderText = "WalkSpeed", TextColor3 = Color3.new(1,1,1)})
c("UICorner", walkBox, {CornerRadius = UDim.new(0,5)})
local jumpBox = c("TextBox", pageMain, {Size = UDim2.new(0,170,0,30), Position = UDim2.new(0,192,0,12), BackgroundColor3 = Color3.fromRGB(35,35,35), Text = "50", PlaceholderText = "JumpPower", TextColor3 = Color3.new(1,1,1)})
c("UICorner", jumpBox, {CornerRadius = UDim.new(0,5)})

local applyWalkJump = btn(pageMain, "Apply Walk & Jump", 54, Color3.fromRGB(50,50,50))
applyWalkJump.MouseButton1Click:Connect(function()
    local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    if h then
        local ws = tonumber(walkBox.Text)
        local js = tonumber(jumpBox.Text)
        if ws then h.WalkSpeed = ws end
        if js then h.JumpPower = js end
    end
end)

local infBtn = btn(pageMain, "Infinite Jump: ON", 94, Color3.fromRGB(35,35,35))
infBtn.MouseButton1Click:Connect(function()
    state.infiniteJump = not state.infiniteJump
    infBtn.Text = "Infinite Jump: "..(state.infiniteJump and "ON" or "OFF")
end)

-- move noclip into mobility
local noclipBtn = btn(pageMain, "Noclip: OFF", 134, Color3.fromRGB(25,25,25))
local ncActive = false
local ncLoop
noclipBtn.MouseButton1Click:Connect(function()
    ncActive = not ncActive
    noclipBtn.Text = "Noclip: "..(ncActive and "ON" or "OFF")
    noclipBtn.BackgroundColor3 = ncActive and Color3.fromRGB(70,70,70) or Color3.fromRGB(25,25,25)
    if ncActive then
        ncLoop = RS.Stepped:Connect(function()
            if p.Character then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if ncLoop then ncLoop:Disconnect() ncLoop = nil end
    end
end)

-- Fix infinite jump to work reliably on all platforms
U.JumpRequest:Connect(function()
    if state.infiniteJump and p.Character then
        local h = p.Character:FindFirstChildOfClass("Humanoid")
        if h then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- FLY + CAR controls moved to MAIN
local flyBtn = btn(pageMain, "Fly: OFF", 174, Color3.fromRGB(25,25,25))
local flySpeedBox = c("TextBox", pageMain, {Size = UDim2.new(0,100,0,30), Position = UDim2.new(0,262,0,174), BackgroundColor3 = Color3.fromRGB(35,35,35), Text = tostring(state.flySpeed)})
c("UICorner", flySpeedBox, {CornerRadius = UDim.new(0,5)})

local carBtn = btn(pageMain, "Car Control: OFF", 214, Color3.fromRGB(25,25,25))
local carSpeedBox = c("TextBox", pageMain, {Size = UDim2.new(0,100,0,30), Position = UDim2.new(0,262,0,214), BackgroundColor3 = Color3.fromRGB(35,35,35), Text = tostring(state.carSpeed)})
c("UICorner", carSpeedBox, {CornerRadius = UDim.new(0,5)})

local driftBtn = btn(pageMain, "Drift: OFF", 254, Color3.fromRGB(25,25,25))

-- mobile button visibility control
local showMobileBtn = btn(pageMain, "Show Mobile Buttons: OFF", 294, Color3.fromRGB(25,25,25))
showMobileBtn.MouseButton1Click:Connect(function()
    state.showMobileButtons = not state.showMobileButtons
    showMobileBtn.Text = "Show Mobile Buttons: "..(state.showMobileButtons and "ON" or "OFF")
    showMobileBtn.BackgroundColor3 = state.showMobileButtons and Color3.fromRGB(70,70,70) or Color3.fromRGB(25,25,25)
    mobileCarBtn.Visible = state.showMobileButtons and U.TouchEnabled or false
    mobileDriftBtn.Visible = state.showMobileButtons and U.TouchEnabled or false
    mobileStickyBtn.Visible = state.showMobileButtons and U.TouchEnabled or false
end)

-- Fly implementation (simple body movers)
local flyBV, flyBG
local function stopFly()
    state.fly = false
    if flyRc then flyRc:Disconnect() flyRc = nil end
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    flyBtn.Text = "Fly: OFF"
    flyBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)
end

local function startFly()
    local ch = p.Character if not ch or not ch:FindFirstChild("HumanoidRootPart") then return end
    state.fly = true
    ch.Humanoid.PlatformStand = true
    local hrp = ch.HumanoidRootPart
    flyBG = c("BodyGyro", hrp, {P = 9e4, MaxTorque = Vector3.new(9e9,9e9,9e9), CFrame = hrp.CFrame})
    flyBV = c("BodyVelocity", hrp, {Velocity = Vector3.new(0,0.1,0), MaxForce = Vector3.new(9e9,9e9,9e9)})
    flyBtn.Text = "Fly: ON"
    flyBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    flyRc = RS.RenderStepped:Connect(function()
        if not state.fly then return end
        local cam = workspace.CurrentCamera
        if flyBG and flyBG.Parent then flyBG.CFrame = cam.CFrame end
        local s = tonumber(flySpeedBox.Text) or 50
        local v = ch.Humanoid.MoveDirection * s
        if U:IsKeyDown(Enum.KeyCode.Space) then v = v + Vector3.new(0,s,0) elseif U:IsKeyDown(Enum.KeyCode.LeftShift) then v = v + Vector3.new(0,-s,0) end
        if flyBV and flyBV.Parent then flyBV.Velocity = v end
    end)
end

flyBtn.MouseButton1Click:Connect(function()
    if state.fly then stopFly() else startFly() end
end)

-- Vehicle / car controller (auto works when seated)
local mobileCarBtn = c("TextButton", g, {Size = UDim2.new(0,80,0,40), Position = UDim2.new(0,10,1,-100), BackgroundColor3 = Color3.fromRGB(40,40,40), Text = "Car OFF", Visible = false, ZIndex = 150})
c("UICorner", mobileCarBtn, {CornerRadius = UDim.new(0,8)})
local mobileDriftBtn = c("TextButton", g, {Size = UDim2.new(0,80,0,40), Position = UDim2.new(0,100,1,-100), BackgroundColor3 = Color3.fromRGB(40,40,40), Text = "Drift OFF", Visible = false, ZIndex = 150})
c("UICorner", mobileDriftBtn, {CornerRadius = UDim.new(0,8)})
local mobileStickyBtn = c("TextButton", g, {Size = UDim2.new(0,80,0,40), Position = UDim2.new(0,190,1,-100), BackgroundColor3 = Color3.fromRGB(40,40,40), Text = "Sticky OFF", Visible = false, ZIndex = 150})
c("UICorner", mobileStickyBtn, {CornerRadius = UDim.new(0,8)})

local function stopCarControl()
    state.carControl = false
    if carRc then carRc:Disconnect() carRc = nil end
    carBtn.Text = "Car Control: OFF"
    carBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)
    mobileCarBtn.Text = "Car OFF"
end

local function startCarControl()
    if carRc then return end
    state.carControl = true
    carBtn.Text = "Car Control: ON"
    carBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    mobileCarBtn.Text = "Car ON"
    carRc = RS.RenderStepped:Connect(function()
        if not state.carControl then return end
        local ch = p.Character
        local humanoid = ch and ch:FindFirstChildOfClass("Humanoid")
        local seat = humanoid and humanoid.SeatPart
        if not seat or not seat.Parent then return end
        local vehicleRoot = seat.AssemblyRootPart or seat.Parent:FindFirstChild("HumanoidRootPart") or seat
        if not vehicleRoot then return end
        local bv = vehicleRoot:FindFirstChild("JH_CarBV")
        local bg = vehicleRoot:FindFirstChild("JH_CarBG")
        if not bv then bv = Instance.new("BodyVelocity"); bv.Name = "JH_CarBV"; bv.MaxForce = Vector3.new(1e6,1e6,1e6); bv.P = 1000; bv.Parent = vehicleRoot end
        if not bg then bg = Instance.new("BodyGyro"); bg.Name = "JH_CarBG"; bg.MaxTorque = Vector3.new(4e5,4e5,4e5); bg.P = 3000; bg.Parent = vehicleRoot end
        local cam = workspace.CurrentCamera
        local moveVector = Vector3.new()
        local throttle = seat.Throttle or 0
        local steer = seat.Steer or 0
        if U:IsKeyDown(Enum.KeyCode.W) or throttle > 0 then moveVector = moveVector + cam.CFrame.LookVector end
        if U:IsKeyDown(Enum.KeyCode.S) or throttle < 0 then moveVector = moveVector - cam.CFrame.LookVector end
        if U:IsKeyDown(Enum.KeyCode.A) or steer < 0 then moveVector = moveVector - cam.CFrame.RightVector end
        if U:IsKeyDown(Enum.KeyCode.D) or steer > 0 then moveVector = moveVector + cam.CFrame.RightVector end
        local baseSpeed = tonumber(carSpeedBox.Text) or state.carSpeed
        if moveVector.Magnitude > 0 then
            local vel = moveVector.Unit * baseSpeed
            -- improved drift: use steer and add lateral momentum if drifting
            if state.carDrift then
                local lateralMul = 0.45
                local lat = cam.CFrame.RightVector * (steer * baseSpeed * lateralMul)
                vel = vel + Vector3.new(lat.X, 0, lat.Z)
            end
            local curY = vehicleRoot.Velocity and vehicleRoot.Velocity.Y or 0
            bv.Velocity = Vector3.new(vel.X, curY, vel.Z)
            bg.CFrame = cam.CFrame
        else
            bv.Velocity = Vector3.new(0, vehicleRoot.Velocity.Y, 0)
        end
    end)
end

carBtn.MouseButton1Click:Connect(function()
    state.carControl = not state.carControl
    if state.carControl then startCarControl() else stopCarControl() end
end)

driftBtn.MouseButton1Click:Connect(function()
    state.carDrift = not state.carDrift
    driftBtn.Text = "Drift: "..(state.carDrift and "ON" or "OFF")
    driftBtn.BackgroundColor3 = state.carDrift and Color3.fromRGB(70,70,70) or Color3.fromRGB(25,25,25)
    mobileDriftBtn.Text = state.carDrift and "Drift ON" or "Drift OFF"
end)

mobileCarBtn.MouseButton1Click:Connect(function()
    state.carControl = not state.carControl
    if state.carControl then startCarControl() else stopCarControl() end
end)
mobileDriftBtn.MouseButton1Click:Connect(function()
    state.carDrift = not state.carDrift
    driftBtn.Text = "Drift: "..(state.carDrift and "ON" or "OFF")
    mobileDriftBtn.Text = state.carDrift and "Drift ON" or "Drift OFF"
end)

-- Sticky Aim / Aim Assist (COMBAT tab)
local aimBtn = btn(pageCombat, "Aimbot/Aim Assist: OFF", 12, Color3.fromRGB(25,25,25))
local stickyBtn = btn(pageCombat, "Sticky Aim: OFF", 52, Color3.fromRGB(25,25,25))
local stickPartBtn = btn(pageCombat, "Sticky Target: Head", 92, Color3.fromRGB(35,35,35))
local stickyTeamBtn = btn(pageCombat, "Team Check: ON", 132, Color3.fromRGB(70,70,70))
local removeStickBtn = btn(pageCombat, "Remove Sticking: OFF", 172, Color3.fromRGB(25,25,25))

local function isValidTarget(target)
    if not target or not target.Character then return false end
    if not target.Character:FindFirstChild("HumanoidRootPart") then return false end
    if target == p then return false end
    if state.stickyTeamCheck and p.Team and target.Team and p.Team == target.Team then return false end
    -- simple alive check
    local h = target.Character:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return false end
    return true
end

local function wallCheck(fromPos, toPos)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {p.Character}
    local res = workspace:Raycast(fromPos, (toPos - fromPos), rayParams)
    if res then
        -- if hit something before target, block
        return false
    end
    return true
end

local function findNearestTarget()
    local cam = workspace.CurrentCamera
    local camPos = cam.CFrame.Position
    local best, bestDist = nil, math.huge
    for _, pl in ipairs(P:GetPlayers()) do
        if isValidTarget(pl) then
            local char = pl.Character
            local part = (state.stickyAimPart == "Head") and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")) or (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") )
            if part then
                local pos = part.Position
                if wallCheck(camPos, pos) then
                    local d = (pos - camPos).Magnitude
                    if d < bestDist then bestDist, best = d, pl end
                end
            end
        end
    end
    return best
end

local function startStickyAim()
    if stickyRc then return end
    stickyRc = RS.RenderStepped:Connect(function()
        if not state.stickyAim then return end
        local target = findNearestTarget()
        if target and target.Character then
            local part = (state.stickyAimPart == "Head") and (target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")) or (target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Torso"))
            if part then
                -- point camera towards part
                local cam = workspace.CurrentCamera
                local camPos = cam.CFrame.Position
                local lookCFrame = CFrame.new(camPos, part.Position)
                cam.CFrame = lookCFrame
            end
        end
    end)
end

local function stopStickyAim()
    if stickyRc then stickyRc:Disconnect() stickyRc = nil end
end

aimBtn.MouseButton1Click:Connect(function()
    state.aimAssist = not state.aimAssist
    aimBtn.Text = "Aimbot/Aim Assist: "..(state.aimAssist and "ON" or "OFF")
    aimBtn.BackgroundColor3 = state.aimAssist and Color3.fromRGB(70,70,70) or Color3.fromRGB(25,25,25)
    -- when turning off, also stop sticky aim
    if not state.aimAssist then
        state.stickyAim = false
        stickyBtn.Text = "Sticky Aim: OFF"
        stopStickyAim()
    end
end)

stickyBtn.MouseButton1Click:Connect(function()
    if not state.aimAssist then
        -- enable aim assist automatically when sticky toggled
        state.aimAssist = true
        aimBtn.Text = "Aimbot/Aim Assist: ON"
        aimBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    end
    state.stickyAim = not state.stickyAim
    stickyBtn.Text = "Sticky Aim: "..(state.stickyAim and "ON" or "OFF")
    stickyBtn.BackgroundColor3 = state.stickyAim and Color3.fromRGB(70,70,70) or Color3.fromRGB(25,25,25)
    mobileStickyBtn.Text = state.stickyAim and "Sticky ON" or "Sticky OFF"
    if state.stickyAim then startStickyAim() else stopStickyAim() end
end)

stickPartBtn.MouseButton1Click:Connect(function()
    state.stickyAimPart = (state.stickyAimPart == "Head") and "Body" or "Head"
    stickPartBtn.Text = "Sticky Target: "..state.stickyAimPart
end)

stickyTeamBtn.MouseButton1Click:Connect(function()
    state.stickyTeamCheck = not state.stickyTeamCheck
    stickyTeamBtn.Text = "Team Check: "..(state.stickyTeamCheck and "ON" or "OFF")
    stickyTeamBtn.BackgroundColor3 = state.stickyTeamCheck and Color3.fromRGB(70,70,70) or Color3.fromRGB(25,25,25)
end)

removeStickBtn.MouseButton1Click:Connect(function()
    state.stickyAim = false
    stickyBtn.Text = "Sticky Aim: OFF"
    stickyBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)
    stopStickyAim()
end)

mobileStickyBtn.MouseButton1Click:Connect(function()
    -- toggles sticky aim quickly
    if not state.aimAssist then
        state.aimAssist = true
        aimBtn.Text = "Aimbot/Aim Assist: ON"
        aimBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    end
    state.stickyAim = not state.stickyAim
    stickyBtn.Text = "Sticky Aim: "..(state.stickyAim and "ON" or "OFF")
    mobileStickyBtn.Text = state.stickyAim and "Sticky ON" or "Sticky OFF"
    if state.stickyAim then startStickyAim() else stopStickyAim() end
end)

-- Hitbox size controls (1-10) and transparency (0-100) in COMBAT
local hbSizeBox = c("TextBox", pageCombat, {Size = UDim2.new(0,170,0,30), Position = UDim2.new(0,12,0,212), BackgroundColor3 = Color3.fromRGB(35,35,35), Text = tostring(state.hitboxSize), PlaceholderText = "Hitbox Size (1-10)"})
c("UICorner", hbSizeBox, {CornerRadius = UDim.new(0,5)})
local hbTransBox = c("TextBox", pageCombat, {Size = UDim2.new(0,170,0,30), Position = UDim2.new(0,192,0,212), BackgroundColor3 = Color3.fromRGB(35,35,35), Text = tostring(state.hitboxTransparency), PlaceholderText = "Transparency % (0-100)"})
c("UICorner", hbTransBox, {CornerRadius = UDim.new(0,5)})

hbSizeBox.FocusLost:Connect(function()
    local v = tonumber(hbSizeBox.Text)
    if v then state.hitboxSize = math.clamp(v,1,10); hbSizeBox.Text = tostring(state.hitboxSize) end
end)
hbTransBox.FocusLost:Connect(function()
    local v = tonumber(hbTransBox.Text)
    if v then state.hitboxTransparency = math.clamp(v,0,100); hbTransBox.Text = tostring(state.hitboxTransparency) end
end)

-- Hitbox expander toggle (moved into COMBAT, shows arrow indicator in UI when active)
local hbToggle = btn(pageCombat, "Hitbox Expander: OFF", 252, Color3.fromRGB(25,25,25))
hbToggle.MouseButton1Click:Connect(function()
    state.hitboxEnabled = not state.hitboxEnabled
    hbToggle.Text = "Hitbox Expander: "..(state.hitboxEnabled and "ON" or "OFF")
    hbToggle.BackgroundColor3 = state.hitboxEnabled and Color3.fromRGB(70,70,70) or Color3.fromRGB(25,25,25)
end)

-- Apply hitbox effects every render step when enabled
RS.RenderStepped:Connect(function()
    if state.hitboxEnabled then
        for _, pl in ipairs(P:GetPlayers()) do
            if pl ~= p and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = pl.Character.HumanoidRootPart
                hrp.Size = Vector3.new(state.hitboxSize, state.hitboxSize, state.hitboxSize)
                hrp.Transparency = math.clamp(state.hitboxTransparency/100,0,1)
                hrp.CanCollide = false
                if not hrp:FindFirstChild("JH_HitboxBox") then
                    local box = Instance.new("SelectionBox")
                    box.Name = "JH_HitboxBox"
                    box.Adornee = hrp
                    box.Parent = hrp
                    box.Color3 = Color3.new(1,1,1)
                    box.LineThickness = 0.03
                end
            end
        end
    else
        for _, pl in ipairs(P:GetPlayers()) do
            if pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = pl.Character.HumanoidRootPart
                hrp.Size = Vector3.new(2,2,1)
                hrp.Transparency = 0
                local box = hrp:FindFirstChild("JH_HitboxBox")
                if box then box:Destroy() end
            end
        end
    end
end)

-- ESP code (simplified)
local espContainer = c("Frame", g, {Name = "ESPContainer", Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1})
local espElements = {}

local function makeESPFor(pl)
    if espElements[pl] then return end
    local arrow = c("TextLabel", espContainer, {Name = "JH_ESPArrow", Size = UDim2.new(0,28,0,28), BackgroundTransparency = 1, Text = "▼", TextColor3 = Color3.fromRGB(255,80,80), TextScaled = true, ZIndex = 201})
    arrow.AnchorPoint = Vector2.new(0.5,0.5)
    local name = c("TextLabel", espContainer, {Name = "JH_ESPName", Size = UDim2.new(0,120,0,18), BackgroundTransparency = 0.4, BackgroundColor3 = Color3.fromRGB(0,0,0), Text = pl.Name, TextColor3 = Color3.new(1,1,1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 201})
    name.AnchorPoint = Vector2.new(0.5,1)
    espElements[pl] = {arrow = arrow, name = name}
end
local function removeESPFor(pl)
    local t = espElements[pl]
    if not t then return end
    if t.arrow and t.arrow.Parent then t.arrow:Destroy() end
    if t.name and t.name.Parent then t.name:Destroy() end
    espElements[pl] = nil
end

local function startESP()
    if espRc then return end
    espRc = RS.RenderStepped:Connect(function()
        if not state.espEnabled then return end
        local cam = workspace.CurrentCamera
        local vs = cam.ViewportSize
        for _, pl in ipairs(P:GetPlayers()) do
            if pl ~= p and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                if not espElements[pl] then makeESPFor(pl) end
                local el = espElements[pl]
                local hrp = pl.Character.HumanoidRootPart
                local rootVp, onScreen = cam:WorldToViewportPoint(hrp.Position)
                local rootPos = Vector2.new(rootVp.X, rootVp.Y)
                -- name
                if state.espNames and onScreen and rootVp.Z > 0 then
                    el.name.Position = UDim2.new(0, rootPos.X, 0, math.clamp(rootPos.Y - 12, 16, vs.Y-16))
                    el.name.Visible = true
                else
                    el.name.Visible = false
                end
                -- arrow
                if state.espArrows then
                    if onScreen and rootVp.Z > 0 then
                        el.arrow.Position = UDim2.new(0, rootPos.X, 0, math.clamp(rootPos.Y + 30, 12, vs.Y-12))
                        el.arrow.Rotation = 180
                        el.arrow.Visible = true
                    else
                        -- offscreen edge
                        local center = Vector2.new(vs.X/2, vs.Y/2)
                        local dir = (rootPos - center)
                        local ang = math.atan2(dir.Y, dir.X)
                        local radiusX = vs.X/2 - 40
                        local radiusY = vs.Y/2 - 60
                        local ex = center.X + math.clamp(math.cos(ang)*radiusX, -radiusX, radiusX)
                        local ey = center.Y + math.clamp(math.sin(ang)*radiusY, -radiusY, radiusY)
                        el.arrow.Position = UDim2.new(0, ex, 0, ey)
                        el.arrow.Rotation = math.deg(ang) + 90
                        el.arrow.Visible = true
                    end
                else
                    el.arrow.Visible = false
                end
            else
                removeESPFor(pl)
            end
        end
    end)
end

-- Toggle ESP
local espBtn = btn(pageCombat, "ESP: OFF", 292, Color3.fromRGB(25,25,25))
espBtn.MouseButton1Click:Connect(function()
    state.espEnabled = not state.espEnabled
    espBtn.Text = "ESP: "..(state.espEnabled and "ON" or "OFF")
    espBtn.BackgroundColor3 = state.espEnabled and Color3.fromRGB(70,70,70) or Color3.fromRGB(25,25,25)
    if state.espEnabled then startESP() else for pl,_ in pairs(espElements) do removeESPFor(pl) end end
end)

-- Ensure mobile buttons do not auto show on rejoin; they only show if "Show Mobile Buttons" toggled by user
mobileCarBtn.Visible = false
mobileDriftBtn.Visible = false
mobileStickyBtn.Visible = false

-- Loading sequence
task.spawn(function()
    for i=1,100 do
        barFill.Size = UDim2.new(i/100,0,1,0)
        task.wait(0.01)
    end
    loadBg:Destroy()
    main.Visible = true
end)

-- Clean up controllers on character removal
p.CharacterRemoving:Connect(function()
    -- cleanup car controllers
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj:FindFirstChild("JH_CarBV") then
            local bv = obj:FindFirstChild("JH_CarBV") if bv then bv:Destroy() end
        end
    end
    stopStickyAim()
    stopCarControl()
    stopFly()
end)

-- Save: this script focuses on client-side features; "hits" are not performed by the client here.
-- Sticky aim aligns the camera to nearest visible target's specified part (Head/Body) using a wall check.

print("JonaHubNew loaded")
