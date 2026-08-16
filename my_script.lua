local P, RS, U = game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService")
local p, uj, he, fly, vFly = P.LocalPlayer, true, false, false, false
local nc, bv, bg, rc, vBv, vBg, vRc

-- Feature flags and defaults
_G.HeadSize, _G.HitboxTransparency, _G.Disabled = 2, 100, false
_G.TeamCheckEnabled = true
_G.HighlightCheckEnabled = true
_G.NameESPEnabled = true
_G.TracerEnabled = true
_G.ArrowEnabled = true

-- Storage for per-player ESP objects
local espData = {}
local assignedTeamColors = {}
local teamColorPool = {
    Color3.fromRGB(0, 200, 0),    -- green for possible teams
    Color3.fromRGB(255, 50, 50),  -- red
    Color3.fromRGB(50, 100, 255), -- blue
    Color3.fromRGB(255, 165, 0),  -- orange
    Color3.fromRGB(160, 32, 240), -- purple
    Color3.fromRGB(255, 255, 0),  -- yellow
    Color3.fromRGB(0, 255, 255)   -- cyan
}

local function getAssignedTeamColor(teamName)
    if not teamName or teamName == "" then return Color3.fromRGB(255,255,255) end
    if not assignedTeamColors[teamName] then
        local count = 0
        for _ in pairs(assignedTeamColors) do count = count + 1 end
        assignedTeamColors[teamName] = teamColorPool[(count % #teamColorPool) + 1]
    end
    return assignedTeamColors[teamName]
end

-- Smart team detection
local function detectTeam(player)
    -- Prefer Team property if teams are set up
    if typeof(player) ~= "userdata" then return nil end
    if player.Team and player.Team.Name ~= "" then
        return player.Team.Name
    end
    -- fallback to TeamColor if present
    if player.TeamColor and player.TeamColor ~= BrickColor.new("Institutional white") then
        return tostring(player.TeamColor) -- convert to string to use as key
    end
    -- no team information: return nil
    return nil
end

local function isTeammate(target)
    if not _G.TeamCheckEnabled then return false end
    if not p or not target then return false end
    if p.Team and target.Team then
        return p.Team == target.Team
    end
    local t1 = detectTeam(p)
    local t2 = detectTeam(target)
    if t1 and t2 then
        return t1 == t2
    end
    return false
end

-- Utility to safely destroy items
local function safeDestroy(obj)
    if obj and obj.Parent then
        obj:Destroy()
    end
end

-- Create/Update ESP for a single player
local function updatePlayerESP(player)
    if not player or player == p then return end
    local ch = player.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Head")
    if not hrp then return end

    espData[player] = espData[player] or {}
    local data = espData[player]

    -- Determine team color
    local teamName = detectTeam(player)
    local color = Color3.fromRGB(255,255,255)
    if _G.HighlightCheckEnabled and teamName then
        color = getAssignedTeamColor(teamName)
    end
    if isTeammate(player) then
        color = Color3.fromRGB(0, 255, 0) -- green for local team
    end

    -- Highlight
    if _G.HighlightCheckEnabled then
        if not data.highlight then
            local h = Instance.new("Highlight")
            h.Name = "JH_Highlight"
            h.Adornee = ch
            h.FillTransparency = 0.5
            h.OutlineTransparency = 0.7
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = ch
            data.highlight = h
        end
        if data.highlight then
            data.highlight.FillColor = color
            data.highlight.OutlineColor = Color3.fromRGB(30,30,30)
        end
    else
        if data.highlight then safeDestroy(data.highlight) data.highlight = nil end
    end

    -- Billboard GUI for name and arrow
    if _G.NameESPEnabled or _G.ArrowEnabled then
        if not data.billboard or not data.billboard.Parent then
            local bgui = Instance.new("BillboardGui")
            bgui.Name = "JH_Billboard"
            bgui.Adornee = hrp
            bgui.ExtentsOffset = Vector3.new(0, 2.5, 0)
            bgui.AlwaysOnTop = true
            bgui.Size = UDim2.new(0, 120, 0, 50)
            bgui.Parent = ch

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "JH_Name"
            nameLabel.BackgroundTransparency = 1
            nameLabel.Size = UDim2.new(1, 0, 0, 20)
            nameLabel.Position = UDim2.new(0, 0, 0, 0)
            nameLabel.Font = Enum.Font.SourceSansBold
            nameLabel.TextSize = 18
            nameLabel.TextStrokeTransparency = 0.7
            nameLabel.Parent = bgui

            local arrowLabel = Instance.new("TextLabel")
            arrowLabel.Name = "JH_Arrow"
            arrowLabel.BackgroundTransparency = 1
            arrowLabel.Size = UDim2.new(1, 0, 0, 26)
            arrowLabel.Position = UDim2.new(0, 0, 0, 20)
            arrowLabel.Font = Enum.Font.SourceSansBold
            arrowLabel.TextSize = 20
            arrowLabel.Text = "▲"
            arrowLabel.TextTransparency = 0.25
            arrowLabel.TextStrokeTransparency = 0.7
            arrowLabel.Parent = bgui

            data.billboard = bgui
            data.nameLabel = nameLabel
            data.arrowLabel = arrowLabel
        end

        -- Update text and color
        if data.nameLabel and _G.NameESPEnabled then
            data.nameLabel.Text = player.Name
            data.nameLabel.TextColor3 = color
            data.nameLabel.Visible = true
        elseif data.nameLabel then
            data.nameLabel.Visible = false
        end

        if data.arrowLabel and _G.ArrowEnabled then
            data.arrowLabel.Visible = true
            data.arrowLabel.TextColor3 = color
        elseif data.arrowLabel then
            data.arrowLabel.Visible = false
        end

    else
        if data.billboard then safeDestroy(data.billboard) data.billboard = nil data.nameLabel = nil data.arrowLabel = nil end
    end

    -- Tracer using Drawing if available
    if _G.TracerEnabled then
        if not data.tracer then
            local success, Drawing = pcall(function() return Drawing end)
            if success and Drawing then
                local line = Drawing.new("Line")
                line.Transparency = 1
                line.Color = color
                line.Thickness = 1
                data.tracer = line
                data.tracerIsDrawing = true
            else
                data.tracer = nil
            end
        end
    else
        if data.tracer then
            pcall(function() data.tracer:Remove() end)
            data.tracer = nil
        end
    end
end

local function clearESPForPlayer(player)
    local data = espData[player]
    if not data then return end
    if data.highlight then safeDestroy(data.highlight) data.highlight = nil end
    if data.billboard then safeDestroy(data.billboard) data.billboard = nil end
    if data.tracer then pcall(function() data.tracer:Remove() end) data.tracer = nil end
    espData[player] = nil
end

-- Update loop: updates visuals per frame for smooth arrow/tracer and size scaling
RS.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if not cam then return end

    for _, player in ipairs(P:GetPlayers()) do
        if player ~= p and player.Character and player.Character.Parent then
            updatePlayerESP(player)
            local data = espData[player]
            if not data then continue end
            local hrp = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Head")
            if not hrp then continue end

            -- Scale name/arrow size based on distance
            local dist = (cam.CFrame.Position - hrp.Position).Magnitude
            local scale = math.clamp(120 * (1 / math.max(dist, 1)), 30, 160)
            if data.billboard then
                local sizeY = math.clamp(40 * (50 / math.max(dist,50)), 18, 50)
                data.billboard.Size = UDim2.new(0, math.clamp(math.floor(scale), 60, 180), 0, sizeY)
                if data.nameLabel then data.nameLabel.TextSize = math.clamp(math.floor(18 * (50 / math.max(dist,50))), 12, 20) end
                if data.arrowLabel then data.arrowLabel.TextSize = math.clamp(math.floor(18 * (50 / math.max(dist,50))), 12, 22) end
            end

            -- Arrow rotation: point towards player's horizontal direction relative to camera
            if data.arrowLabel and data.arrowLabel.Visible then
                local dir = (hrp.Position - cam.CFrame.Position)
                dir = Vector3.new(dir.X, 0, dir.Z)
                local forward = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
                if dir.Magnitude > 0 and forward.Magnitude > 0 then
                    local angle = math.atan2(dir.X, dir.Z) - math.atan2(forward.X, forward.Z)
                    data.arrowLabel.Rotation = math.deg(angle)
                end
            end

            -- Update tracer (Drawing)
            if data.tracer and _G.TracerEnabled then
                local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                local centerX = cam.ViewportSize.X/2
                local bottomY = cam.ViewportSize.Y - 50
                local x, y = screenPos.X, screenPos.Y
                data.tracer.Color = isTeammate(player) and Color3.fromRGB(0,255,0) or getAssignedTeamColor(detectTeam(player))
                if onScreen then
                    data.tracer.From = Vector2.new(centerX, bottomY)
                    data.tracer.To = Vector2.new(x, y)
                    data.tracer.Visible = true
                else
                    -- If offscreen, hide tracer or draw to screen edge (hide for simplicity)
                    data.tracer.Visible = false
                end
            end

            -- Ensure highlight color stays updated for team changes
            if data.highlight then
                local color = Color3.fromRGB(255,255,255)
                if _G.HighlightCheckEnabled and detectTeam(player) then
                    color = getAssignedTeamColor(detectTeam(player))
                end
                if isTeammate(player) then color = Color3.fromRGB(0,255,0) end
                data.highlight.FillColor = color
            end

        else
            -- clear if player removed or no character
            if espData[player] then clearESPForPlayer(player) end
        end
    end
end)

-- Hook up player events
P.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function() task.wait(0.2) updatePlayerESP(pl) end)
    pl.AncestryChanged:Connect(function() if not pl:IsDescendantOf(P) then clearESPForPlayer(pl) end end)
    pl:GetPropertyChangedSignal("Team"):Connect(function()
        assignedTeamColors = {}
    end)
