local bundle = [======[
local SOLVER_SOURCE = [====[
-- One-click TFC shot solver for the inspected client version.
-- Uses the game's BuildShot and SimulateShot; server randomness/keeper movement remain uncertain.
local player = game:GetService("Players").LocalPlayer
local root = game:GetService("ReplicatedStorage").FootballFreekick
local config = require(root.FreeKickConfig)
local RunService = game:GetService("RunService")
local env = getsenv(player.PlayerScripts.FootballFreekickClient)
assert(type(env.beginCharge) == "function" and type(env.releaseShot) == "function", "Client kick functions unavailable")
local pg = player:WaitForChild("PlayerGui")
-- Dispose the previous skip controller before constructing its replacement.
if getgenv().TFCAutoSkipCleanup then getgenv().TFCAutoSkipCleanup() end
for _, name in ipairs({"TFCAimHelper", "TFCShotSolver"}) do
    local old = pg:FindFirstChild(name)
    if old then old:Destroy() end
end
local oldMarker = workspace:FindFirstChild("TFCAimTarget")
if oldMarker then oldMarker:Destroy() end
local SCRIPT_VERSION = "1.14"
local INSPECTED_PLACE_VERSION = 378
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local gui = Instance.new("ScreenGui")
gui.Name = "TFCShotSolver"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pg

local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0)
shadow.Size = UDim2.fromOffset(500, 270)
shadow.Position = UDim2.new(0.5, 4, 0, 34)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.55
shadow.BorderSizePixel = 0
shadow.ZIndex = 0
shadow.Parent = gui
local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0, 18)
shadowCorner.Parent = shadow

local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Size = UDim2.fromOffset(500, 270)
panel.Position = UDim2.new(0.5, 0, 0, 30)
panel.BackgroundColor3 = Color3.fromRGB(17, 21, 29)
panel.BorderSizePixel = 0
panel.ZIndex = 1
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 18)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(72, 94, 135)
panelStroke.Transparency = 0.22
panelStroke.Thickness = 1.2
panelStroke.Parent = panel

local panelGradient = Instance.new("UIGradient")
panelGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(29, 36, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 18, 26))
})
panelGradient.Rotation = 90
panelGradient.Parent = panel

local header = Instance.new("Frame")
header.Name = "Header"
header.BackgroundTransparency = 1
header.Size = UDim2.new(1, 0, 0, 62)
header.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(18, 10)
title.Size = UDim2.fromOffset(260, 28)
title.Font = Enum.Font.GothamBold
title.Text = "TFC Shot Solver"
title.TextColor3 = Color3.fromRGB(245, 247, 255)
title.TextSize = 19
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local versionLabel = Instance.new("TextLabel")
versionLabel.Name = "VersionLabel"
versionLabel.BackgroundTransparency = 1
versionLabel.Position = UDim2.fromOffset(18, 36)
versionLabel.Size = UDim2.fromOffset(150, 17)
versionLabel.Font = Enum.Font.Gotham
versionLabel.Text = "Version " .. SCRIPT_VERSION
versionLabel.TextColor3 = Color3.fromRGB(138, 154, 185)
versionLabel.TextSize = 11
versionLabel.TextXAlignment = Enum.TextXAlignment.Left
versionLabel.Parent = header

local function setButtonColor(btn, color)
    btn.BackgroundColor3 = color
    btn:SetAttribute("TFCBaseColor", color)
end

