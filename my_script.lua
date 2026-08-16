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

-- UI buttons for toggles integrated into existing UI
-- Find where esB is created above (we are integrating here directly after creation). We'll create new buttons relative to p2.

-- Locate p2 frame from above (exists in outer scope)
-- Create small toggle buttons under existing ESP button
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

-- We want to safely reference p2; it's declared above. If not found, skip creating UI toggles.
local success, _ = pcall(function()
    if not p2 then error("no p2") end
end)
if success then
    -- Place new toggles
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
            -- remove highlights
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

    -- Update p2 layout CanvasSize if it's a ScrollingFrame
    if p2:IsA("ScrollingFrame") then
        p2.CanvasSize = UDim2.new(0,0,0,420)
    end
end

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

-- Existing Hitbox Expander loop (kept, with minor fix to use _G.Disabled semantics correctly)
RS.RenderStepped:Connect(function()
    if _G.Disabled then
        for _, v in ipairs(P:GetPlayers()) do
            if v ~= p and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = v.Character.HumanoidRootPart
                hrp.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize)
                hrp.Transparency = math.clamp(_G.HitboxTransparency / 100, 0, 1)
                hrp.CanCollide = false
                if not hrp:FindFirstChild("HitboxVisual") then
                    local box = Instance.new("SelectionBox")
                    box.Name = "HitboxVisual"
                    box.Color3 = Color3.fromRGB(255, 255, 255)
                    box.LineThickness = 0.03
                    box.Adornee = hrp
                    box.Parent = hrp
                end
            end
        end
    else
        for _, v in ipairs(P:GetPlayers()) do
            if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = v.Character.HumanoidRootPart
                local box = hrp:FindFirstChild("HitboxVisual")
                if box then box:Destroy() end
                -- Reset size only for others (keep local player's HRP default)
                if v ~= p then
                    pcall(function() v.Character.HumanoidRootPart.Size = Vector3.new(2,2,1) end)
                end
            end
        end
    end
end)

-- Clean up on script end or disable: if user toggles off ESP entirely, ensure nothing remains
local function disableAllESP()
    for pl, d in pairs(espData) do clearESPForPlayer(pl) end
    assignedTeamColors = {}
end

-- If user turns off highlights/tracers via the main button (esB above), hook into that button's existing handler which toggles `he`.
-- We will monitor `he` every 0.5s and clear on false
task.spawn(function()
    while true do
        task.wait(0.5)
        if not he then
            disableAllESP()
        else
            -- ensure ESP updates
            for _, pl in ipairs(P:GetPlayers()) do if pl ~= p then updatePlayerESP(pl) end end
        end
    end
end)

-- End of integrated ESP improvements