end)
P.PlayerRemoving:Connect(function(pl) clearESPForPlayer(pl) end)

p:GetPropertyChangedSignal("Team"):Connect(function()
    assignedTeamColors = {}
    -- refresh colors
    for pl,_ in pairs(espData) do updatePlayerESP(pl) end
end)

-- Remove previous Hitbox/UI code and insert the new UI + Hitbox Expander with loading animation

-- Fixed Hitbox Expander with dynamic percentage transparency (0 to 100)
RS.RenderStepped:Connect(function()
    if _G.Disabled then
        for _, v in ipairs(P:GetPlayers()) do
            if v ~= p and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = v.Character.HumanoidRootPart
                hrp.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize)
                hrp.Transparency = math.clamp(_G.HitboxTransparency / 100, 0, 1)
                hrp.CanCollide = false
                if not hrp:FindFirstChild("HitboxVisual") then
                    local box = Instance.new("SelectionBox", hrp)
                    box.Name = "HitboxVisual"
                    box.Color3 = Color3.fromRGB(255, 255, 255)
                    box.LineThickness = 0.03
                    box.Adornee = hrp
                end
            end
        end
    else
        for _, v in ipairs(P:GetPlayers()) do
            if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = v.Character.HumanoidRootPart
                local box = hrp:FindFirstChild("HitboxVisual")
                if box then box:Destroy() end
            end
        end
    end
