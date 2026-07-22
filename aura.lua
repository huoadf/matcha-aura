-- ==============================================================================
-- 🔮 MATCHA PARTICLE & SPARK AURA STUDIO (OFFICIAL INS-UI INTEGRATION)
-- Repository: https://github.com/huoadf/matcha-aura
-- Docs: https://huoadf.github.io/matcha-docs/
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Master Config Table
local aura_config = {
    -- Toggles & Modes
    enabled            = true,
    target_lock_on     = false,
    target_mode        = "LocalPlayer", -- "LocalPlayer", "Closest", "Random"
    sparks_enabled     = true,
    glow_enabled       = true,
    filled_particles   = false,
    rainbow_main       = false,
    rainbow_sparks     = false,
    rainbow_speed      = 1.0,

    -- Dynamic Patterns
    pattern_mode       = "Dual Ring", -- "Dual Ring", "Vortex Helix", "Expanding Shockwave", "Halo & Floor Ring"

    -- Particle Counts
    particle_count     = 35,
    spark_count        = 20,

    -- Colors
    main_color         = Color3.fromRGB(238, 138, 255),
    spark_color        = Color3.fromRGB(80, 220, 255),
    glow_color         = Color3.fromRGB(255, 80, 200),

    -- Dimensions & Offsets
    radius             = 4.0,
    inner_radius       = 1.5,
    height_offset      = 0.5,
    particle_size      = 3.0,
    spark_size         = 1.5,
    glow_scale         = 2.5,
    thickness          = 1.5,

    -- Speeds & Motion
    rotation_speed     = 2.0,
    spark_speed_mult   = 1.4,
    wave_speed         = 2.0,
    wave_amplitude     = 0.5,
    bobbing_speed      = 1.5,
    bobbing_amplitude  = 0.5,
    vortex_height      = 2.5,

    -- Opacity & Glow Intensity
    glow_intensity     = 0.35,
    opacity            = 0.85
}

-- Pre-allocated Drawing Pools (120 FPS Memory Management)
local MAX_PARTICLES = 80
local MAX_SPARKS    = 40

local particle_pool = {}
local spark_pool    = {}
local glow_pool     = {}

for i = 1, MAX_PARTICLES do
    local c = Drawing.new("Circle")
    c.Visible = false
    c.Thickness = aura_config.thickness
    c.NumSides = 16
    c.ZIndex = 6
    particle_pool[i] = c
end

for i = 1, MAX_SPARKS do
    local s = Drawing.new("Circle")
    s.Visible = false
    s.Thickness = 1.0
    s.NumSides = 12
    s.ZIndex = 7
    s.Filled = true
    spark_pool[i] = s

    local g = Drawing.new("Circle")
    g.Visible = false
    g.Thickness = 1.0
    g.NumSides = 12
    g.ZIndex = 5
    g.Filled = true
    glow_pool[i] = g
end

local function hideAll()
    for i = 1, MAX_PARTICLES do particle_pool[i].Visible = false end
    for i = 1, MAX_SPARKS do
        spark_pool[i].Visible = false
        glow_pool[i].Visible = false
    end
end

-- Rainbow Color Generator
local COLOR_NOW = 0
local function rainbowColor(offset)
    local h = ((COLOR_NOW * aura_config.rainbow_speed) + (offset or 0)) % 1
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local q = 1 - f
    local r, g, b
    i = i % 6
    if     i == 0 then r,g,b = 1,f,0
    elseif i == 1 then r,g,b = q,1,0
    elseif i == 2 then r,g,b = 0,1,f
    elseif i == 3 then r,g,b = 0,q,1
    elseif i == 4 then r,g,b = f,0,1
    else               r,g,b = 1,0,q
    end
    return Color3.new(r, g, b)
end

local function get_clamped_radius(base_radius, inner, outer)
    return math.max(inner, math.min(outer, base_radius))
end