local function styleButton(btn, color)
    btn.AutoButtonColor = false
    btn.BackgroundColor3 = color
    btn:SetAttribute("TFCBaseColor", color)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(245, 247, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.86
    stroke.Thickness = 1
    stroke.Parent = btn

    btn.MouseEnter:Connect(function()
        local base = btn:GetAttribute("TFCBaseColor") or btn.BackgroundColor3
        TweenService:Create(btn, TweenInfo.new(0.13), {
            BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.10)
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        local base = btn:GetAttribute("TFCBaseColor") or btn.BackgroundColor3
        TweenService:Create(btn, TweenInfo.new(0.13), {
            BackgroundColor3 = base
        }):Play()
    end)
end

local minimize = Instance.new("TextButton")
minimize.Name = "MinimizeButton"
minimize.Size = UDim2.fromOffset(30, 30)
minimize.Position = UDim2.new(1, -78, 0, 11)
minimize.Text = "—"
minimize.Parent = header
styleButton(minimize, Color3.fromRGB(55, 62, 78))

local close = Instance.new("TextButton")
close.Name = "CloseButton"
close.Size = UDim2.fromOffset(30, 30)
close.Position = UDim2.new(1, -42, 0, 11)
close.Text = "×"
close.TextSize = 18
close.Parent = header
styleButton(close, Color3.fromRGB(155, 60, 68))

local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Size = UDim2.new(1, -36, 0, 1)
divider.Position = UDim2.fromOffset(18, 61)
divider.BorderSizePixel = 0
divider.BackgroundColor3 = Color3.fromRGB(62, 76, 102)
divider.BackgroundTransparency = 0.3
divider.Parent = panel

local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.BackgroundTransparency = 1
tabBar.Position = UDim2.fromOffset(18, 70)
tabBar.Size = UDim2.fromOffset(464, 30)
tabBar.Parent = panel

local statusTab = Instance.new("TextButton")
statusTab.Name = "StatusTab"
statusTab.Size = UDim2.fromOffset(100, 28)
statusTab.Position = UDim2.fromOffset(0, 0)
statusTab.Text = "Status"
statusTab.Parent = tabBar
styleButton(statusTab, Color3.fromRGB(60, 105, 190))

local controlsTab = Instance.new("TextButton")
controlsTab.Name = "ControlsTab"
controlsTab.Size = UDim2.fromOffset(100, 28)
controlsTab.Position = UDim2.fromOffset(108, 0)
controlsTab.Text = "Controls"
controlsTab.Parent = tabBar
styleButton(controlsTab, Color3.fromRGB(47, 53, 68))

local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Position = UDim2.fromOffset(18, 108)
content.Size = UDim2.new(1, -36, 0, 100)
content.Parent = panel

local statusPage = Instance.new("Frame")
statusPage.Name = "StatusPage"
statusPage.BackgroundTransparency = 1
statusPage.Size = UDim2.fromScale(1, 1)
statusPage.Parent = content

local controlsPage = Instance.new("Frame")
controlsPage.Name = "ControlsPage"
controlsPage.BackgroundTransparency = 1
controlsPage.Size = UDim2.fromScale(1, 1)
controlsPage.Visible = false
controlsPage.Parent = content

local statusIndicator = Instance.new("Frame")
statusIndicator.Name = "StatusIndicator"
statusIndicator.Size = UDim2.fromOffset(8, 8)
statusIndicator.Position = UDim2.fromOffset(2, 7)
statusIndicator.BackgroundColor3 = Color3.fromRGB(82, 205, 125)
statusIndicator.BorderSizePixel = 0
statusIndicator.Parent = statusPage
local indicatorCorner = Instance.new("UICorner")
indicatorCorner.CornerRadius = UDim.new(1, 0)
indicatorCorner.Parent = statusIndicator

local statusTitle = Instance.new("TextLabel")
statusTitle.Name = "StatusTitle"
statusTitle.BackgroundTransparency = 1
statusTitle.Position = UDim2.fromOffset(18, 0)
statusTitle.Size = UDim2.fromOffset(120, 22)
statusTitle.Font = Enum.Font.GothamSemibold
statusTitle.Text = "READY"
statusTitle.TextColor3 = Color3.fromRGB(82, 205, 125)
statusTitle.TextSize = 12
statusTitle.TextXAlignment = Enum.TextXAlignment.Left
statusTitle.Parent = statusPage

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.fromOffset(0, 27)
statusLabel.Size = UDim2.new(1, 0, 1, -27)
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "Ready. Choose a freekick, then press Solve & Shoot."
statusLabel.TextColor3 = Color3.fromRGB(224, 230, 241)
statusLabel.TextSize = 14
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = statusPage

local controlsInfo = Instance.new("TextLabel")
controlsInfo.Name = "ControlsInfo"
controlsInfo.BackgroundTransparency = 1
controlsInfo.Position = UDim2.fromOffset(0, 0)
controlsInfo.Size = UDim2.new(1, 0, 0, 32)
controlsInfo.Font = Enum.Font.Gotham
controlsInfo.Text = "Presentation controls"
controlsInfo.TextColor3 = Color3.fromRGB(165, 178, 202)
controlsInfo.TextSize = 12
controlsInfo.TextXAlignment = Enum.TextXAlignment.Left
controlsInfo.Parent = controlsPage

local skipButton = Instance.new("TextButton")
skipButton.Name = "TFCAutoSkip"
skipButton.Size = UDim2.new(1, 0, 0, 38)
skipButton.Position = UDim2.fromOffset(0, 38)
skipButton.Text = "Auto Skip: ON"
skipButton.Parent = controlsPage
styleButton(skipButton, Color3.fromRGB(42, 132, 83))

local button = Instance.new("TextButton")
button.Name = "SolveButton"
button.Size = UDim2.new(1, -36, 0, 40)
button.Position = UDim2.new(0, 18, 1, -50)
button.Text = "Solve & Shoot"
button.Parent = panel
styleButton(button, Color3.fromRGB(55, 120, 235))

local function setStatus(state, message)
    statusLabel.Text = message

    if state == "working" then
        statusTitle.Text = "WORKING"
        statusTitle.TextColor3 = Color3.fromRGB(245, 190, 75)
        statusIndicator.BackgroundColor3 = Color3.fromRGB(245, 190, 75)
    elseif state == "fallback" then
        statusTitle.Text = "FALLBACK"
        statusTitle.TextColor3 = Color3.fromRGB(245,190,75)
        statusIndicator.BackgroundColor3 = Color3.fromRGB(245,190,75)
    elseif state == "success" then
        statusTitle.Text = "SUCCESS"
        statusTitle.TextColor3 = Color3.fromRGB(85, 210, 140)
        statusIndicator.BackgroundColor3 = Color3.fromRGB(85, 210, 140)
    elseif state == "error" then
        statusTitle.Text = "ERROR"
        statusTitle.TextColor3 = Color3.fromRGB(235, 85, 90)
        statusIndicator.BackgroundColor3 = Color3.fromRGB(235, 85, 90)
    else
        statusTitle.Text = "READY"
        statusTitle.TextColor3 = Color3.fromRGB(82, 205, 125)
        statusIndicator.BackgroundColor3 = Color3.fromRGB(82, 205, 125)
    end
end

local function openTab(name)
    local onStatus = name == "Status"
    statusPage.Visible = onStatus
    controlsPage.Visible = not onStatus
    setButtonColor(statusTab, onStatus and Color3.fromRGB(60, 105, 190) or Color3.fromRGB(47, 53, 68))
    setButtonColor(controlsTab, onStatus and Color3.fromRGB(47, 53, 68) or Color3.fromRGB(60, 105, 190))
end

statusTab.Activated:Connect(function()
    openTab("Status")
end)

controlsTab.Activated:Connect(function()
    openTab("Controls")
end)

local minimized = false
local fullSize = UDim2.fromOffset(500, 270)
local minimizedSize = UDim2.fromOffset(500, 55)

minimize.Activated:Connect(function()
    minimized = not minimized
    if minimized then
        content.Visible = false
        tabBar.Visible = false
        divider.Visible = false
        versionLabel.Visible = false
        button.Visible = false
        minimize.Text = "+"
        TweenService:Create(panel, TweenInfo.new(0.18), {Size = minimizedSize}):Play()
        TweenService:Create(shadow, TweenInfo.new(0.18), {Size = minimizedSize}):Play()
    else
        minimize.Text = "—"
        TweenService:Create(panel, TweenInfo.new(0.18), {Size = fullSize}):Play()
        TweenService:Create(shadow, TweenInfo.new(0.18), {Size = fullSize}):Play()
        task.delay(0.16, function()
            if gui.Parent and not minimized then
                content.Visible = true
                tabBar.Visible = true
                divider.Visible = true
                versionLabel.Visible = true
                button.Visible = true
            end
        end)
    end
end)

local dragging = false
local dragInput
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
        shadow.Position = UDim2.new(
            panel.Position.X.Scale,
            panel.Position.X.Offset + 4,
            panel.Position.Y.Scale,
            panel.Position.Y.Offset + 4
        )
    end
end)

local busy = false
local autoEnabled, autoRunning = getgenv().TFCAutomationEnabled ~= false, false
local MIN_POWER, MAX_POWER = 0.65, 0.73
local function controlsShot()
    return type(env.localControlsCurrentShot) ~= "function" or env.localControlsCurrentShot()
end
close.Activated:Connect(function() if not busy then gui:Destroy() end end)
-- Learn scripted wall jumps while this helper is open. Humanoid.JumpHeight is
-- not the active jump setting here (the inspected NPCs have JumpPower = 0).
local shared = getgenv()
shared.TFCMotionProfile = shared.TFCMotionProfile or {walls={},keepers={}}
local motion = shared.TFCMotionProfile
motion.successfulShots=motion.successfulShots or {}
local pendingShots={}
if shared.TFCMotionObserver then shared.TFCMotionObserver:Disconnect() end
local lastPhase, shotStarted, keeperStart
local observationElapsed = 0
local observer = RunService.Heartbeat:Connect(function(dt)
    observationElapsed += dt
    if observationElapsed < 0.05 then return end
    observationElapsed = 0
    local runtime = workspace:FindFirstChild("FreekickSystemRuntime")
    if not runtime then return end
    local phase = player:GetAttribute("FootballFreekickPhase")
    if phase=="shot" and lastPhase~="shot" then shotStarted=os.clock(); keeperStart=nil end
    for _, obj in ipairs(runtime:GetChildren()) do
        local kind=obj:GetAttribute("SetupObjectKind")
        if kind=="Wall" then
            local key=obj:GetAttribute("SetupObjectId") or obj.Name
            local rec=motion.walls[key] or {rise=0}
            rec.baselines=rec.baselines or {}
            rec.timeline=rec.timeline or {}
            motion.walls[key]=rec
            for _, p in ipairs(obj:GetDescendants()) do
                if p:IsA("BasePart") and p.Name=="HumanoidRootPart" then
                    local id=p.Parent.Name
                    if phase=="kick" then rec.baselines[id]=p.Position.Y end
                    local base=rec.baselines[id]
                    if phase=="shot" and shotStarted and base then
                        local rise=math.max(0,p.Position.Y-base)
                        local bin=math.clamp(math.ceil((os.clock()-shotStarted)*20),1,60)
                        rec.timeline[bin]=math.max(rec.timeline[bin] or 0,rise)
                        rec.rise=math.max(rec.rise,rise)
                        if rise>0.15 then rec.observed=true end
                    end
                end
            end
        elseif kind=="Goalkeeper" then
            local difficulty=obj:GetAttribute("KeeperDifficulty") or "Unknown"
            local p=obj:FindFirstChild("HumanoidRootPart",true)
            if p and phase=="shot" and shotStarted then
                keeperStart=keeperStart or p.Position
                local rec=motion.keepers[difficulty] or {speed=0,travel={}}
                rec.travel=rec.travel or {}
                motion.keepers[difficulty]=rec
                local elapsed=os.clock()-shotStarted
                local displacement=math.abs(p.Position.Z-keeperStart.Z)
                local bin=math.clamp(math.ceil(elapsed*20),1,60)
                rec.travel[bin]=math.max(rec.travel[bin] or 0,displacement)
                if displacement>0.25 then rec.reaction=math.min(rec.reaction or elapsed,elapsed) end
                rec.vertical=math.max(rec.vertical or 0,p.Position.Y-keeperStart.Y)
            end
        end
    end
    lastPhase=phase
end)
shared.TFCMotionObserver=observer
local shotEvents=root.Remotes.FreeKickRemote.OnClientEvent:Connect(function(event,data)
    if type(data)~="table" then return end
    if event=="ShotAccepted" then
        local u=debug.getupvalues(env.commitQueuedShot)
        local id=data.shotSequence
        if id and (not data.shooterUserId or data.shooterUserId==player.UserId) then
            pendingShots[id]={leg=u[11],power=u[6],aimYaw=u[7],contactX=u[8],contactY=u[9],
                origin=debug.getupvalues(env.beginCharge)[16]}
        end
    elseif event=="GoalConfirmed" then
        local rec=pendingShots[data.shotSequence]
        if rec then
            table.insert(motion.successfulShots,rec)
            if #motion.successfulShots>20 then table.remove(motion.successfulShots,1) end
            print("TFC_LEARNED_GOAL yaw="..rec.aimYaw.." power="..rec.power.." contact="..rec.contactX..","..rec.contactY)
            pendingShots[data.shotSequence]=nil
        end
    end
end)
gui.Destroying:Connect(function()
    observer:Disconnect()
    shotEvents:Disconnect()
    if shared.TFCMotionObserver==observer then shared.TFCMotionObserver=nil end
end)

local function validateClient()
    local u = debug.getupvalues(env.commitQueuedShot)
    assert(#u == 11 and typeof(u[5]) == "Instance" and u[5].Name == "FreeKickRemote"
        and type(u[6]) == "number" and type(u[11]) == "string", "Client version changed; refusing to change shot settings")
    local r = debug.getupvalues(env.releaseShot)
    assert(#r == 14 and type(r[2]) == "boolean" and type(r[3]) == "boolean"
        and type(r[4]) == "boolean" and type(r[5]) == "number"
        and type(r[6]) == "number" and type(r[7]) == "number"
        and type(r[8]) == "number", "Release function changed")
    local charge = debug.getupvalues(env.beginCharge)
    assert(#charge == 20 and type(charge[7]) == "boolean" and type(charge[8]) == "number"
        and type(charge[9]) == "number", "Precision timing function changed")
    return u
end

local function waitForGreen()
    local deadline = os.clock() + 5
    setStatus("working", "Shot calculated. Waiting for the shrinking circle to reach green...")
    while os.clock() < deadline do
        RunService.RenderStepped:Wait()
        assert(gui.Parent, "Solver closed")
        local u = validateClient()
        assert(u[1] == "kick" and not u[2] and not u[3], "Kick phase changed while waiting")
        local charge = debug.getupvalues(env.beginCharge)
        assert(not charge[7], "Timing already locked by another shot; reset and retry")
        local threshold = charge[9]
        assert(threshold > 0 and threshold < 0.98, "Green timing window unavailable")
        -- This is the same shrinking-circle phase and green threshold used by beginCharge.
        -- Stay away from the cycle boundary so a frame delay cannot wrap the phase to red.
        local phase = os.clock() * 1.05 % 1
        local lower = threshold + math.min(0.02, (1-threshold)*0.2)
        if phase >= lower and phase <= 0.98 then
            return phase, threshold
        end
    end
    error("Could not reach the green timing window; no shot started")
end

-- Read game-owned attributes; never change the player's ratings.
local liveStats = {Right={},Left={}}
local statConnections = {}
local function refreshPlayerStats()
    local lines = {}
    for _, foot in ipairs({"Right","Left"}) do
        local ratings = liveStats[foot]
        for _, key in ipairs({"ACC","PRE","POW","CUR"}) do
            ratings[key] = player:GetAttribute("FootballStat_"..foot.."_"..key)
        end
        table.insert(lines,string.format("%s: ACC %s | PRE %s | POW %s | CUR %s",foot,
            tostring(ratings.ACC),tostring(ratings.PRE),tostring(ratings.POW),tostring(ratings.CUR)))
    end
    if controlsInfo.Parent then
        controlsInfo.Text = table.concat(lines,"\n")
        controlsInfo.TextWrapped = true
    end
end
for _, foot in ipairs({"Right","Left"}) do
    for _, key in ipairs({"ACC","PRE","POW","CUR"}) do
        table.insert(statConnections,player:GetAttributeChangedSignal("FootballStat_"..foot.."_"..key):Connect(refreshPlayerStats))
    end
end
gui.Destroying:Connect(function()
    for _, connection in ipairs(statConnections) do connection:Disconnect() end
end)
refreshPlayerStats()

local function setupFingerprint()
    local values = {tostring(player.Character), tostring(game.PlaceVersion)}
    for _, foot in ipairs({"Right", "Left"}) do
        for _, key in ipairs({"ACC", "PRE", "POW", "CUR"}) do
            table.insert(values, tostring(player:GetAttribute("FootballStat_"..foot.."_"..key)))
        end
    end
    local function appendTable(prefix, t)
        for k,v in pairs(t or {}) do
            if type(v) ~= "table" and type(v) ~= "function" then
                table.insert(values, prefix..tostring(k).."="..tostring(v))
            end
        end
    end
    appendTable("wind:", env.kickWindConfiguration)
    appendTable("perk:", env.currentPerks())
    local runtime = workspace:FindFirstChild("FreekickSystemRuntime")
    for _, obj in ipairs(runtime and runtime:GetChildren() or {}) do
        table.insert(values, tostring(obj)..":"..obj.Name)
        for _, key in ipairs({"SetupObjectKind", "SetupObjectId", "KeeperDifficulty"}) do
            table.insert(values, obj.Name..":"..key.."="..tostring(obj:GetAttribute(key)))
        end
        if obj:GetAttribute("SetupObjectKind") == "Wall" then
            for _, part in ipairs(obj:GetDescendants()) do
                if part:IsA("BasePart") and part.Name == "HumanoidRootPart" then
                    local p = part.Position
                    table.insert(values, string.format("%s:%.0f/%.0f/%.0f",part:GetFullName(),
                        math.round(p.X*4),math.round(p.Y*4),math.round(p.Z*4)))
                end
            end
        end
    end
    table.sort(values)
    return table.concat(values, "|")
end

-- Persistent records use observed results, never simulated hit counts.
local ConfigHttp=game:GetService("HttpService")
local configShared=getgenv()
local CONFIG_FOLDER="TFCShotSolver"
local CONFIG_PATH=CONFIG_FOLDER.."/position-configs.json"
local positionConfig=configShared.TFCPositionConfig
if not positionConfig then
 positionConfig={schema=1,records={},lastWrite=0}
 if type(isfile)=="function" and type(readfile)=="function" then
  local ok,data=pcall(function() if isfile(CONFIG_PATH) then return ConfigHttp:JSONDecode(readfile(CONFIG_PATH)) end
   if isfile("TFCShotConfigs.json") then return ConfigHttp:JSONDecode(readfile("TFCShotConfigs.json")) end end)
  if ok and type(data)=="table" and data.schema==1 and type(data.records)=="table" then positionConfig.records=data.records end
 end
 configShared.TFCPositionConfig=positionConfig
end
positionConfig.dirty=true -- Migrate existing records to the script's workspace folder.
local function positionContext()
 local values={tostring(game.PlaceVersion)}
 for k,v in pairs(env.kickWindConfiguration or {}) do table.insert(values,"wind:"..k.."="..tostring(v)) end
 for k,v in pairs(env.currentPerks()) do table.insert(values,"perk:"..k.."="..tostring(v)) end
 local runtime=workspace:FindFirstChild("FreekickSystemRuntime")
 for _,obj in ipairs(runtime and runtime:GetChildren() or {}) do
  local kind=obj:GetAttribute("SetupObjectKind")
  table.insert(values,tostring(kind)..":"..tostring(obj:GetAttribute("KeeperDifficulty")))
  if kind~="Goalkeeper" then for _,p in ipairs(obj:GetDescendants()) do
   if p:IsA("BasePart") and (p.Name=="HumanoidRootPart" or not obj:IsA("Model")) then
    table.insert(values,string.format("%s:%.1f/%.1f:%.1f/%.1f/%.1f",p.Name,p.Position.X,p.Position.Z,p.Size.X,p.Size.Y,p.Size.Z))
   end
  end end
 end
 table.sort(values);return table.concat(values,"|")
end
positionConfig.observe=function(records)
 local changed=false
 for _,r in ipairs(records) do
  if r.source=="solver" and r.context and r.outcome~="pending" and r.outcome~="unknown" then
   local key=tostring(r.startedAt).."/"..tostring(r.sequence).."/"..tostring(r.clockStarted)
   local success=r.objective=="Crossbar" and ((r.contacts and r.contacts.Crossbar==true) or (r.gameObjective=="Crossbar" and r.outcome=="goal")) or (r.objective~="Crossbar" and r.outcome=="goal")
   local old=positionConfig.records[key]
   if not old or old.success~=success then
    local record=table.clone(r);record.success=success;positionConfig.records[key]=record;changed=true
   end
  end
 end
 if changed then positionConfig.dirty=true end
 if positionConfig.dirty and os.clock()-positionConfig.lastWrite>=5 and type(writefile)=="function" then
  local ok,e=pcall(function()
   if type(isfolder)=="function" and type(makefolder)=="function" and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
   local successful,missed={},{}
   for key,rec in pairs(positionConfig.records) do
    if rec.success then successful[key]=rec else missed[key]=rec end
   end
   writefile(CONFIG_PATH,ConfigHttp:JSONEncode({schema=1,records=positionConfig.records}))
   writefile(CONFIG_FOLDER.."/successful-shots.json",ConfigHttp:JSONEncode({schema=1,records=successful}))
   writefile(CONFIG_FOLDER.."/missed-shots.json",ConfigHttp:JSONEncode({schema=1,records=missed}))
  end)
  if ok then positionConfig.dirty=false;positionConfig.lastWrite=os.clock();print("TFC_POSITION_CONFIG_SAVED") else warn("TFC_POSITION_CONFIG_ERROR "..tostring(e)) end
 end
end
print("TFC_POSITION_CONFIG_READY persisted position/stats/wind/obstacles and actual successes")

local function solve()
    local u = validateClient()
    assert(u[1] == "kick" and not u[2] and not u[3], "Enter the kick/aim screen first; finish the current shot if needed")
    assert(controlsShot(), "Wait for your turn to shoot")
    assert(not debug.getupvalues(env.releaseShot)[2], "A shot is already charging; finish it first")
    local ball = workspace:FindFirstChild("Ball")
    assert(ball and ball:IsA("BasePart"), "Ball unavailable")
    assert(ball.AssemblyLinearVelocity.Magnitude < 3, "Wait until the ball is stationary")
    local origin = ball.Position
    local activeMode=player:GetAttribute("FootballSetupMode") or "Normal"
    local crossbar = type(env.objectiveSuccessText)=="function" and env.objectiveSuccessText()=="CROSSBAR"
    assert(crossbar or activeMode=="Normal","Unsupported objective: "..tostring(activeMode))
    local objective = crossbar and "Crossbar" or "Normal"
    local topBar = workspace:FindFirstChild("Goal") and workspace.Goal:FindFirstChild("TopBar")
    assert(not crossbar or (topBar and topBar:IsA("BasePart")),"Crossbar geometry unavailable")
    local goal = crossbar and config.GoalCenter() or (env.objectiveTargetPosition or config.GoalCenter())
    print("TFC_OBJECTIVE "..objective)
    assert(math.abs(goal.X - config.Goal.X) < 1 and math.abs(goal.Z - config.Goal.CenterZ) < 1,
        "This solver currently supports the full-size goal")
    assert(origin.X < config.Goal.X - 2, "Reset the ball for a freekick")
    local schema = require(root.AdvancedSetupSchema)
    local windConfiguration = table.clone(env.kickWindConfiguration or {})
    local windVelocity = schema.WindVelocityStuds(windConfiguration)
    local fingerprint = setupFingerprint()
    local context=positionContext()
    local character = player.Character
    local distance = (goal-origin).Magnitude
    setStatus("working", string.format("Sampling setup: %.1f studs (%.1f m); wind %s", distance,
        distance * config.MetersPerStud, tostring(windVelocity)))
    task.wait(0.25)
    assert(setupFingerprint() == fingerprint and (ball.Position-origin).Magnitude < 0.2,
        "Setup changed while sampling; retry")
    print(string.format("TFC_DATA v%s placeVersion=%s character=%s distance=%.2fstuds/%.2fm wind=%s",
        SCRIPT_VERSION,tostring(game.PlaceVersion),character and character.Name or "none",
        distance,distance*config.MetersPerStud,tostring(windVelocity)))
    local leg = u[11]
    local stats = {}
    for _, key in ipairs({"ACC", "PRE", "POW", "CUR"}) do
        stats[key] = player:GetAttribute("FootballStat_" .. leg .. "_" .. key) or 60
    end
    local perks = env.currentPerks()
    -- The firing path waits for a naturally perfect green timing score.
    local precision = 1
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {workspace.FreekickSystemRuntime}
    local keeperParts, keeperRoot, walls = {}, nil, {}
    local difficulty = "Easy"
    local forward = Vector3.new(goal.X-origin.X,0,goal.Z-origin.Z).Unit
    local lateral = Vector3.new(-forward.Z,0,forward.X)
    for _, obj in ipairs(workspace.FreekickSystemRuntime:GetChildren()) do
        if obj:GetAttribute("SetupObjectKind") == "Goalkeeper" then
            difficulty = obj:GetAttribute("KeeperDifficulty") or "Unknown"
            keeperRoot = obj:FindFirstChild("HumanoidRootPart",true) or keeperRoot
            for _, p in ipairs(obj:GetDescendants()) do
                if p:IsA("BasePart") and p.Transparency < 1 then table.insert(keeperParts, {Position=p.Position,AssemblyLinearVelocity=p.AssemblyLinearVelocity,Size=p.Size}) end
            end
        elseif obj:GetAttribute("SetupObjectKind") == "Wall" then
            local w = {minDepth=math.huge,maxDepth=-math.huge,minSide=math.huge,maxSide=-math.huge,top=-math.huge,nearestDistance=math.huge}
            for _, p in ipairs(obj:GetDescendants()) do
                if p:IsA("BasePart") and p.Name == "HumanoidRootPart" then
                    w.nearestDistance = math.min(w.nearestDistance,(p.Position-origin).Magnitude)
                end
                if p:IsA("BasePart") and p.Transparency < 1 then
                    w.nearestDistance = math.min(w.nearestDistance,(p.Position-origin).Magnitude)
                    for _, x in ipairs({-1,1}) do for _, y in ipairs({-1,1}) do for _, z in ipairs({-1,1}) do
                        local point = p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2)
                        local d,side = (point-origin):Dot(forward),(point-origin):Dot(lateral)
                        w.minDepth,w.maxDepth = math.min(w.minDepth,d),math.max(w.maxDepth,d)
                        w.minSide,w.maxSide = math.min(w.minSide,side),math.max(w.maxSide,side)
                        w.top = math.max(w.top,point.Y)
                    end end end
                end
            end
            local rec=motion.walls[obj:GetAttribute("SetupObjectId") or obj.Name]
            -- Use height at ball arrival when timing has been observed. Do not
            -- add a lifetime minimum-root-height error to every future jump.
            w.jumpRise=math.max(2.5,rec and rec.rise or 0)
            w.jumpTimeline=rec and table.clone(rec.timeline or {}) or {}
            if w.top > -math.huge and w.minDepth > 0 then table.insert(walls,w) end
        end
    end
    local advanced = difficulty ~= "Easy"
    local hard = difficulty == "Hard" or difficulty == "Unknown"
    local scatterSamples = hard and 160 or 96
    local reliabilityTarget = 0.70
    -- Trajectory reliability lower bound; this does not estimate scoring odds.
    local function reliabilityLower(hits, samples)
        local z, p = 1.96, hits / samples
        return (p + z*z/(2*samples)
            - z*math.sqrt(p*(1-p)/samples + z*z/(4*samples*samples)))
            / (1 + z*z/samples)
    end
    -- Retain a jump reserve on every difficulty until observed motion is available.
    refreshPlayerStats()
    local statsByLeg = {Right=table.clone(liveStats.Right),Left=table.clone(liveStats.Left)}
    for _, ratings in pairs(statsByLeg) do
        for _, key in ipairs({"ACC","PRE","POW","CUR"}) do
            assert(type(ratings[key])=="number", "Player stats are still loading")
        end
    end
    for foot, ratings in pairs(statsByLeg) do
        print(string.format("TFC_STATS %s ACC=%d PRE=%d POW=%d CUR=%d",foot,ratings.ACC,ratings.PRE,ratings.POW,ratings.CUR))
    end
    print("TFC_DIFFICULTY "..difficulty.." scatterSamples="..scatterSamples.." measuredWallJumpReserve="..tostring(walls[1] and walls[1].jumpRise))
    -- Goal sides are measured in world Z, consistent with the game's goal geometry.
    local keeperPosition = keeperRoot and keeperRoot.Position or nil
    local keeperVelocity = keeperRoot and keeperRoot.AssemblyLinearVelocity or Vector3.zero
    local telemetrySnapshot={}
    local storage=player.PlayerGui:FindFirstChild("TFCShotTelemetry")
    if storage and storage:GetAttribute("SnapshotJSON") then
        local ok,data=pcall(game:GetService("HttpService").JSONDecode,game:GetService("HttpService"),storage:GetAttribute("SnapshotJSON"))
        if ok then telemetrySnapshot=data end
    end
    local keeperProfile=telemetrySnapshot.keeperProfiles and telemetrySnapshot.keeperProfiles[difficulty]
    local preferredSide
    local keeperLeftDistance, keeperRightDistance
    if keeperPosition then
        local postHalf = config.Goal.Width/2
        keeperLeftDistance = (keeperPosition-Vector3.new(goal.X,keeperPosition.Y,goal.Z-postHalf)).Magnitude
        keeperRightDistance = (keeperPosition-Vector3.new(goal.X,keeperPosition.Y,goal.Z+postHalf)).Magnitude
        -- When centered, both sides are equally available; otherwise choose the farther post.
        if math.abs(keeperLeftDistance-keeperRightDistance)>0.05 then
            preferredSide = keeperLeftDistance>keeperRightDistance and -1 or 1
        end
    end
    print(string.format("TFC_TARGET_SIDE keeperLeftPost=%.2f keeperRightPost=%.2f target=%s",
        keeperLeftDistance or -1,keeperRightDistance or -1,
        preferredSide and (preferredSide<0 and "left" or "right") or "either (centered/no keeper)"))
    for i,w in ipairs(walls) do
        print(string.format("TFC_DEFENDER_DISTANCE wall=%d ballToDefender=%.2fstuds/%.2fm depth=%.2f..%.2f topY=%.2f jumpReserve=%.2f",
            i,w.nearestDistance,w.nearestDistance*config.MetersPerStud,w.minDepth,w.maxDepth,w.top,w.jumpRise))
    end
    local half = config.Goal.Width / 2 - config.BallRadius - 0.5
    local minY = config.Field.SurfaceY + config.BallRadius + 0.3
    local maxY = config.Field.SurfaceY + config.Goal.Height - config.BallRadius
    local targetY = maxY - 1.0
    local targetZ = half - 1.1
    if crossbar then targetY=topBar.Position.Y;targetZ=0 end
    local learnedSettings={}
    for _,rec in pairs(positionConfig.records) do
        if rec.context==context and rec.objective==objective and rec.origin and rec.stats and statsByLeg[rec.leg] then
            local p=rec.origin
            local compatible=(origin-Vector3.new(p.x,p.y,p.z)).Magnitude<=2
            for _,key in ipairs({"ACC","PRE","POW","CUR"}) do if rec.stats[key]~=statsByLeg[rec.leg][key] then compatible=false end end
            if compatible then table.insert(learnedSettings,rec) end
        end
    end
    local function observedPreference(input)
        local hits,misses=0,0
        for _,rec in ipairs(learnedSettings) do
            if rec.leg==input.leg and math.abs(rec.power-input.power)<=0.008
                and math.abs(rec.aimYaw-input.aimYaw)<=0.45
                and math.abs(rec.contactX-input.contactX)<=0.045
                and math.abs(rec.contactY-input.contactY)<=0.045 then
                if rec.success then hits+=1 else misses+=1 end
            end
        end
        -- Weak evidence nudges ranking; repeated misses push the search to a
        -- different angle/contact/power instead of replaying a known failure.
        return math.clamp(hits*10-misses*12,-48,30),hits,misses
    end
    print("TFC_POSITION_HISTORY compatible attempts="..#learnedSettings)
    local lastYield = os.clock()
    local function evaluate(input, seed, explore)
        if os.clock()-lastYield > 0.012 then
            task.wait()
            lastYield = os.clock()
            assert(gui.Parent and player.Character == character and controlsShot(), "Shot setup unavailable")
            assert(not autoRunning or autoEnabled,"Auto Play paused")
            assert(player:GetAttribute("FootballFreekickPhase") == "kick", "Kick phase changed during calculation")
            assert((ball.Position-origin).Magnitude < 0.2, "Ball moved during calculation")
        end
        if input.power < MIN_POWER or input.power > MAX_POWER then return nil end
        local simulationInput = table.clone(input)
        simulationInput.seed = seed
        local shot = config.BuildShot(simulationInput)
        -- Same conversion and air-drag wind field used by the game's ballistics.
        shot.windVelocity = windVelocity
        local sampleRate = explore and 30 or 90
        local duration = config.ShotDuration or 5
        local path = config.SimulateShot(shot, origin, duration, duration*sampleRate, true)
        local prior = origin
        local crossing, crossingIndex, arrival, goalSpeed
        for i, pos in ipairs(path) do
            if prior.X < config.Goal.X and pos.X >= config.Goal.X then
                local alpha = (config.Goal.X - prior.X) / (pos.X - prior.X)
                crossing = prior:Lerp(pos, alpha)
                crossingIndex, arrival = i, (i - 1 + alpha) / sampleRate
                goalSpeed = (pos-prior).Magnitude*sampleRate
                break
            end
            prior = pos
        end
        if not crossing then return nil end
        local valid, penalty = true, 0
        local function constraint(ok, violation)
            if not ok then valid=false; penalty+=math.max(violation or 1,0.1)*12 end
        end
        local curved = math.abs(shot.curve) >= 0.12 and shot.mode ~= "Knuckle"
        local corner
        local barDistance,barReach
        if crossbar then
            -- Same capsule geometry as the game's Crossbar objective, measured
            -- at the segment's intersection with the bar's central plane.
            local barPoint=topBar.CFrame:PointToObjectSpace(crossing)
            local nearest=topBar.CFrame:PointToWorldSpace(Vector3.new(math.clamp(barPoint.X,-topBar.Size.X/2,topBar.Size.X/2),0,0))
            barDistance=(crossing-nearest).Magnitude
            barReach=config.BallRadius+math.max(topBar.Size.Y,topBar.Size.Z)/2
            local hitRadius=barReach-(seed==0 and 0.15 or 0)
            constraint(barDistance<=hitRadius,barDistance-hitRadius)
            corner=barDistance<=hitRadius
            if preferredSide then
                local separation=(crossing.Z-goal.Z)*preferredSide
                constraint(separation>=half*0.45,half*0.45-separation)
            end
        else
        constraint(math.abs(crossing.Z-goal.Z)<=half,math.abs(crossing.Z-goal.Z)-half)
        constraint(crossing.Y>=minY,minY-crossing.Y)
        constraint(crossing.Y<=maxY,crossing.Y-maxY)
        corner = curved and crossing.Y >= maxY-2.3 and math.abs(crossing.Z-goal.Z) >= half-3.5
        -- Aim the nominal shot at the upper corner. A scattered shot remains valid
        -- if it clears the jumping wall and stays in the goal, even if it lands
        -- outside the small corner target; counting those as misses was too strict.
        -- Upper corners are a ranking preference, not grounds for discarding a
        -- clean, curved goal-mouth shot such as a proven manual kick.
        constraint(shot.mode ~= "Knuckle",1)
        -- Nominal and scattered trajectories must remain on the farther half of the goal.
        local sideSeparation = preferredSide and (crossing.Z-goal.Z)*preferredSide or math.abs(crossing.Z-goal.Z)
        constraint(sideSeparation >= 0.5, 0.5-sideSeparation)
        if seed == 0 then
            -- Aim the nominal trajectory at the opposite upper corner, inside the frame.
            constraint(crossing.Y >= maxY-2.3, maxY-2.3-crossing.Y)
            -- Extra nominal clearance for frame thickness and scatter near the bar.
            constraint(crossing.Y <= maxY-0.5, crossing.Y-(maxY-0.5))
            constraint(math.abs(crossing.Z-goal.Z) <= half-0.3, math.abs(crossing.Z-goal.Z)-(half-0.3))
            constraint(sideSeparation >= half-3.5, half-3.5-sideSeparation)
        end
        end
        if not valid and not explore then return nil end
        -- Require the ball to pass above the defenders, including a clearance buffer.
        -- Testing both faces prevents a dipping ball from clipping the back of the wall.
        local wallClearance, jumpClearance = math.huge, math.huge
        for _, w in ipairs(walls) do
            for _, depth in ipairs({w.minDepth,(w.minDepth+w.maxDepth)/2,w.maxDepth}) do
                local prev = origin
                local found, wallArrival
                for i=1,crossingIndex do
                    local pos = path[i]
                    local da,db = (prev-origin):Dot(forward),(pos-origin):Dot(forward)
                    if da<=depth and db>=depth and db-da>0.0001 then
                        local alpha=(depth-da)/(db-da)
                        found = prev:Lerp(pos,alpha)
                        wallArrival=(i-1+alpha)/sampleRate
                        break
                    end
                    prev=pos
                end
                if not found then return nil end
                local jumpAtArrival=w.jumpRise
                local bin=math.clamp(math.ceil(wallArrival*20),1,60)
                local timed,covered=0,false
                -- Include neighboring frames for network and jump-timing variation.
                for j=math.max(1,bin-2),math.min(60,bin+2) do
                    if w.jumpTimeline[j]~=nil then covered=true; timed=math.max(timed,w.jumpTimeline[j]) end
                end
                if covered then jumpAtArrival=timed+0.35 end
                local clearance = found.Y-w.top-config.BallRadius
                -- Current defender height is a geometric requirement. The uncertain
                -- future jump is a separate risk measurement, not a certain collision.
                constraint(clearance>=0.35,0.35-clearance)
                if clearance<0.35 and not explore then return nil end
                wallClearance=math.min(wallClearance,clearance)
                jumpClearance=math.min(jumpClearance,clearance-jumpAtArrival)
            end
            -- On-target candidates below defender height are rejected.
        end
        prior = origin
        for i = 1, crossingIndex, (explore and 3 or 1) do
            local pos = path[i]
            local delta = pos - prior
            if delta.Magnitude > 0.001 and workspace:Spherecast(prior, config.BallRadius, delta, params) then
                constraint(false,4); if not explore then return nil end; break
            end
            prior = pos
        end
        if (crossing - prior).Magnitude > 0.001 and workspace:Spherecast(prior, config.BallRadius, crossing - prior, params) then
            constraint(false,4); if not explore then return nil end
        end
        local clearance = 20
        for _, p in ipairs(keeperParts) do
            local predicted = p.Position + p.AssemblyLinearVelocity * math.min(arrival, 0.4)
            clearance = math.min(clearance, (crossing - predicted).Magnitude - p.Size.Magnitude / 2)
        end
        local margin = crossbar and (barReach-barDistance) or math.min(half - math.abs(crossing.Z - goal.Z), crossing.Y - minY, maxY - crossing.Y)
        local cornerError = crossbar and barDistance or math.sqrt((math.abs(crossing.Z-goal.Z)-targetZ)^2 + (crossing.Y-targetY)^2)
        -- Measure lateral separation at the keeper's depth, before the goal line.
        local keeperGap, interceptionTime=clearance,arrival
        if keeperRoot then
            local prev=origin
            for i=1,crossingIndex do
                local pos=path[i]
                if prev.X<keeperPosition.X and pos.X>=keeperPosition.X then
                    local alpha=(keeperPosition.X-prev.X)/(pos.X-prev.X)
                    local intercept=prev:Lerp(pos,alpha)
                    local time=(i-1+alpha)/sampleRate
                    interceptionTime=time
                    local predicted=keeperPosition+keeperVelocity*math.min(time,0.4)
                    keeperGap=math.sqrt((intercept.Z-predicted.Z)^2+(intercept.Y-predicted.Y)^2)
                    break
                end
                prev=pos
            end
        end
        -- Favor upper corners with a deliberate buffer inside the frame, not the post itself.
        local score = clearance*0.5 + keeperGap*0.8 + math.min(margin,1.5)*2
            + 12/(arrival+0.2) + goalSpeed*0.08 - shot.scatterDegrees*0.5 - cornerError*6
            + math.min(wallClearance,2) - math.max(0,0.35-jumpClearance)*6
        if not advanced then
            -- Easy: use the earlier, simpler inside-foot curve over the wall,
            -- favor a shorter flight, and avoid excessive power/scatter.
            score += (shot.mode=="InsideCurled" and 5 or 0) + 8/(arrival+0.2)
                - math.max(0,input.power-0.75)*20
        end
        if advanced then
            -- Reach is a conservative risk estimate, not the server's hidden save logic.
            local learned=motion.keepers[difficulty]
            local reach=0
            if learned and learned.travel then
                for bin=1,math.min(60,math.ceil(interceptionTime*20)) do reach=math.max(reach,learned.travel[bin] or 0) end
            end
            local pressure = hard and 1.5 or 1
            score += keeperGap*pressure*2 + goalSpeed*0.12*pressure + 15*pressure/(arrival+0.15)
                - math.max(0,reach+3-keeperGap)*pressure*4
            -- Measure final-flight curvature instead of total launch deviation.
            local lateIndex = math.clamp(math.floor(crossingIndex*0.65),2,#path)
            local latePos, earlierPos = path[lateIndex], path[lateIndex-1]
            local tangent = latePos-earlierPos
            if tangent.X > 0.001 and latePos.X < config.Goal.X then
                local projectedZ = latePos.Z+tangent.Z*(config.Goal.X-latePos.X)/tangent.X
                score += math.min(math.abs(crossing.Z-projectedZ),6)*pressure*0.8
            end
        end
        -- Learn a conservative reach envelope from actual movement on this difficulty.
        if keeperProfile and keeperProfile.samples>=2 then
            local observedReach=0
            for bin=1,math.min(60,math.ceil(interceptionTime*20)) do
                observedReach=math.max(observedReach,keeperProfile.travel[tostring(bin)] or 0)
            end
            score-=math.max(0,observedReach+3-keeperGap)*4
        end
        if crossbar then
            score=100-barDistance*90 + math.min(wallClearance,2)*2
                - shot.scatterDegrees*2 - math.max(0,0.35-jumpClearance)*3 + 5/(arrival+0.2)
        end
        local empirical=observedPreference(input)
        score += empirical
        score -= penalty
        return score, crossing, {corner=corner, curved=curved, arrival=arrival, mode=shot.mode,
            curve=shot.curve,clearance=clearance, goalSpeed=goalSpeed, wallClearance=wallClearance,jumpClearance=jumpClearance,valid=valid}
    end
    local candidates = {}
    local count = 0
    local function addCandidate(input)
        local score, crossing, info = evaluate(input, 0, true)
        if score then table.insert(candidates, {input=input, score=score, crossing=crossing, info=info}) end
        return score
    end
    if true then
        local hints={{leg=u[11],aimYaw=u[7],contactX=u[8],contactY=u[9]}}
        for _, successful in ipairs(motion.successfulShots or {}) do
            if typeof(successful.origin)=="Vector3" and (successful.origin-origin).Magnitude<25 then table.insert(hints,successful) end
        end
        local savedHints=0
        local rootPart=character and character:FindFirstChild("HumanoidRootPart")
        for _,rec in pairs(positionConfig.records) do
            if rec.success and rec.context==context and rec.objective==objective and rec.origin and statsByLeg[rec.leg] then
                local oldOrigin=Vector3.new(rec.origin.x,rec.origin.y,rec.origin.z)
                local compatible=(oldOrigin-origin).Magnitude<=2
                for _,key in ipairs({"ACC","PRE","POW","CUR"}) do if not rec.stats or rec.stats[key]~=statsByLeg[rec.leg][key] then compatible=false end end
                if rec.playerPosition and rootPart then
                    local p=rec.playerPosition
                    compatible=compatible and (rootPart.Position-Vector3.new(p.x,p.y,p.z)).Magnitude<=3
                end
                if compatible then table.insert(hints,rec);savedHints+=1 end
            end
        end
        print("TFC_POSITION_CONFIG_HINTS "..savedHints)
        local imported=0
        for _,rec in ipairs(telemetrySnapshot.records or {}) do
            if (not crossbar and rec.outcome=="goal" or crossbar and (rec.contacts and rec.contacts.Crossbar or rec.gameObjective=="Crossbar" and rec.outcome=="goal")) and (rec.objective or "Normal")==objective and rec.origin and rec.stats and statsByLeg[rec.leg] then
                local priorOrigin=Vector3.new(rec.origin.x,rec.origin.y,rec.origin.z)
                local statsMatch=true
                for _,key in ipairs({"ACC","PRE","POW","CUR"}) do
                    if rec.stats[key]~=statsByLeg[rec.leg][key] then statsMatch=false end
                end
                local sameWind=not (rec.wind and rec.wind.windEnabled) and not windConfiguration.windEnabled
                if statsMatch and sameWind and (priorOrigin-origin).Magnitude<15 then
                    table.insert(hints,{origin=priorOrigin,leg=rec.leg,power=rec.power,aimYaw=rec.aimYaw,
                        contactX=rec.contactX,contactY=rec.contactY})
                    imported+=1
                end
            end
        end
        print("TFC_CONFIRMED_GOAL_HINTS "..imported)
        for _, hint in ipairs(hints) do
            local exact={ballPosition=origin,goalCenter=goal,leg=hint.leg,stats=statsByLeg[hint.leg],perks=perks,
                power=math.clamp(hint.power or u[6],MIN_POWER,MAX_POWER),aimYaw=hint.aimYaw,
                contactX=hint.contactX,contactY=hint.contactY,precision=precision}
            addCandidate(exact)
            for _, yawOffset in ipairs({-2,-1,0,1,2}) do
                for pi=130,146,4 do
                    local input={ballPosition=origin,goalCenter=goal,leg=hint.leg,stats=statsByLeg[hint.leg],perks=perks,
                        power=pi/200,aimYaw=math.clamp(hint.aimYaw+yawOffset,-config.Aim.MaxYaw,config.Aim.MaxYaw),
                        contactX=hint.contactX,contactY=hint.contactY,precision=precision}
                    addCandidate(input)
                end
                task.wait()
            end
        end
    end
    for _, testLeg in ipairs({"Right","Left"}) do
    for yaw = -config.Aim.MaxYaw, config.Aim.MaxYaw, 3 do
        for pi = 130, 146, 4 do
            for _, cx in ipairs({-0.9,-0.65,-0.4,-0.2,0,0.2,0.4,0.65,0.9}) do
                for _, cy in ipairs({-0.9,-0.65,-0.4,-0.2,0,0.2,0.45,0.7}) do
                    local input = {ballPosition=origin, goalCenter=goal, leg=testLeg, stats=statsByLeg[testLeg], perks=perks,
                        power=pi/200, aimYaw=yaw, contactX=cx, contactY=cy, precision=precision}
                    addCandidate(input)
                    count += 1
                    if count % 400 == 0 then
                        setStatus("working", difficulty..": searching curves above jumping defenders... " .. count .. " combinations")
                        task.wait()
                        assert(gui.Parent, "Solver closed")
                    end
                end
            end
        end
    end
    end
    table.sort(candidates, function(a,b) return a.score > b.score end)
    -- Keep promising shots on both sides so one corner cannot crowd out the other.
    local starts, leftCount, rightCount = {}, 0, 0
    local startLimit = advanced and (hard and 24 or 18) or 12
    for _, c in ipairs(candidates) do
        if c.crossing.Z < goal.Z and leftCount < startLimit then
            table.insert(starts,c); leftCount += 1
        elseif c.crossing.Z >= goal.Z and rightCount < startLimit then
            table.insert(starts,c); rightCount += 1
        end
        if leftCount==startLimit and rightCount==startLimit then break end
    end
    -- Refine yaw, power and contact around good coarse solutions.
    for _, c in ipairs(starts) do
        local current, currentScore = c.input, c.score
        for round = 1, 8 do
            local scale = 0.55^(round-1)
            local steps = {aimYaw=1.5*scale, power=0.02*scale, contactX=0.1*scale, contactY=0.1*scale}
            for _, key in ipairs({"aimYaw","power","contactX","contactY"}) do
                for _, sign in ipairs({-1,1}) do
                    local trial = table.clone(current)
                    trial[key] += steps[key]*sign
                    trial.aimYaw = math.clamp(trial.aimYaw,-config.Aim.MaxYaw,config.Aim.MaxYaw)
                    trial.power = math.clamp(trial.power,MIN_POWER,MAX_POWER)
                    trial.contactX, trial.contactY = config.ClampContact(trial.contactX,trial.contactY)
                    local score = addCandidate(trial)
                    if score and score > currentScore then current, currentScore = trial, score end
                end
            end
            task.wait()
        end
    end
    table.sort(candidates, function(a,b) return a.score > b.score end)
    local finalists, used, landingCells = {}, {}, {}
    local finalistLimit = advanced and (hard and 48 or 36) or 32
    leftCount, rightCount = 0, 0
    for _, c in ipairs(candidates) do
        local key = string.format("%s/%.2f/%.3f/%.3f/%.3f",c.input.leg,c.input.aimYaw,c.input.power,c.input.contactX,c.input.contactY)
        local cell = c.input.leg.."/"..math.floor(c.crossing.Y*2).."/"..math.floor(c.crossing.Z*2)
        local left = c.crossing.Z < goal.Z
        if c.info.valid and not used[key] and (landingCells[cell] or 0)<2
            and ((left and leftCount<finalistLimit) or (not left and rightCount<finalistLimit)) then
            used[key] = true
            landingCells[cell]=(landingCells[cell] or 0)+1
            local nominalScore, nominalCrossing, nominalInfo = evaluate(c.input,0,false)
            if nominalScore then
                c.score,c.crossing,c.info=nominalScore,nominalCrossing,nominalInfo
                table.insert(finalists,c)
            end
            if nominalScore then
                if left then leftCount += 1 else rightCount += 1 end
            end
        end
        if leftCount==finalistLimit and rightCount==finalistLimit then break end
    end
    local ranked = {}
    for i,c in ipairs(finalists) do
        local hits,corners,jumpHits,scores=0,0,0,{}
        for trial=1,scatterSamples do
            local score,_,info=evaluate(c.input,trial*7919+104729)
            if score then
                hits+=1
                if info.corner then corners+=1 end
                if info.jumpClearance>=0.35 then jumpHits+=1 end
                table.insert(scores,score)
            end
        end
        if hits>0 then
            table.sort(scores)
            c.hits,c.corners,c.jumpHits,c.samples=hits,corners,jumpHits,scatterSamples
            c.lower=reliabilityLower(hits,scatterSamples)
            c.rank=c.lower*240 + reliabilityLower(jumpHits,scatterSamples)*30
                + scores[math.max(1,math.floor(#scores*0.2))] + corners/scatterSamples*12
            table.insert(ranked,c)
        end
        if i%4==0 then
            setStatus("working","Ranking opposite upper-corner shots: "..i.."/"..#finalists)
            task.wait()
        end
    end
    assert(#ranked>0,crossbar and "No crossbar-contact trajectory cleared defenders at 65-73%; setup may be unreachable" or "No on-target upper-corner trajectory cleared the current defenders at 65-73%; reposition the ball")
    -- Reliability determines the order; jump-risk and corner quality break ties.
    local function order(a,b)
        local aReliable,bReliable=a.lower>=reliabilityTarget,b.lower>=reliabilityTarget
        if aReliable~=bReliable then return aReliable end
        -- Above the geometric threshold, use the combined score so an extra
        -- scattered hit cannot erase better jump clearance or observed results.
        if aReliable then
            if a.rank~=b.rank then return a.rank>b.rank end
            return a.lower>b.lower
        end
        if a.lower~=b.lower then return a.lower>b.lower end
        return a.rank>b.rank
    end
    table.sort(ranked,order)
    local validationSamples = hard and 192 or 128
    local validated={}
    -- Avoid counting nearly identical optimizer steps as separate fallback shots.
    local function distinct(a,b)
        return a.leg~=b.leg or math.abs(a.aimYaw-b.aimYaw)>0.4
            or math.abs(a.power-b.power)>0.008 or math.abs(a.contactX-b.contactX)>0.025
            or math.abs(a.contactY-b.contactY)>0.025
    end
    for _,c in ipairs(ranked) do
        local duplicate=false
        for _,v in ipairs(validated) do
            if not distinct(c.input,v.input) then duplicate=true; break end
        end
        if not duplicate then
            local hits,corners,jumpHits,scoreTotal=0,0,0,0
            for trial=1,validationSamples do
                local score,_,info=evaluate(c.input,10000019+trial*104729)
                if score then
                    hits+=1; scoreTotal+=score
                    if info.corner then corners+=1 end
                    if info.jumpClearance>=0.35 then jumpHits+=1 end
                end
            end
            c.hits,c.corners,c.jumpHits,c.samples=hits,corners,jumpHits,validationSamples
            c.lower=reliabilityLower(hits,validationSamples)
            c.rank=c.lower*240+reliabilityLower(jumpHits,validationSamples)*30
                +(hits>0 and scoreTotal/hits or -1000)+corners/validationSamples*12
            if hits>0 then table.insert(validated,c) end
            print(string.format("TFC_VALIDATED_CANDIDATE clear=%d/%d jumpReserveClear=%d/%d lower95=%.3f power=%.3f",
                hits,validationSamples,jumpHits,validationSamples,c.lower,c.input.power))
            if #validated>=4 then break end
        end
    end
    assert(#validated>0,"No candidate passed any fresh trajectory trials; ball/setup may have changed")
    table.sort(validated,order)
    local chosen,fallback
    for _,c in ipairs(validated) do
        if c.lower>=reliabilityTarget then chosen=c;break end
    end
    if not chosen then
        chosen=validated[2] or validated[1]
        fallback=true
        warn("TFC_FALLBACK "..(#validated>=2 and "second-most reliable distinct shot" or "only viable shot")..
            "; simulated reliability below target, scoring remains uncertain")
    end
    local best=table.clone(chosen.input)
    local bias,pastHits,pastMisses=observedPreference(best)
    print(string.format("TFC_POSITION_SELECTION priorSuccesses=%d priorMisses=%d empiricalBias=%.1f",pastHits,pastMisses,bias))
    local bestInfo={hits=chosen.hits,corners=chosen.corners,samples=chosen.samples,
        crossing=chosen.crossing,curve=chosen.info.curve,mode=chosen.info.mode,arrival=chosen.info.arrival,
        goalSpeed=chosen.info.goalSpeed,wallClearance=chosen.info.wallClearance,
        keeperPosition=keeperPosition,keeperRoot=keeperRoot,preferredSide=preferredSide,
        difficulty=difficulty,context=context,objective=objective,fallback=fallback,lower=chosen.lower,jumpHits=chosen.jumpHits}
    print(string.format("TFC_SELECTION finalists=%d validated=%d fallback=%s clear=%d/%d power=%.3f",
        #finalists,#validated,tostring(fallback==true),chosen.hits,chosen.samples,best.power))
    best.seed = nil
    bestInfo.origin, bestInfo.fingerprint = origin, fingerprint
    if keeperRoot then
        assert(keeperRoot.Parent and (keeperRoot.Position-keeperPosition).Magnitude < 1.5,
            "Keeper moved during search; recalculate the opposite-side target")
    end
    assert(setupFingerprint() == fingerprint, "Stats, wind, perks or wall changed during search; retry")
    assert((ball.Position-origin).Magnitude < 0.2, "Ball moved during search; retry")
    return best, bestInfo
end

local function run(fire)
    if busy then return end
    busy = true
    button.Text = "Working..."
    setButtonColor(button, Color3.fromRGB(180, 130, 45))
    setStatus("working", "Searching for the best available shot...")
    local ok, err = pcall(function()
        local best,info
        for attempt=1,3 do
            local solved,a,b=pcall(solve)
            if solved then best,info=a,b;break end
            local changed=tostring(a):find("Stats, wind, perks") or tostring(a):find("Setup changed while sampling")
            if not changed or attempt==3 then error(a) end
            setStatus("working","Refreshing changed stats/setup and recalculating...")
            task.wait(0.15)
        end
        local side = info.crossing.Z < config.Goal.CenterZ and "left" or "right"
        statusLabel.Text = string.format("%s keeper | %s corner | %s foot | Power %.0f%%\nAim %.1f° | Contact (%.2f, %.2f) | %d/%d simulated clear shots\n%s",
            info.difficulty,side,best.leg,best.power*100,best.aimYaw,best.contactX,best.contactY,info.hits,info.samples,
            string.format("Jump reserve clear %d/%d | %s",info.jumpHits,info.samples,
                fire and "Taking selected shot..." or "Preview; scoring is uncertain."))
        if info.objective=="Crossbar" then statusLabel.Text="CROSSBAR | Power "..string.format("%.1f%%",best.power*100).." | "..info.hits.."/"..info.samples.." simulated contacts\nAim "..string.format("%.2f",best.aimYaw).." | "..(fire and "Taking shot..." or "Preview") end
        if info.fallback then statusLabel.Text="FALLBACK #2 | "..statusLabel.Text end
        setStatus(info.fallback and "fallback" or "success", statusLabel.Text)
        print("TFC_SOLVER_RESULT " .. statusLabel.Text)
        print(string.format("TFC_CORNER_CHECK goalCrossing=(%.2f, %.2f, %.2f) upperCornerSamples=%d/%d mode=%s flightTime=%.3fs goalSpeed=%.1fstuds/s currentWallClearance=%.2fstuds keeper=%s",
            info.crossing.X, info.crossing.Y, info.crossing.Z, info.corners,info.samples, info.mode,
            info.arrival,info.goalSpeed,info.wallClearance,tostring(info.keeperPosition)))
        if not fire then return end
        local u = validateClient()
        assert(u[1] == "kick" and not u[2] and not u[3], "Kick phase changed; retry")
        if best.leg~=u[11] then
            assert(type(env.setLeg)=="function", "Foot selection unavailable")
            env.setLeg(best.leg)
        end
        debug.setupvalue(env.commitQueuedShot, 7, best.aimYaw)
        debug.setupvalue(env.commitQueuedShot, 8, best.contactX)
        debug.setupvalue(env.commitQueuedShot, 9, best.contactY)
        env.updateModeLabel()
        local phase, threshold = waitForGreen()
        if info.keeperRoot and info.keeperRoot.Parent then
            assert((info.keeperRoot.Position-info.keeperPosition).Magnitude<1.5,
                "Keeper moved during the search; press Solve & Shoot to recalculate")
            if info.preferredSide then
                assert((info.keeperRoot.Position.Z-config.Goal.CenterZ)*info.preferredSide<=0,
                    "Keeper changed sides; recalculate the farther-side target")
            end
        end
        assert(gui.Parent and controlsShot(), "Shot no longer belongs to this player")
        local currentBall = workspace:FindFirstChild("Ball")
        assert(currentBall and (currentBall.Position-info.origin).Magnitude < 0.2
            and currentBall.AssemblyLinearVelocity.Magnitude < 3, "Ball changed before release; retry")
        refreshPlayerStats()
        assert(setupFingerprint() == info.fingerprint, "Shot environment/stats changed before release; recalculate")
        assert(best.power >= MIN_POWER and best.power <= MAX_POWER, "Power outside 65-73% range")
        local releaseState = debug.getupvalues(env.releaseShot)
        assert(releaseState[1] == "kick" and not releaseState[2]
            and not releaseState[3] and not releaseState[4], "Shot state changed; retry")
        -- Once charging starts, release before any timing assertions can throw.
        -- releaseShot: [2]=charging, [3]=queued, [5]=charge start,
        -- [6]=queued power, [7]=current held power, [8]=queued precision.
        local telemetry=player.PlayerGui:FindFirstChild("TFCShotTelemetry")
        local setIntent=telemetry and telemetry:FindFirstChild("SetIntent")
        if setIntent then
            local intent={at=os.clock(),version=SCRIPT_VERSION,objective=info.objective,context=info.context,curve=info.curve,power=best.power,aimYaw=best.aimYaw,
                hits=info.hits,samples=info.samples,jumpHits=info.jumpHits,fallback=info.fallback,
                arrival=info.arrival,target={x=info.crossing.X,y=info.crossing.Y,z=info.crossing.Z}}
            setIntent:Invoke(game:GetService("HttpService"):JSONEncode(intent))
        end
        assert(not autoRunning or autoEnabled,"Auto Play paused before release")
        -- The live input loop can update these while waitForGreen yields.
        -- Restore the selected shot immediately before charging, without yielding.
        debug.setupvalue(env.commitQueuedShot, 7, best.aimYaw)
        debug.setupvalue(env.commitQueuedShot, 8, best.contactX)
        debug.setupvalue(env.commitQueuedShot, 9, best.contactY)
        env.beginCharge()
        releaseState = debug.getupvalues(env.releaseShot)
        assert(releaseState[2] == true,
            "Charging was refused: wait for your turn and close any perk selection")
        debug.setupvalue(env.releaseShot, 5, os.clock())
        debug.setupvalue(env.releaseShot, 7, best.power)
        env.releaseShot()
        local queued = debug.getupvalues(env.releaseShot)
        assert(not queued[2] and queued[3], "Release did not queue the shot")
        -- No yield between release and exact-power verification.
        debug.setupvalue(env.commitQueuedShot, 6, best.power)
        debug.setupvalue(env.commitQueuedShot, 7, best.aimYaw)
        debug.setupvalue(env.commitQueuedShot, 8, best.contactX)
        debug.setupvalue(env.commitQueuedShot, 9, best.contactY)
        local finalInput=debug.getupvalues(env.commitQueuedShot)
        print(string.format("TFC_SHOT_INPUT_VERIFIED yaw=%.4f contact=(%.4f,%.4f) selected=(%.4f,%.4f,%.4f)",
            finalInput[7],finalInput[8],finalInput[9],best.aimYaw,best.contactX,best.contactY))
        local capturedPrecision = queued[8]
        local queuedPower = debug.getupvalues(env.commitQueuedShot)[6]
        print(string.format("TFC_POWER_VERIFIED selected=%.4f queued=%.4f charging=%s precision=%.4f",
            best.power,queuedPower,tostring(queued[2]),capturedPrecision))
        if capturedPrecision < 0.999 then
            warn("TFC_TIMING: precision below ideal; shot was released at capped power")
        end
        task.wait(3.2)
        setStatus("success", "Shot taken. Reset/select your next freekick, then press Solve & Shoot.\nKeeper movement and random scatter can still cause misses.")
    end)
    if not ok then
        if getgenv().TFCMonitor then getgenv().TFCMonitor.intent=nil end
        setStatus("error", tostring(err))
        warn("TFC_SOLVER " .. tostring(err))
    end
    busy = false
    button.Text = "Solve & Shoot"
    setButtonColor(button, Color3.fromRGB(55, 120, 235))
    return ok,err
end
button.Activated:Connect(function() run(true) end)
getgenv().TFCShotSolverAPI = {version=SCRIPT_VERSION, isBusy=function() return busy end, preview=function() run(false) end, shoot=function() run(true) end}
print("TFC_SOLVER_READY v"..SCRIPT_VERSION.." | power 65-73% | opposite upper corner | live stats | second-shot fallback | inspected place "..INSPECTED_PLACE_VERSION)
-- Loaded directly; use Solve & Shoot when your kick is ready.

-- Auto Play waits for ownership, loaded ratings, and a stationary ball.
do
    local storage=player.PlayerGui:FindFirstChild("TFCShotTelemetry")
    if storage and storage:GetAttribute("AutoPlayEnabled")~=nil then
        autoEnabled=storage:GetAttribute("AutoPlayEnabled")
    end
    skipButton.Size=UDim2.new(0.5,-4,0,38)
    local autoButton=Instance.new("TextButton")
    autoButton.Name="TFCAutoPlay"
    autoButton.Size=UDim2.new(0.5,-4,0,38)
    autoButton.Position=UDim2.new(0.5,4,0,38)
    autoButton.Parent=controlsPage
    styleButton(autoButton,Color3.fromRGB(45,105,195))
    local function draw()
        autoButton.Text=autoEnabled and "Auto Play: ON" or "Auto Play: OFF"
        setButtonColor(autoButton,autoEnabled and Color3.fromRGB(45,105,195) or Color3.fromRGB(65,65,70))
        local s=player.PlayerGui:FindFirstChild("TFCShotTelemetry")
        if s then s:SetAttribute("AutoPlayEnabled",autoEnabled) end
    end
    local toggle=autoButton.Activated:Connect(function() autoEnabled=not autoEnabled;getgenv().TFCAutomationEnabled=autoEnabled;draw() end)
    local elapsed,lastKey,attempts,finished,nextAttempt=0,nil,0,false,0
    local heartbeat=RunService.Heartbeat:Connect(function(dt)
        elapsed+=dt;if elapsed<0.2 then return end;elapsed=0
        if not gui.Parent then return end
        local phase=player:GetAttribute("FootballFreekickPhase")
        if phase~="kick" or not controlsShot() then
            lastKey=nil;attempts=0;finished=false
            return
        end
        if not autoEnabled or autoRunning or busy or finished or os.clock()<nextAttempt then return end
        local ball=workspace:FindFirstChild("Ball")
        if not ball or ball.AssemblyLinearVelocity.Magnitude>=3 then return end
        local ratingsReady=true
        for _,foot in ipairs({"Right","Left"}) do
            for _,key in ipairs({"ACC","PRE","POW","CUR"}) do
                if type(player:GetAttribute("FootballStat_"..foot.."_"..key))~="number" then ratingsReady=false end
            end
        end
        if not ratingsReady then return end
        local u=debug.getupvalues(env.commitQueuedShot)
        local r=debug.getupvalues(env.releaseShot)
        if u[2] or u[3] or r[2] or r[3] or r[4] then return end
        local key=string.format("%.1f/%.1f",ball.Position.X,ball.Position.Z)
        for _,foot in ipairs({"Right","Left"}) do
            for _,stat in ipairs({"ACC","PRE","POW","CUR"}) do
                key=key.."/"..tostring(player:GetAttribute("FootballStat_"..foot.."_"..stat))
            end
        end
        if key~=lastKey then lastKey=key;attempts=0;finished=false;nextAttempt=os.clock()+0.3;return end
        if attempts>=2 then return end
        autoRunning=true;attempts+=1
        task.spawn(function()
            print("TFC_AUTO_PLAY_START attempt="..attempts)
            local ok,success,err=pcall(run,true)
            autoRunning=false
            if ok and success then finished=true
            else
                nextAttempt=os.clock()+1
                if attempts>=2 and autoEnabled then
                    setStatus("error","Auto Play couldn't complete this kick after two attempts. Reposition/reset, or use Solve & Shoot.\n"..tostring(ok and err or success))
                end
            end
        end)
    end)
    gui.Destroying:Connect(function()
        autoEnabled=false;heartbeat:Disconnect();toggle:Disconnect()
    end)
    getgenv().TFCShotSolverAPI.setAutoPlay=function(enabled) autoEnabled=enabled==true;draw() end
    draw()
    print("TFC_AUTO_PLAY_READY "..autoButton.Text.." | power 65-73%")
end

-- Auto Skip is optional; missing presentation handlers must not break the solver.
local skipOk, skipError = pcall(function()
    local shared = getgenv()
    if shared.TFCAutoSkipCleanup then shared.TFCAutoSkipCleanup() end
    local player = game:GetService("Players").LocalPlayer
    local env = getsenv(player.PlayerScripts.FootballFreekickClient)
    local gui = player.PlayerGui:FindFirstChild("TFCShotSolver")
    assert(gui, "Load the shot solver before Auto Skip")
    local panel = gui:FindFirstChild("MainPanel")
    assert(panel, "Solver panel unavailable")
    local controls = panel:FindFirstChild("Content") and panel.Content:FindFirstChild("ControlsPage")
    assert(controls, "Controls page unavailable")
    local solveButton = panel:FindFirstChild("SolveButton")
    local skipButton = controls:FindFirstChild("TFCAutoSkip")
    assert(solveButton, "Solve button unavailable")
    assert(skipButton, "Auto Skip button unavailable")
    if shared.TFCAutoSkipEnabled == nil then shared.TFCAutoSkipEnabled = true end
    local function draw()
        local enabled = shared.TFCAutoSkipEnabled
        skipButton.Text = enabled and "Auto Skip: ON" or "Auto Skip: OFF"
        setButtonColor(skipButton, enabled and Color3.fromRGB(35,125,75) or Color3.fromRGB(65,65,70))
    end
    local replay = debug.getupvalues(env.beginCharge)[13]
    assert(type(replay) == "table" and type(replay.skipHolding) == "boolean",
        "Skip state changed; Auto Skip needs an update")
    for _, name in ipairs({"releasePresentationSkipHold","requestMatchPresentationSkip",
        "setMatchPresentationHold","presentationStageVoted","localControlsCurrentShot"}) do
        assert(type(env[name]) == "function", "Skip handler unavailable: "..name)
    end
    local heldStage, lastStage, clicked
    local function release()
        if heldStage then
            local old = heldStage
            heldStage = nil
            env.releasePresentationSkipHold(old)
        end
    end
    local function step()
        local phase = player:GetAttribute("FootballFreekickPhase")
        local stage = phase == "celebrate" and "Celebration" or (phase == "replay" and "Replay" or nil)
        if stage ~= lastStage then
            release()
            lastStage, clicked = stage, false
        end
        if not shared.TFCAutoSkipEnabled or not stage then release(); return end
        if env.matchPresentationSkipPending or env.presentationStageVoted(stage) then
            release()
            return
        end
        if stage == "Replay" and replay.replayKind == "almost" and env.localControlsCurrentShot() then
            release()
            if not clicked then
                env.requestMatchPresentationSkip(stage)
                clicked = true
                print("TFC_AUTO_SKIP click Replay")
            end
            return
        end
        -- Keep the normal hold active without resetting its elapsed progress.
        -- The game's update loop requests the skip when its hold timer finishes.
        if not replay.skipHolding then
            replay.skipHolding = true
            replay.skipHoldStarted = os.clock()
            env.setMatchPresentationHold(stage,true)
            heldStage = stage
            print("TFC_AUTO_SKIP hold "..stage)
        end
    end
    local heartbeat, destroyConnection, toggleConnection
    local cleaned = false
    local cleanup
    cleanup = function()
        if cleaned then return end
        cleaned = true
        if heartbeat then heartbeat:Disconnect() end
        if destroyConnection then destroyConnection:Disconnect() end
        if toggleConnection then toggleConnection:Disconnect() end
        pcall(release)
        skipButton:Destroy()
        if shared.TFCAutoSkipCleanup == cleanup then shared.TFCAutoSkipCleanup = nil end
    end
    toggleConnection = skipButton.Activated:Connect(function()
        shared.TFCAutoSkipEnabled = not shared.TFCAutoSkipEnabled
        if not shared.TFCAutoSkipEnabled then release() end
        draw()
    end)
    local elapsed = 0
    heartbeat = game:GetService("RunService").Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < 0.1 then return end
        elapsed = 0
        local ok,err = pcall(step)
        if not ok then
            shared.TFCAutoSkipEnabled = false
            pcall(release)
            draw()
            warn("TFC_AUTO_SKIP disabled: "..tostring(err))
        end
    end)
    destroyConnection = gui.Destroying:Connect(cleanup)
    shared.TFCAutoSkipCleanup = cleanup
    draw()
    print("TFC_AUTO_SKIP_READY "..skipButton.Text)
end)
if not skipOk then
    skipButton.Text = "Auto Skip: unavailable"
    warn("TFC_AUTO_SKIP unavailable: "..tostring(skipError))
end

-- Reinstall the persistent result collector on every script load.
do
-- Persistent observation only: does not aim, charge, shoot, or change ratings.
local player=game:GetService("Players").LocalPlayer
local root=game:GetService("ReplicatedStorage").FootballFreekick
local env=getsenv(player.PlayerScripts.FootballFreekickClient)
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local shared=getgenv()
if shared.TFCMonitor and shared.TFCMonitor.cleanup then shared.TFCMonitor.cleanup() end
local previous=player.PlayerGui:FindFirstChild("TFCShotTelemetry")
local saved
local savedAutoPlay
if previous then
    savedAutoPlay=previous:GetAttribute("AutoPlayEnabled")
    local json=previous:GetAttribute("SnapshotJSON")
    if json then local ok,data=pcall(HttpService.JSONDecode,HttpService,json);if ok then saved=data end end
    local stop=previous:FindFirstChild("Stop")
    if stop then stop:Fire() end
    previous:Destroy()
end
local storage=Instance.new("ScreenGui")
storage.Name="TFCShotTelemetry";storage.ResetOnSpawn=false;storage.Parent=player.PlayerGui
if savedAutoPlay~=nil then storage:SetAttribute("AutoPlayEnabled",savedAutoPlay) end
local monitor={records=saved and saved.records or {},nextId=0,startedAt=saved and saved.startedAt or os.time()}
monitor.keeperProfiles=saved and saved.keeperProfiles or {}
for _,rec in ipairs(monitor.records) do monitor.nextId=math.max(monitor.nextId,rec.id or 0) end
shared.TFCMonitor=monitor
monitor.connections={}
monitor.intent=nil
monitor.active=nil
local bySequence={}
for _,rec in ipairs(monitor.records) do
    bySequence[tostring(rec.sequence)]=rec
    if rec.outcome=="pending" then monitor.active=rec end
end
local function persist()
    if monitor.snapshot and storage.Parent then
        local snapshot=monitor.snapshot()
        storage:SetAttribute("SnapshotJSON",HttpService:JSONEncode(snapshot))
        storage:SetAttribute("Goals",snapshot.totals.goals)
        storage:SetAttribute("NonGoals",snapshot.totals.nonGoals)
        storage:SetAttribute("Pending",snapshot.totals.pending)
        local cache=getgenv().TFCPositionConfig
        if cache and cache.observe then cache.observe(monitor.records) end
    end
end
local function emit(kind,record)
    print("TFC_MONITOR_"..kind.." "..HttpService:JSONEncode(record))
    persist()
end
local function finish(rec,outcome,evidence)
    if not rec then return end
    if rec.outcome=="goal" and outcome~="goal" then return end
    if rec.outcome==outcome then return end
    rec.outcome=outcome;rec.evidence=evidence;rec.finishedAt=os.time()
    rec.duration=os.clock()-rec.clockStarted
    emit("RESULT",rec)
end
local function geometry(origin)
    local ball=workspace:FindFirstChild("Ball")
    local config=require(root.FreeKickConfig)
    local data={distance=(config.GoalCenter()-origin).Magnitude,ballRadius=config.BallRadius}
    local runtime=workspace:FindFirstChild("FreekickSystemRuntime")
    for _,obj in ipairs(runtime and runtime:GetChildren() or {}) do
        if obj:GetAttribute("SetupObjectKind")=="Goalkeeper" then
            local p=obj:FindFirstChild("HumanoidRootPart",true)
            if p then data.keeper={x=p.Position.X,y=p.Position.Y,z=p.Position.Z} end
            data.difficulty=obj:GetAttribute("KeeperDifficulty")
        end
    end
    return data
end
local function ownShot(data)
    local shooter=tonumber(data.shooterUserId) or player:GetAttribute("FootballMatchShooterUserId")
    return shooter==player.UserId
end
local function accepted(data)
    if not ownShot(data) then return end
    local key=tostring(data.shotSequence)
    local previous=bySequence[key]
    if previous and previous.outcome=="pending" then return end
    if monitor.active and monitor.active.outcome=="pending" then
        finish(monitor.active,"non_goal","next own shot accepted without prior goal confirmation")
    end
    monitor.nextId+=1
    local values=debug.getupvalues(env.commitQueuedShot)
    local origin=debug.getupvalues(env.beginCharge)[16]
    local ball=workspace:FindFirstChild("Ball")
    if typeof(origin)~="Vector3" then origin=ball and ball.Position or Vector3.zero end
    local intent=monitor.intent
    local solver=intent and os.clock()-intent.at<4
        and math.abs((values[6] or 0)-(intent.power or -1))<0.015
        and math.abs((values[7] or 0)-(intent.aimYaw or -100))<0.1
    local rec={id=monitor.nextId,sequence=data.shotSequence,outcome="pending",
        startedAt=os.time(),clockStarted=os.clock(),source=solver and "solver" or "manual_or_unattributed",
        version=solver and intent.version or "unattributed",objective=solver and intent.objective or player:GetAttribute("FootballSetupMode") or "Normal",leg=values[11],power=values[6],
        aimYaw=values[7],contactX=values[8],contactY=values[9],
        origin={x=origin.X,y=origin.Y,z=origin.Z},stats={},setup=geometry(origin),contacts={}}
    rec.gameObjective=player:GetAttribute("FootballSetupMode") or "Normal"
    rec.context=solver and intent.context or nil
    rec.curve=solver and intent.curve or nil
    local characterRoot=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if characterRoot then local p=characterRoot.Position;rec.playerPosition={x=p.X,y=p.Y,z=p.Z} end
    for _,k in ipairs({"ACC","PRE","POW","CUR"}) do
        rec.stats[k]=player:GetAttribute("FootballStat_"..tostring(rec.leg).."_"..k)
    end
    if solver then
        rec.predictedClear=intent.hits;rec.predictedSamples=intent.samples
        rec.predictedJumpClear=intent.jumpHits;rec.fallback=intent.fallback==true
        rec.predictedArrival=intent.arrival;rec.predictedTarget=intent.target
    end
    rec.wind=table.clone(env.kickWindConfiguration or {})
    table.insert(monitor.records,rec)
    bySequence[key]=rec;monitor.active=rec;monitor.intent=nil
    emit("ACCEPTED",rec)
end
local remote=root.Remotes.FreeKickRemote.OnClientEvent:Connect(function(event,data)
    if type(data)~="table" then return end
    if event=="ShotAccepted" then accepted(data);return end
    local rec=data.shotSequence and bySequence[tostring(data.shotSequence)] or nil
    if rec and data.shooterUserId and tonumber(data.shooterUserId)~=player.UserId then return end
    if event=="GoalConfirmed" then finish(rec,"goal","server GoalConfirmed")
    elseif event=="VARStatus" and data.decision=="GOAL" then finish(rec,"goal","server VAR GOAL")
    elseif event=="VARStatus" and data.decision=="NO GOAL" then
        if rec then rec.outcome="pending";finish(rec,"non_goal","server VAR NO GOAL") end
    elseif event=="OutOfPlay" then
        if rec then rec.outOfPlay=true;task.delay(2,function()
            if rec.outcome=="pending" then finish(rec,"non_goal","server OutOfPlay") end
        end) end
    elseif event=="ResetReady" then
        local active=monitor.active
        if active and active.outcome=="pending" then task.delay(2,function()
            if active.outcome=="pending" then finish(active,"non_goal","reset completed without goal confirmation") end
        end) end
    end
end)
table.insert(monitor.connections,remote)
local watchedBall,touchConnection
local function watchBall(ball)
    if ball==watchedBall then return end
    if touchConnection then touchConnection:Disconnect() end
    watchedBall=ball
    if not ball then return end
    touchConnection=ball.Touched:Connect(function(part)
        local rec=monitor.active
        if not rec or os.clock()-rec.clockStarted>10 then return end
        local obj=part
        while obj and obj~=workspace do
            local kind=obj:GetAttribute("SetupObjectKind")
            if kind=="Wall" or kind=="Goalkeeper" then
        rec.contacts[kind]=true
                if not rec.firstContact then rec.firstContact={kind=kind,elapsed=os.clock()-rec.clockStarted} end
                return
            end
            obj=obj.Parent
        end
        local name=string.lower(part:GetFullName())
        if name:find("topbar") or name:find("crossbar") then rec.contacts.Crossbar=true end
        if name:find("post") or name:find("crossbar") or name:find("topbar") then rec.contacts.GoalFrame=true end
    end)
end
local elapsed=0
local persistElapsed=0
table.insert(monitor.connections,RunService.Heartbeat:Connect(function(dt)
    persistElapsed+=dt;if persistElapsed>=1 then persistElapsed=0;persist() end
    elapsed+=dt;if elapsed<0.1 then return end;elapsed=0
    watchBall(workspace:FindFirstChild("Ball"))
    local rec=monitor.active
    if not rec or rec.outcome~="pending" then return end
    local age=os.clock()-rec.clockStarted
    if age<3 and rec.setup.keeper then
        local runtime=workspace:FindFirstChild("FreekickSystemRuntime")
        for _,obj in ipairs(runtime and runtime:GetChildren() or {}) do
            if obj:GetAttribute("SetupObjectKind")=="Goalkeeper" then
                local p=obj:FindFirstChild("HumanoidRootPart",true)
                if p then
                    local key=rec.setup.difficulty or "Unknown"
                    local profile=monitor.keeperProfiles[key] or {travel={},samples=0}
                    monitor.keeperProfiles[key]=profile
                    if not rec.keeperObserved then profile.samples+=1;rec.keeperObserved=true end
                    local bin=math.clamp(math.ceil(age*20),1,60)
                    local travel=math.abs(p.Position.Z-rec.setup.keeper.z)
                    profile.travel[tostring(bin)]=math.max(profile.travel[tostring(bin)] or 0,travel)
                    if travel>0.2 then profile.reaction=math.min(profile.reaction or age,age) end
                    profile.vertical=math.max(profile.vertical or 0,p.Position.Y-rec.setup.keeper.y)
                end
            end
        end
    end
    local phase=player:GetAttribute("FootballFreekickPhase")
    local replay=debug.getupvalues(env.beginCharge)[13]
    if phase=="replay" and type(replay)=="table" and replay.replayKind=="almost" and not rec.closing then
        rec.closing=true
        task.delay(2,function()
            if rec.outcome=="pending" then finish(rec,"non_goal","completed almost replay without goal confirmation") end
        end)
    end
    if os.clock()-rec.clockStarted>45 then finish(rec,"unknown","no terminal outcome observed within 45 seconds") end
end))
monitor.snapshot=function()
    local totals={accepted=#monitor.records,goals=0,nonGoals=0,pending=0,unknown=0,versions={}}
    for _,r in ipairs(monitor.records) do
        local key=r.version
        local v=totals.versions[key] or {accepted=0,goals=0,nonGoals=0,pending=0,unknown=0,wallContacts=0,keeperContacts=0}
        totals.versions[key]=v;v.accepted+=1
        local field=({goal="goals",non_goal="nonGoals",pending="pending",unknown="unknown"})[r.outcome]
        if field then totals[field]+=1;v[field]+=1 end
        if r.contacts.Wall then v.wallContacts+=1 end
        if r.contacts.Goalkeeper then v.keeperContacts+=1 end
    end
    return {startedAt=monitor.startedAt,totals=totals,records=monitor.records,keeperProfiles=monitor.keeperProfiles}
end
monitor.cleanup=function()
    for _,c in ipairs(monitor.connections) do c:Disconnect() end
    if touchConnection then touchConnection:Disconnect() end
end
local stop=Instance.new("BindableEvent");stop.Name="Stop";stop.Parent=storage
stop.Event:Connect(monitor.cleanup)
local setIntent=Instance.new("BindableFunction");setIntent.Name="SetIntent";setIntent.Parent=storage
setIntent.OnInvoke=function(json)
    monitor.intent=HttpService:JSONDecode(json)
    return true
end
local snapshotFunction=Instance.new("BindableFunction");snapshotFunction.Name="Snapshot";snapshotFunction.Parent=storage
snapshotFunction.OnInvoke=function() return HttpService:JSONEncode(monitor.snapshot()) end
print("TFC_MONITOR_READY goals/non-goals/pending/unknown tracked from this point")
emit("SNAPSHOT",monitor.snapshot())

end

]====]
if not game:IsLoaded() then game.Loaded:Wait() end
local Players=game:GetService("Players")
local player=Players.LocalPlayer or Players.PlayerAdded:Wait()
local shared=getgenv()
local previous=shared.TFCAutomationController
if previous and previous.isRunning and previous.isRunning() and previous.version>="1.14" then return end
if previous then previous.stop() end
local running=true
local controller={version="1.14",stop=function() running=false end,isRunning=function() return running end}
shared.TFCAutomationController=controller
if shared.TFCAutomationEnabled==nil then shared.TFCAutomationEnabled=true end
local pg=player:WaitForChild("PlayerGui")
local old=pg:FindFirstChild("TFCFullAutomation");if old then old:Destroy() end
local ui=Instance.new("ScreenGui");ui.Name="TFCFullAutomation";ui.ResetOnSpawn=false;ui.Parent=pg
local toggle=Instance.new("TextButton");toggle.Size=UDim2.fromOffset(220,32);toggle.Position=UDim2.new(0,12,1,-44)
toggle.BackgroundColor3=Color3.fromRGB(32,65,110);toggle.TextColor3=Color3.new(1,1,1);toggle.TextSize=14;toggle.Parent=ui
toggle.Activated:Connect(function()
 shared.TFCAutomationEnabled=not shared.TFCAutomationEnabled
 local api=shared.TFCShotSolverAPI;if api and api.setAutoPlay then api.setAutoPlay(shared.TFCAutomationEnabled) end
end)
local function visible(x)
 while x and x~=pg do
  if x:IsA("GuiObject") and not x.Visible then return false end
  if x:IsA("ScreenGui") and not x.Enabled then return false end
  x=x.Parent
 end
 return x==pg
end
local function click(button)
 if not visible(button) or not button.Active then return false end
 if type(firesignal)=="function" then firesignal(button.Activated);return true end
 if type(getconnections)=="function" then
  local fired=false
  for _,c in ipairs(getconnections(button.Activated)) do if c.Enabled~=false and c.Function then task.spawn(c.Function);fired=true end end
  return fired
 end
 return false
end
local function textOf(x)
 local t=x.Name.." "..(x:IsA("TextButton") and x.Text or "")
 for _,d in ipairs(x:GetDescendants()) do if d:IsA("TextLabel") then t=t.." "..d.Text end end
 return t:lower():gsub("%s+", " ")
end
local lastAction,nextAction,installAfter=nil,0,0
local function report(action)
 if action~=lastAction then print("TFC_FLOW "..action);lastAction=action end
end
local function queueContinuation()
 local queue=queue_on_teleport or queueonteleport
 if type(queue)~="function" or not shared.TFCAutomationBundle then warn("TFC_FLOW teleport queue unavailable; autoexec must restart controller");return end
 local source="getgenv().TFCAutomationEnabled="..tostring(shared.TFCAutomationEnabled)..";local bundle="..string.format("%q",shared.TFCAutomationBundle)..";getgenv().TFCAutomationBundle=bundle;local f,e=loadstring(bundle);assert(f,e);f()"
 local ok,e=pcall(queue,source);if not ok then warn("TFC_FLOW queue error "..tostring(e)) end
end
-- Queue at startup: executor may detach before a teleport event is delivered.
queueContinuation()
local teleport=player.OnTeleport:Connect(function(state)
 if state==Enum.TeleportState.Started then print("TFC_FLOW teleport starting") end
end)
task.spawn(function()
 while running do
  toggle.Text=shared.TFCAutomationEnabled and "Full automation: ON | v1.14" or "Full automation: OFF | v1.14"
  local ok,err=pcall(function()
   if not shared.TFCAutomationEnabled then report("paused");return end
   local scriptObject=player.PlayerScripts:FindFirstChild("FootballFreekickClient")
   local env
   if scriptObject then local success,value=pcall(getsenv,scriptObject);if success then env=value end end
   if env and type(env.beginCharge)=="function" and type(env.releaseShot)=="function" then
    local api=shared.TFCShotSolverAPI
    local solverGui=pg:FindFirstChild("TFCShotSolver")
    if (not api or api.version~="1.14" or not solverGui) and os.clock()>installAfter and player:GetAttribute("FootballFreekickPhase")~="setup" and player:GetAttribute("FootballFreekickPhase")~="select" then
     if api and api.isBusy and api.isBusy() then report("waiting for current calculation");return end
     local phase=player:GetAttribute("FootballFreekickPhase")
     local ball=workspace:FindFirstChild("Ball")
     if ball and ball.AssemblyLinearVelocity.Magnitude>3 and phase=="kick" then return end
     installAfter=os.clock()+10
     local f,e=loadstring(SOLVER_SOURCE);assert(f,e);f();report("solver installed")
    end
    local match=env.matchClient
    local phase=player:GetAttribute("FootballFreekickPhase")
    local ourSetup=phase=="setup" and (not match or not match.payload or tonumber(match.payload.chooserUserId)==player.UserId)
    if ourSetup and os.clock()>nextAction then
     local setup
     for _,f in ipairs({env.startKick,env.resetFreekick}) do
      if type(f)=="function" then for _,value in pairs(debug.getupvalues(f)) do
       if type(value)=="table" and type(value._startFreekick)=="function" then setup=value;break end
      end end
      if setup then break end
     end
     if setup and setup.active then
      if setup.stage=="options" then
       local schema=require(game.ReplicatedStorage.FootballFreekick.AdvancedSetupSchema)
       assert(schema.IsModeEnabled("Crossbar"),"Crossbar challenge is unavailable in this game")
       setup.options.mode="Crossbar"
       setup:_previewOptions(true)
       setup:_confirmOptions();nextAction=os.clock()+1;report("Crossbar challenge confirmed")
      elseif setup.stage=="selected" then setup:_confirmSelected();nextAction=os.clock()+1;report("play object confirmed")
      elseif setup.stage=="general" and setup.configuration then
       if setup.configuration.mode~="Crossbar" then
        setup:_beginOptions();nextAction=os.clock()+1;report("changing own setup to Crossbar")
       else setup:_startFreekick();nextAction=os.clock()+3;report("Crossbar play started") end
      end
     end
     return
    end
    if phase=="select" and os.clock()>nextAction then env.resetFreekick();nextAction=os.clock()+3;report("opening play setup");return end
    if match and match.payload then
     local p=match.payload
     if p.state=="Complete" or p.state=="Cancelled" then
      if match.resultRoot and visible(match.resultRoot) and not match.rewardPresentationActive and os.clock()>nextAction then
       if p.rematchAvailable==false or p.state=="Cancelled" or p.completionReason=="OPPONENT_FAILED_TO_RECONNECT" then
        match:_activateResultOption(1);nextAction=os.clock()+5;report("Leave: opponent unavailable")
       elseif not match.rematchRequested and match:_canRequestRematch() then
        match:_activateResultOption(2);nextAction=os.clock()+5;report("Rematch requested")
       else report("waiting for rematch or return") end
      end
      return
     end
     report("match active");return
    end
   end
   if os.clock()<nextAction then return end
   for _,x in ipairs(pg:GetDescendants()) do
    if x:IsA("GuiButton") and visible(x) and x.Active then
     local t=textOf(x)
     if t:find("find match",1,true) or t:find("findmatch",1,true) then
      if click(x) then nextAction=os.clock()+15;report("Find Match activated "..x:GetFullName()) end
      return
     end
     if t:find("quick match",1,true) or t:find("quickmatch",1,true) or t:find("qucik match",1,true) then
      if click(x) then nextAction=os.clock()+15;report("Quick Match activated "..x:GetFullName()) end
      return
     end
    end
   end
   report("waiting for menu or client")
  end)
  if not ok then warn("TFC_FLOW error "..tostring(err));task.wait(3) end
  task.wait(0.5)
 end
 teleport:Disconnect();ui:Destroy()
end)
print("TFC_FLOW_READY v1.14 | Crossbar setup, menu, rematch, leave, shooting | power 65-73%")

]======]
getgenv().TFCAutomationBundle=bundle
local f,e=loadstring(bundle);assert(f,e);f()