end)

local function c(cl, pr, prm)
    local i = Instance.new(cl)
    for k, v in pairs(prm or {}) do i[k] = v end
    i.Parent = pr return i
end

-- Screen GUI Holder
local g = c("ScreenGui", p:WaitForChild("PlayerGui"), {Name = "JonaHubNew", ResetOnSpawn = false})

-- Loading Screen Setup
local loadBg = c("Frame", g, {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(10, 10, 10), ZIndex = 100})

local loadTitle = c("TextLabel", loadBg, {Size = UDim2.new(0, 300, 0, 50), Position = UDim2.new(0.5, -150, 0.42, -40), BackgroundTransparency = 1, Text = "Jona hub", TextColor3 = Color3.new(1, 1, 1), TextSize = 28, Font = Enum.Font.SourceSansBold, ZIndex = 101})
local loadSub = c("TextLabel", loadBg, {Size = UDim2.new(0, 300, 0, 30), Position = UDim2.new(0.5, -150, 0.42, 0), BackgroundTransparency = 1, Text = "assets", TextColor3 = Color3.fromRGB(150, 150, 150), TextSize = 14, Font = Enum.Font.SourceSans, ZIndex = 101})

local barBg = c("Frame", loadBg, {Size = UDim2.new(0, 300, 0, 6), Position = UDim2.new(0.5, -150, 0.52, 0), BackgroundColor3 = Color3.fromRGB(30, 30, 30), ZIndex = 101})
c("UICorner", barBg, {CornerRadius = UDim.new(1, 0)})

local barFill = c("Frame", barBg, {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), ZIndex = 102})
c("UICorner", barFill, {CornerRadius = UDim.new(1, 0)})

-- Main UI Elements (Created hidden initially)
local f = c("Frame", g, {Size = UDim2.new(0, 520, 0, 320), Position = UDim2.new(0.5, -260, 0.5, -160), BackgroundColor3 = Color3.fromRGB(15, 15, 15), Active = true, Draggable = true, Visible = false})
c("UICorner", f, {CornerRadius = UDim.new(0, 8)})

local rb = c("TextButton", g, {Size = UDim2.new(0, 45, 0, 45), Position = UDim2.new(0.05, 0, 0.5, -22), BackgroundColor3 = Color3.fromRGB(25, 25, 25), TextColor3 = Color3.new(1, 1, 1), Text = "JH", TextScaled = true, Visible = false, Active = true, Draggable = true})
c("UICorner", rb, {CornerRadius = UDim.new(1, 0)})