-- Target Lock HRP Resolver
local function getTargetHRP()
    if aura_config.target_mode == "LocalPlayer" or not aura_config.target_lock_on then
        local char = LocalPlayer and LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    local myHRP = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    local candidates = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            local dist = (hrp.Position - myHRP.Position).Magnitude
            candidates[#candidates + 1] = {hrp = hrp, dist = dist}
        end
    end

    if #candidates == 0 then return myHRP end

    if aura_config.target_mode == "Closest" then
        table.sort(candidates, function(a, b) return a.dist < b.dist end)
        return candidates[1].hrp
    elseif aura_config.target_mode == "Random" then
        return candidates[math.random(1, #candidates)].hrp
    end

    return myHRP
end

-- Main Render Loop Hook
local time = 0
RunService.Heartbeat:Connect(function(dt)
    if not aura_config.enabled then
        hideAll()
        return
    end

    local targetHRP = getTargetHRP()
    if not targetHRP then
        hideAll()
        return
    end

    local root_pos = targetHRP.Position
    time = time + dt
    COLOR_NOW = (COLOR_NOW + dt * 0.25) % 1.0

    local main_color  = aura_config.rainbow_main and rainbowColor() or aura_config.main_color
    local spark_color = aura_config.rainbow_sparks and rainbowColor(0.5) or aura_config.spark_color
    local glow_color  = aura_config.glow_color
    local opacity     = aura_config.opacity
    local filled      = aura_config.filled_particles
    local inner       = aura_config.inner_radius
    local outer       = aura_config.radius

    -- 1. Main Particles Loop
    local pCount = math.min(math.floor(aura_config.particle_count), MAX_PARTICLES)
    for i = 1, pCount do
        local c = particle_pool[i]
        local angle = (i / pCount) * math.pi * 2 + time * aura_config.rotation_speed
        local x, y, z

        if aura_config.pattern_mode == "Vortex Helix" then
            local progress = ((i / pCount) + time * 0.3) % 1
            local r = get_clamped_radius(outer * (1 - progress * 0.4), inner, outer)
            x = root_pos.X + math.cos(angle * 2) * r
            z = root_pos.Z + math.sin(angle * 2) * r
            y = root_pos.Y + (progress * aura_config.vortex_height - 1.0)
        elseif aura_config.pattern_mode == "Expanding Shockwave" then
            local waveR = ((time * aura_config.wave_speed + i * 0.1) % 1) * outer
            local r = get_clamped_radius(waveR, inner, outer)
            x = root_pos.X + math.cos(angle) * r
            z = root_pos.Z + math.sin(angle) * r
            y = root_pos.Y + aura_config.height_offset
        elseif aura_config.pattern_mode == "Halo & Floor Ring" then
            local isHalo = (i % 2 == 0)
            local r = isHalo and (outer * 0.5) or outer
            x = root_pos.X + math.cos(angle) * r
            z = root_pos.Z + math.sin(angle) * r
            y = root_pos.Y + (isHalo and 2.2 or -2.2) + math.sin(time * aura_config.bobbing_speed + i) * 0.2
        else -- Dual Ring Default
            local waveOffset = math.sin(time * aura_config.wave_speed + i * 0.5) * aura_config.wave_amplitude
            local r = get_clamped_radius(outer - 0.5 + waveOffset, inner, outer)
            x = root_pos.X + math.cos(angle) * r
            z = root_pos.Z + math.sin(angle) * r
            y = root_pos.Y + aura_config.height_offset + math.sin(time * aura_config.bobbing_speed + i * 0.3) * aura_config.bobbing_amplitude
        end

        local screen_pos, onScreen = WorldToScreen(Vector3.new(x, y, z))

        if onScreen then
            local size = aura_config.particle_size + math.sin(time * 2.5 + i * 0.5) * 0.5
            local alpha = 0.3 + math.sin(time * 2.0 + i * 0.3) * 0.3

            c.Position = Vector2.new(screen_pos.X, screen_pos.Y)
            c.Radius = math.max(size, 0.5)
            c.Thickness = aura_config.thickness
            c.Color = main_color
            c.Transparency = math.clamp(alpha * opacity, 0, 1)
            c.Filled = filled
            c.Visible = true
        else
            c.Visible = false
        end
    end
    for i = pCount + 1, MAX_PARTICLES do particle_pool[i].Visible = false end

    -- 2. Sparks & Glow Orbs Loop
    if aura_config.sparks_enabled then
        local sCount = math.min(math.floor(aura_config.spark_count), MAX_SPARKS)
        for i = 1, sCount do
            local s = spark_pool[i]
            local g = glow_pool[i]
            local angle = (i / sCount) * math.pi * 2 - time * (aura_config.rotation_speed * aura_config.spark_speed_mult)
            local r = get_clamped_radius(
                outer * 0.6 + math.sin(time * 2.0 + i * 0.5) * 0.8,
                inner + 0.3,
                outer * 0.9
            )

            local x = root_pos.X + math.cos(angle) * r
            local z = root_pos.Z + math.sin(angle) * r
            local y = root_pos.Y + aura_config.height_offset + math.sin(time * 2.5 + i * 0.4) * 1.2

            local screen_pos, onScreen = WorldToScreen(Vector3.new(x, y, z))

            if onScreen then
                local size = aura_config.spark_size + math.sin(time * 4.0 + i * 1.5) * 0.3
                local alpha = 0.4 + math.sin(time * 3.0 + i * 0.7) * 0.3

                s.Position = Vector2.new(screen_pos.X, screen_pos.Y)
                s.Radius = math.max(size, 0.3)
                s.Color = spark_color
                s.Transparency = math.clamp(alpha * opacity, 0, 1)
                s.Visible = true

                if aura_config.glow_enabled and aura_config.glow_intensity > 0 then
                    local glow_size = size * aura_config.glow_scale
                    local glow_alpha = aura_config.glow_intensity * alpha * opacity * 0.35
                    g.Position = Vector2.new(screen_pos.X, screen_pos.Y)
                    g.Radius = glow_size
                    g.Color = glow_color
                    g.Transparency = math.clamp(glow_alpha, 0, 1)
                    g.Visible = true
                else
                    g.Visible = false
                end
            else
                s.Visible = false; g.Visible = false
            end
        end
        for i = sCount + 1, MAX_SPARKS do
            spark_pool[i].Visible = false; glow_pool[i].Visible = false
        end
    else
        for i = 1, MAX_SPARKS do
            spark_pool[i].Visible = false; glow_pool[i].Visible = false
        end
    end
end)

-- Official INS-ui Library Integration (neaxusxgod-png/INS-ui)
local Lib = nil
pcall(function()
    local code = game:HttpGet("https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/main/uilib.min.lua")
    if type(code) == "string" and code:find("CreateWindow") then
        Lib = loadstring(code)()
    end
end)

Lib = Lib or _G.INSui or (getfenv and getfenv().INSui)

if Lib and Lib.CreateWindow then
    local win = Lib:CreateWindow({
        title    = "Matcha Aura Studio",
        subtitle = "Particle & Spark Engine",
        size     = Vector2.new(680, 520),
        menuKey  = "p",
        smartFps = false,
        checkboxStyle = true,
        logo     = "https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/main/assets/logo.png"
    })

    win:AddSettingsTab("cog")
    Lib:Notify("Matcha Aura Studio", "Loaded! Press P to toggle menu.", 4, "info")

    -- Tab 1: Aura Config
    local mainTab = win:Tab("Aura Config", "sparkles")
    local secControls = mainTab:Section("Master Controls", "Left")
    secControls:Toggle("Enabled", aura_config.enabled, function(on)
        aura_config.enabled = on
        Lib:Notify("Aura", on and "enabled" or "disabled", 2, on and "success" or "warning")
    end)
    secControls:Toggle("Filled Particles", aura_config.filled_particles, function(on)
        aura_config.filled_particles = on
    end)

    secControls:Divider("Targeting & Lock-On")
    secControls:Toggle("Target Lock ESP", aura_config.target_lock_on, function(on)
        aura_config.target_lock_on = on
    end)
    secControls:Dropdown("Target Mode", {"LocalPlayer"}, {"LocalPlayer", "Closest", "Random"}, false, function(v)
        aura_config.target_mode = v[1]
    end)

    local secStyle = mainTab:Section("Pattern Styles", "Right")
    secStyle:Dropdown("Aura Pattern Mode", {"Dual Ring"}, {"Dual Ring", "Vortex Helix", "Expanding Shockwave", "Halo & Floor Ring"}, false, function(v)
        aura_config.pattern_mode = v[1]
    end)

    -- Tab 2: Dynamics & Motion
    local dynTab = win:Tab("Dynamics", "activity")
    local secCounts = dynTab:Section("Particle Counts", "Left")
    secCounts:Slider("Particle Count", 35, 1, 5, 80, "", function(v) aura_config.particle_count = v end)
    secCounts:Slider("Spark Count", 20, 1, 2, 40, "", function(v) aura_config.spark_count = v end)

    local secSpeeds = dynTab:Section("Speed & Waves", "Right")
    secSpeeds:Slider("Rotation Speed", 2.0, 0.1, 0, 5, "", function(v) aura_config.rotation_speed = v end)
    secSpeeds:Slider("Spark Speed Mult", 1.4, 0.1, 0.5, 3, "x", function(v) aura_config.spark_speed_mult = v end)
    secSpeeds:Slider("Wave Speed", 2.0, 0.1, 0, 4, "", function(v) aura_config.wave_speed = v end)
    secSpeeds:Slider("Wave Amplitude", 0.5, 0.1, 0, 2, "", function(v) aura_config.wave_amplitude = v end)
    secSpeeds:Slider("Bobbing Speed", 1.5, 0.1, 0, 4, "", function(v) aura_config.bobbing_speed = v end)

    -- Tab 3: Dimensions & Radius
    local dimTab = win:Tab("Dimensions", "maximize-2")
    local secRad = dimTab:Section("Radius & Offsets", "Left")
    secRad:Slider("Outer Radius", 4.0, 0.1, 1, 12, "m", function(v) aura_config.radius = v end)
    secRad:Slider("Inner Radius", 1.5, 0.1, 0.5, 8, "m", function(v) aura_config.inner_radius = v end)
    secRad:Slider("Height Offset", 0.5, 0.1, -4, 4, "m", function(v) aura_config.height_offset = v end)
    secRad:Slider("Vortex Height", 2.5, 0.1, 1, 6, "m", function(v) aura_config.vortex_height = v end)

    local secSize = dimTab:Section("Particle Sizes", "Right")
    secSize:Slider("Particle Size", 3.0, 0.1, 0.5, 8, "px", function(v) aura_config.particle_size = v end)
    secSize:Slider("Spark Size", 1.5, 0.1, 0.3, 5, "px", function(v) aura_config.spark_size = v end)
    secSize:Slider("Glow Scale", 2.5, 0.1, 1, 6, "x", function(v) aura_config.glow_scale = v end)
    secSize:Slider("Edge Thickness", 1.5, 0.1, 1, 5, "px", function(v) aura_config.thickness = v end)

    -- Tab 4: Colors & Opacity
    local colTab = win:Tab("Colors & FX", "palette")
    local secColors = colTab:Section("Color Customization", "Left")
    local colMainToggle = secColors:Toggle("Main Particle Color", true)
    colMainToggle:AddColorpicker(aura_config.main_color, function(c) aura_config.main_color = c end)

    local colSparkToggle = secColors:Toggle("Spark Color", true)
    colSparkToggle:AddColorpicker(aura_config.spark_color, function(c) aura_config.spark_color = c end)

    local colGlowToggle = secColors:Toggle("Glow Color", true)
    colGlowToggle:AddColorpicker(aura_config.glow_color, function(c) aura_config.glow_color = c end)

    local secRainbow = colTab:Section("Rainbow Modes & Opacity", "Right")
    secRainbow:Toggle("Rainbow Main Color", aura_config.rainbow_main, function(on) aura_config.rainbow_main = on end)
    secRainbow:Toggle("Rainbow Spark Color", aura_config.rainbow_sparks, function(on) aura_config.rainbow_sparks = on end)
    secRainbow:Slider("Rainbow Speed", 1.0, 0.1, 0.2, 5, "x", function(v) aura_config.rainbow_speed = v end)

    secRainbow:Divider("Opacity & Glow")
    secRainbow:Slider("Glow Intensity", 0.35, 0.01, 0, 1, "", function(v) aura_config.glow_intensity = v end)
    secRainbow:Slider("Master Opacity", 0.85, 0.01, 0.1, 1, "", function(v) aura_config.opacity = v end)
end

-- External Global Controls (Preserved & Extended)
_G.set_aura_color = function(r, g, b)
    aura_config.main_color = Color3.fromRGB(r * 255, g * 255, b * 255)
end

_G.set_spark_color = function(r, g, b)
    aura_config.spark_color = Color3.fromRGB(r * 255, g * 255, b * 255)
end

_G.set_aura_enabled = function(enabled)
    aura_config.enabled = enabled
end

_G.get_aura_config = function()
    return aura_config
end

print("[Matcha 3D Aura Studio]: Loaded successfully with official INS ui library!")