local tb = c("Frame", f, {Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 1})
c("TextLabel", tb, {Size = UDim2.new(0, 150, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Text = "Jona hub", TextColor3 = Color3.new(1, 1, 1), TextXAlignment = 0, TextSize = 18, Font = Enum.Font.SourceSansBold})

local mb = c("TextButton", tb, {Size = UDim2.new(0, 25, 0, 25), Position = UDim2.new(1, -55, 0, 5), BackgroundTransparency = 1, Text = "-", TextColor3 = Color3.new(1, 1, 1), TextSize = 16})
local cb = c("TextButton", tb, {Size = UDim2.new(0, 25, 0, 25), Position = UDim2.new(1, -28, 0, 5), BackgroundTransparency = 1, Text = "X", TextColor3 = Color3.fromRGB(200, 200, 200), TextSize = 16})

cb.MouseButton1Click:Connect(function() f.Visible, rb.Visible = false, true end)
mb.MouseButton1Click:Connect(function() f.Visible, rb.Visible = false, true end)
rb.MouseButton1Click:Connect(function() f.Visible, rb.Visible = true, false end)

local sb = c("Frame", f, {Size = UDim2.new(0, 110, 1, -45), Position = UDim2.new(0, 8, 0, 40), BackgroundColor3 = Color3.fromRGB(22, 22, 22)})
c("UICorner", sb, {CornerRadius = UDim.new(0, 6)})
local ca = c("Frame", f, {Size = UDim2.new(1, -134, 1, -45), Position = UDim2.new(0, 124, 0, 40), BackgroundColor3 = Color3.fromRGB(22, 22, 22)})
c("UICorner", ca, {CornerRadius = UDim.new(0, 6)})

local t1 = c("TextButton", sb, {Size = UDim2.new(1, -10, 0, 32), Position = UDim2.new(0, 5, 0, 5), BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.new(1, 1, 1), Text = "MAIN", Font = Enum.Font.SourceSansBold, TextSize = 14})
c("UICorner", t1, {CornerRadius = UDim.new(0, 4)})
local t2 = c("TextButton", sb, {Size = UDim2.new(1, -10, 0, 32), Position = UDim2.new(0, 5, 0, 42), BackgroundColor3 = Color3.fromRGB(28, 28, 28), TextColor3 = Color3.fromRGB(180, 180, 180), Text = "COMBAT", Font = Enum.Font.SourceSansBold, TextSize = 14})
c("UICorner", t2, {CornerRadius = UDim.new(0, 4)})
local t3 = c("TextButton", sb, {Size = UDim2.new(1, -10, 0, 32), Position = UDim2.new(0, 5, 0, 79), BackgroundColor3 = Color3.fromRGB(28, 28, 28), TextColor3 = Color3.fromRGB(180, 180, 180), Text = "EXTRA", Font = Enum.Font.SourceSansBold, TextSize = 14})
c("UICorner", t3, {CornerRadius = UDim.new(0, 4)})

local p1 = c("ScrollingFrame", ca, {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = true, CanvasSize = UDim2.new(0, 0, 0, 210), ScrollBarThickness = 4})
local p2 = c("Frame", ca, {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false})
local p3 = c("ScrollingFrame", ca, {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, CanvasSize = UDim2.new(0, 0, 0, 280), ScrollBarThickness = 4})

local function sw(a, b, c)
    p1.Visible, p2.Visible, p3.Visible = a, b, c
    t1.BackgroundColor3, t1.TextColor3 = a and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(28, 28, 28), a and Color3.new(1, 1, 1) or Color3.fromRGB(180, 180, 180)
    t2.BackgroundColor3, t2.TextColor3 = b and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(28, 28, 28), b and Color3.new(1, 1, 1) or Color3.fromRGB(180, 180, 180)
    t3.BackgroundColor3, t3.TextColor3 = c and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(28, 28, 28), c and Color3.new(1, 1, 1) or Color3.fromRGB(180, 180, 180)
end
t1.MouseButton1Click:Connect(function() sw(true, false, false) end)
t2.MouseButton1Click:Connect(function() sw(false, true, false) end)
t3.MouseButton1Click:Connect(function() sw(false, false, true) end)

local function btn(pr, t, y, col)
    local b = c("TextButton", pr, {Size = UDim2.new(0, 350, 0, 30), Position = UDim2.new(0, 12, 0, y), BackgroundColor3 = col or Color3.fromRGB(35, 35, 35), TextColor3 = Color3.new(1, 1, 1), Text = t, Font = Enum.Font.SourceSansSemibold, TextSize = 14})
    c("UICorner", b, {CornerRadius = UDim.new(0, 5)}) return b
end

local ws = c("TextBox", p1, {Size = UDim2.new(0, 170, 0, 30), Position = UDim2.new(0, 12, 0, 10), BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.new(1, 1, 1), PlaceholderText = "WalkSpeed", Text = "", TextSize = 14})
c("UICorner", ws, {CornerRadius = UDim.new(0, 5)})
local jp = c("TextBox", p1, {Size = UDim2.new(0, 170, 0, 30), Position = UDim2.new(0, 192, 0, 10), BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.new(1, 1, 1), PlaceholderText = "JumpPower", Text = "", TextSize = 14})
c("UICorner", jp, {CornerRadius = UDim.new(0, 5)})

btn(p1, "Apply Speed & Jump", 48, Color3.fromRGB(50, 50, 50)).MouseButton1Click:Connect(function()
    local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    if h then
        if tonumber(ws.Text) then h.WalkSpeed = tonumber(ws.Text) end
        if tonumber(jp.Text) then h.JumpPower = tonumber(jp.Text) end
    end
end)

local ij = btn(p1, "Infinite Jump: ON", 86, Color3.fromRGB(35, 35, 35))
ij.MouseButton1Click:Connect(function() uj = not uj ij.Text = "Infinite Jump: "..(uj and "ON" or "OFF") end)

local flB = btn(p1, "Fly: OFF", 124, Color3.fromRGB(25, 25, 25))
flB.Size = UDim2.new(0, 240, 0, 30)
local fs = c("TextBox", p1, {Size = UDim2.new(0, 100, 0, 30), Position = UDim2.new(0, 262, 0, 124), BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.new(1, 1, 1), PlaceholderText = "FlySpeed", Text = "50", TextSize = 14})
c("UICorner", fs, {CornerRadius = UDim.new(0, 5)})

local function sFly()
    fly = false
    if p.Character and p.Character:FindFirstChildOfClass("Humanoid") then p.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false end
    if bv then bv:Destroy() bv = nil end if bg then bg:Destroy() bg = nil end if rc then rc:Disconnect() rc = nil end
    flB.Text, flB.BackgroundColor3 = "Fly: OFF", Color3.fromRGB(25, 25, 25)
end

flB.MouseButton1Click:Connect(function()
    if fly then sFly() else
        local ch = p.Character if not ch or not ch:FindFirstChild("HumanoidRootPart") then return end
        fly = true ch.Humanoid.PlatformStand = true
        bg = c("BodyGyro", ch.HumanoidRootPart, {P = 9e4, maxTorque = Vector3.new(9e9, 9e9, 9e9), cframe = ch.HumanoidRootPart.CFrame})
        bv = c("BodyVelocity", ch.HumanoidRootPart, {velocity = Vector3.new(0, 0.1, 0), maxForce = Vector3.new(9e9, 9e9, 9e9)})
        flB.Text, flB.BackgroundColor3 = "Fly: ON", Color3.fromRGB(70, 70, 70)
        rc = RS.RenderStepped:Connect(function()
            if not fly then return end
            bg.cframe = workspace.CurrentCamera.CFrame
            local s = tonumber(fs.Text) or 50
            local v = ch.Humanoid.MoveDirection * s
            if U:IsKeyDown(Enum.KeyCode.Space) or ch.Humanoid.Jump then v = v + Vector3.new(0, s, 0) elseif U:IsKeyDown(Enum.KeyCode.LeftShift) then v = v + Vector3.new(0, -s, 0) end
            bv.velocity = v
        end)
    end
end)

local mobUp, mobDown = false, false
local upBtn = c("TextButton", g, {Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(1, -70, 0.5, -60), BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.new(1, 1, 1), Text = "^", TextSize = 20, Visible = false, ZIndex = 10})
c("UICorner", upBtn, {CornerRadius = UDim.new(0, 8)})
local downBtn = c("TextButton", g, {Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(1, -70, 0.5, 10), BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.new(1, 1, 1), Text = "v", TextSize = 20, Visible = false, ZIndex = 10})
c("UICorner", downBtn, {CornerRadius = UDim.new(0, 8)})

upBtn.MouseButton1Down:Connect(function() mobUp = true end)
upBtn.MouseButton1Up:Connect(function() mobUp = false end)
downBtn.MouseButton1Down:Connect(function() mobDown = true end)
downBtn.MouseButton1Up:Connect(function() mobDown = false end)

local vFlB = btn(p1, "Vehicle Fly: OFF", 162, Color3.fromRGB(25, 25, 25))
vFlB.Size = UDim2.new(0, 240, 0, 30)
local vfs = c("TextBox", p1, {Size = UDim2.new(0, 100, 0, 30), Position = UDim2.new(0, 262, 0, 162), BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.new(1, 1, 1), PlaceholderText = "VehFlySpeed", Text = "50", TextSize = 14})
c("UICorner", vfs, {CornerRadius = UDim.new(0, 5)})

local function sVFly()
    vFly = false
    mobUp, mobDown = false, false
    upBtn.Visible, downBtn.Visible = false, false
    if vBv then vBv:Destroy() vBv = nil end if vBg then vBg:Destroy() vBg = nil end if vRc then vRc:Disconnect() vRc = nil end
    vFlB.Text, vFlB.BackgroundColor3 = "Vehicle Fly: OFF", Color3.fromRGB(25, 25, 25)
end

vFlB.MouseButton1Click:Connect(function()
    if vFly then sVFly() else
        local ch = p.Character
        local seat = ch and ch:FindFirstChildOfClass("Humanoid") and ch.Humanoid.SeatPart
        if not seat then return end
        local vehicleRoot = seat.AssemblyRootPart or seat.Parent:FindFirstChild("HumanoidRootPart") or seat
        vFly = true
        if U.TouchEnabled then
            upBtn.Visible, downBtn.Visible = true, true
        end
        vBg = c("BodyGyro", vehicleRoot, {P = 9e4, maxTorque = Vector3.new(9e9, 9e9, 9e9), cframe = vehicleRoot.CFrame})
        vBv = c("BodyVelocity", vehicleRoot, {velocity = Vector3.new(0, 0.1, 0), maxForce = Vector3.new(9e9, 9e9, 9e9)})
        vFlB.Text, vFlB.BackgroundColor3 = "Vehicle Fly: ON", Color3.fromRGB(70, 70, 70)
        vRc = RS.RenderStepped:Connect(function()
            if not vFly or not seat.Parent then sVFly() return end
            local cam = workspace.CurrentCamera
            vBg.cframe = cam.CFrame
            local s = tonumber(vfs.Text) or 50
            local moveVector = Vector3.new()
            local throttle = seat.Throttle
            local steer = seat.Steer
            if U:IsKeyDown(Enum.KeyCode.W) or throttle > 0 then moveVector = moveVector + cam.CFrame.LookVector end
            if U:IsKeyDown(Enum.KeyCode.S) or throttle < 0 then moveVector = moveVector - cam.CFrame.LookVector end
            if U:IsKeyDown(Enum.KeyCode.A) or steer < 0 then moveVector = moveVector - cam.CFrame.RightVector end
            if U:IsKeyDown(Enum.KeyCode.D) or steer > 0 then moveVector = moveVector + cam.CFrame.RightVector end
            if moveVector.Magnitude > 0 then
                moveVector = moveVector.Unit * s
            end
            local upDown = 0
            if U:IsKeyDown(Enum.KeyCode.Space) or (ch and ch:FindFirstChildOfClass("Humanoid") and ch.Humanoid.Jump) or mobUp then
                upDown = s
            elseif U:IsKeyDown(Enum.KeyCode.LeftShift) or mobDown then
                upDown = -s
            end
            vBv.velocity = moveVector + Vector3.new(0, upDown, 0)
        end)
    end
end)

-- EXTRA TAB FEATURES
local fovBox = c("TextBox", p3, {Size = UDim2.new(0, 350, 0, 30), Position = UDim2.new(0, 12, 0, 15), BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.new(1, 1, 1), PlaceholderText = "FOV (10-120)", Text = "", TextSize = 14})
c("UICorner", fovBox, {CornerRadius = UDim.new(0, 5)})

fovBox:GetPropertyChangedSignal("Text"):Connect(function()
    local val = tonumber(fovBox.Text)
    if val then
        workspace.CurrentCamera.FieldOfView = math.clamp(val, 10, 120)
    end
end)

local fbEnabled = false
local lighting = game:GetService("Lighting")
local originalLighting = {
    Brightness = lighting.Brightness,
    ClockTime = lighting.ClockTime,
    GlobalShadows = lighting.GlobalShadows,
    OutdoorAmbient = lighting.OutdoorAmbient,
    Ambient = lighting.Ambient
}
local fbBtn = c("TextButton", p3, {Size = UDim2.new(0, 170, 0, 30), Position = UDim2.new(0, 12, 0, 55), BackgroundColor3 = Color3.fromRGB(25, 25, 25), TextColor3 = Color3.new(1, 1, 1), Text = "Fullbright: OFF", Font = Enum.Font.SourceSansSemibold, TextSize = 14})
c("UICorner", fbBtn, {CornerRadius = UDim.new(0, 5)})

local fbConnection
fbBtn.MouseButton1Click:Connect(function()
    fbEnabled = not fbEnabled
    fbBtn.Text = "Fullbright: "..(fbEnabled and "ON" or "OFF")
    fbBtn.BackgroundColor3 = fbEnabled and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(25, 25, 25)
    if fbEnabled then
        originalLighting.Brightness = lighting.Brightness
        originalLighting.ClockTime = lighting.ClockTime
        originalLighting.GlobalShadows = lighting.GlobalShadows
        originalLighting.OutdoorAmbient = lighting.OutdoorAmbient
        originalLighting.Ambient = lighting.Ambient
        lighting.GlobalShadows = false
        lighting.Brightness = 2
        lighting.ClockTime = 14
        lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        lighting.Ambient = Color3.new(1, 1, 1)
        fbConnection = lighting.Changed:Connect(function(property)
            if fbEnabled then
                if property == "GlobalShadows" and lighting.GlobalShadows then lighting.GlobalShadows = false end
                if property == "Brightness" and lighting.Brightness ~= 2 then lighting.Brightness = 2 end
            end
        end)
    else
        if fbConnection then fbConnection:Disconnect() fbConnection = nil end
        lighting.GlobalShadows = originalLighting.GlobalShadows
        lighting.Brightness = originalLighting.Brightness
        lighting.ClockTime = originalLighting.ClockTime
        lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        lighting.Ambient = originalLighting.Ambient
    end
end)

local clickTpEnabled = false
local clickTpBtn = c("TextButton", p3, {Size = UDim2.new(0, 170, 0, 30), Position = UDim2.new(0, 192, 0, 55), BackgroundColor3 = Color3.fromRGB(25, 25, 25), TextColor3 = Color3.new(1, 1, 1), Text = "Click TP: OFF", Font = Enum.Font.SourceSansSemibold, TextSize = 14})
c("UICorner", clickTpBtn, {CornerRadius = UDim.new(0, 5)})

clickTpBtn.MouseButton1Click:Connect(function()
    clickTpEnabled = not clickTpEnabled
    clickTpBtn.Text = "Click TP: "..(clickTpEnabled and "ON" or "OFF")
    clickTpBtn.BackgroundColor3 = clickTpEnabled and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(25, 25, 25)
end)

local mouse = p:GetMouse()
local function performClickTp(pos)
    if clickTpEnabled and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = p.Character.HumanoidRootPart
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end

mouse.Button1Down:Connect(function()
    if clickTpEnabled and mouse.Hit then
        performClickTp(mouse.Hit.Position)
    end
end)

U.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if clickTpEnabled and input.UserInputType == Enum.UserInputType.Touch then
        local cam = workspace.CurrentCamera
        local touchPos = input.Position
        local unitRay = cam:ViewportPointToRay(touchPos.X, touchPos.Y)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {p.Character}
        local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
        if result then
            performClickTp(result.Position)
        end
    end
end)

-- Teleport to Player Dropdown Section
local tpDropdownOpen = false
local tpDropBtn = c("TextButton", p3, {Size = UDim2.new(0, 350, 0, 30), Position = UDim2.new(0, 12, 0, 95), BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.new(1, 1, 1), Text = "Teleport   â¼", Font = Enum.Font.SourceSansSemibold, TextSize = 14})
c("UICorner", tpDropBtn, {CornerRadius = UDim.new(0, 5)})

local tpListFrame = c("ScrollingFrame", p3, {Size = UDim2.new(0, 350, 0, 120), Position = UDim2.new(0, 12, 0, 130), BackgroundColor3 = Color3.fromRGB(20, 20, 20), BorderColor3 = Color3.fromRGB(40, 40, 40), Visible = false, CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 4})
c("UICorner", tpListFrame, {CornerRadius = UDim.new(0, 5)})

local function updateTpPlayerList()
    for _, child in ipairs(tpListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local players = P:GetPlayers()
    local yPos = 2
    for _, targetPlayer in ipairs(players) do
        if targetPlayer ~= p then
            local pBtn = c("TextButton", tpListFrame, {Size = UDim2.new(1, -10, 0, 28), Position = UDim2.new(0, 5, 0, yPos), BackgroundColor3 = Color3.fromRGB(30, 30, 30), TextColor3 = Color3.new(1, 1, 1), Text = targetPlayer.Name, Font = Enum.Font.SourceSans, TextSize = 13})
            c("UICorner", pBtn, {CornerRadius = UDim.new(0, 4)})
            pBtn.MouseButton1Click:Connect(function()
                if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    p.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                end
            end)
            yPos = yPos + 32
        end
    end
    tpListFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

tpDropBtn.MouseButton1Click:Connect(function()
    tpDropdownOpen = not tpDropdownOpen
    tpListFrame.Visible = tpDropdownOpen
    tpDropBtn.Text = "Teleport   "..(tpDropdownOpen and "â²" or "â¼")
    if tpDropdownOpen then
        updateTpPlayerList()
    end
end)

P.PlayerAdded:Connect(function() if tpDropdownOpen then updateTpPlayerList() end end)
P.PlayerRemoving:Connect(function() if tpDropdownOpen then updateTpPlayerList() end end)

-- COMBAT TAB FEATURES
local hbB = btn(p2, "Hitbox Expander: OFF", 15, Color3.fromRGB(25, 25, 25))
hbB.MouseButton1Click:Connect(function()
    _G.Disabled = not _G.Disabled
    hbB.Text = "Hitbox Expander: "..(_G.Disabled and "ON" or "OFF")
    hbB.BackgroundColor3 = _G.Disabled and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(25, 25, 25)
    if not _G.Disabled then
        for _, v in ipairs(P:GetPlayers()) do
            if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local b = v.Character.HumanoidRootPart:FindFirstChild("HitboxVisual")
                if b then b:Destroy() end
                v.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
            end
        end
    end
end)

local hsB = c("TextBox", p2, {Size = UDim2.new(0, 170, 0, 30), Position = UDim2.new(0, 12, 0, 55), BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.new(1, 1, 1), PlaceholderText = "Hitbox Size (1-10)", Text = "2", TextSize = 14})
c("UICorner", hsB, {CornerRadius = UDim.new(0, 5)})
hsB.FocusLost:Connect(function()
    local v = tonumber(hsB.Text)
    if v then _G.HeadSize = math.clamp(v, 1, 10) hsB.Text = tostring(_G.HeadSize) end
end)

local htB = c("TextBox", p2, {Size = UDim2.new(0, 170, 0, 30), Position = UDim2.new(0, 192, 0, 55), BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.new(1, 1, 1), PlaceholderText = "Transparency (0-100%)", Text = "100", TextSize = 14})
c("UICorner", htB, {CornerRadius = UDim.new(0, 5)})
htB.FocusLost:Connect(function()
    local v = tonumber(htB.Text)
    if v then _G.HitboxTransparency = math.clamp(v, 0, 100) htB.Text = tostring(_G.HitboxTransparency) end
end)

local ncB = btn(p2, "Noclip: OFF", 95, Color3.fromRGB(25, 25, 25))
ncB.MouseButton1Click:Connect(function()
    local a = ncB.Text:find("OFF")
    if a then
        nc = RS.Stepped:Connect(function()
            if p.Character then for _, v in ipairs(p.Character:GetDescendants()) do if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end end end
        end)
    elseif nc then nc:Disconnect() nc = nil end
    ncB.Text, ncB.BackgroundColor3 = "Noclip: "..(a and "ON" or "OFF"), a and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(25, 25, 25)
end)

local esB = btn(p2, "ESP: OFF", 135, Color3.fromRGB(25, 25, 25))
esB.Size = UDim2.new(0, 240, 0, 30)

-- Small toggles for ESP features (team check, highlight, name, tracer, arrow)
local function mkToggle(parent, y, text, initial)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 110, 0, 28)
    b.Position = UDim2.new(0, 262, 0, y)
    b.BackgroundColor3 = initial and Color3.fromRGB(70,70,70) or Color3.fromRGB(25,25,25)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = text..": "..(initial and "ON" or "OFF")
    local corner = Instance.new("UICorner", b)
    corner.CornerRadius = UDim.new(0,4)
    b.Parent = parent
    return b
end

local teamCheckBtn = mkToggle(p2, 175, "Team Check", _G.TeamCheckEnabled)
local highlightCheckBtn = mkToggle(p2, 213, "Highlight Check", _G.HighlightCheckEnabled)
local nameEspBtn = mkToggle(p2, 251, "Name ESP", _G.NameESPEnabled)
local tracerBtn = mkToggle(p2, 289, "Tracer", _G.TracerEnabled)
local arrowBtn = mkToggle(p2, 327, "Direction Arrow", _G.ArrowEnabled)

teamCheckBtn.MouseButton1Click:Connect(function()
    _G.TeamCheckEnabled = not _G.TeamCheckEnabled
    teamCheckBtn.BackgroundColor3 = _G.TeamCheckEnabled and Color3.fromRGB(70,70,70) or Color3.fromRGB(25,25,25)
    teamCheckBtn.Text = "Team Check: "..(_G.TeamCheckEnabled and "ON" or "OFF")
end)
highlightCheckBtn.MouseButton1Click:Connect(function()
    _G.HighlightCheckEnabled = not _G.HighlightCheckEnabled
    highlightCheckBtn.BackgroundColor3 = _G.HighlightCheckEnabled and Color3.fromRGB(70,70,70) or Color3.fromRGB(25,25,25)
    highlightCheckBtn.Text = "Highlight Check: "..(_G.HighlightCheckEnabled and "ON" or "OFF")
    if not _G.HighlightCheckEnabled then
        for pl, d in pairs(espData) do if d.highlight then safeDestroy(d.highlight) d.highlight = nil end end
    end
end)
nameEspBtn.MouseButton1Click:Connect(function()
    _G.NameESPEnabled = not _G.NameESPEnabled
    nameEspBtn.BackgroundColor3 = _G.NameESPEnabled and Color3.fromRGB(70,70,70) or Color3.fromRGB(25,25,25)
    nameEspBtn.Text = "Name ESP: "..(_G.NameESPEnabled and "ON" or "OFF")
    if not _G.NameESPEnabled then
        for pl, d in pairs(espData) do if d.nameLabel then d.nameLabel.Visible = false end end
    end
end)
tracerBtn.MouseButton1Click:Connect(function()
    _G.TracerEnabled = not _G.TracerEnabled
    tracerBtn.BackgroundColor3 = _G.TracerEnabled and Color3.fromRGB(70,70,70) or Color3.fromRGB(25,25,25)
    tracerBtn.Text = "Tracer: "..(_G.TracerEnabled and "ON" or "OFF")
    if not _G.TracerEnabled then
        for pl, d in pairs(espData) do if d.tracer then pcall(function() d.tracer:Remove() end) d.tracer = nil end end
    end
end)
arrowBtn.MouseButton1Click:Connect(function()
    _G.ArrowEnabled = not _G.ArrowEnabled
    arrowBtn.BackgroundColor3 = _G.ArrowEnabled and Color3.fromRGB(70,70,70) or Color3.fromRGB(25,25,25)
    arrowBtn.Text = "Direction Arrow: "..(_G.ArrowEnabled and "ON" or "OFF")
    if not _G.ArrowEnabled then
        for pl, d in pairs(espData) do if d.arrowLabel then d.arrowLabel.Visible = false end end
    end
end)

-- ESP toggle should toggle the updated ESP system (he variable)
esB.MouseButton1Click:Connect(function()
    he = not he
    esB.Text = "ESP: "..(he and "ON" or "OFF")
    esB.BackgroundColor3 = he and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(25, 25, 25)
    if not he then
        disableAllESP()
    else
        for _, pl in ipairs(P:GetPlayers()) do if pl ~= p then updatePlayerESP(pl) end end
    end
end)

P.PlayerAdded:Connect(function(v)
    v.CharacterAdded:Connect(function() task.wait(0.2) updatePlayerESP(v) end)
end)

p:GetPropertyChangedSignal("Team"):Connect(function()
    assignedTeamColors = {}
    for pl,_ in pairs(espData) do updatePlayerESP(pl) end
end)

p.CharacterAdded:Connect(function() sFly() sVFly() end)

U.JumpRequest:Connect(function() local h = uj and p.Character and p.Character:FindFirstChildOfClass("Humanoid") if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end)

-- Loading Bar Animation (5 Seconds Duration)
task.spawn(function()
    local tweenService = game:GetService("TweenService")
    local info = TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = tweenService:Create(barFill, info, {Size = UDim2.new(1, 0, 1, 0)})
    tween:Play()
    tween.Completed:Wait()

    -- Smooth fade out effect for the loading screen
    local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fadeBgTween = tweenService:Create(loadBg, fadeInfo, {BackgroundTransparency = 1})
    local fadeTitleTween = tweenService:Create(loadTitle, fadeInfo, {TextTransparency = 1})
    local fadeSubTween = tweenService:Create(loadSub, fadeInfo, {TextTransparency = 1})
    local fadeBarBgTween = tweenService:Create(barBg, fadeInfo, {BackgroundTransparency = 1})
    local fadeBarFillTween = tweenService:Create(barFill, fadeInfo, {BackgroundTransparency = 1})

    fadeBgTween:Play()
    fadeTitleTween:Play()
    fadeSubTween:Play()
    fadeBarBgTween:Play()
    fadeBarFillTween:Play()

    fadeBgTween.Completed:Wait()
    loadBg:Destroy()

    -- Reveal the main UI
    f.Visible = true
end)
