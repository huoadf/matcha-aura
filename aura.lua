-- ==============================================================================
-- 🔮 MATCHA PARTICLE & SPARK AURA SYSTEM
-- Repository: https://github.com/huoadf/matcha-aura
-- Docs: https://huoadf.github.io/matcha-docs/
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Configuration Table
local aura_config = {
    enabled = true,
    main_color = Color3.fromRGB(235, 8, 255),
    spark_color = Color3.fromRGB(255, 20, 255),
    particle_count = 30,
    spark_count = 15,
    radius = 4.0,
    inner_radius = 1.5,
    particle_size = 3.0,
    spark_size = 1.5,
    rotation_speed = 2.0,
    wave_speed = 2.0,
    filled_particles = false,
    glow_intensity = 0.3,
    opacity = 1.0
}

-- Drawing Pools (Pre-allocated for maximum 120 FPS performance)
local MAX_PARTICLES, MAX_SPARKS = 80, 40
local particle_pool, spark_pool, glow_pool = {}, {}, {}

for i = 1, MAX_PARTICLES do
    local c = Drawing.new("Circle")
    c.Visible = false
    c.Thickness = 1.5
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

local function get_clamped_radius(base_radius, inner, outer)
    return math.max(inner, math.min(outer, base_radius))
end

-- Render Loop (Matcha Heartbeat Hook)
local time = 0
RunService.Heartbeat:Connect(function(dt)
    if not aura_config.enabled then
        for i = 1, MAX_PARTICLES do particle_pool[i].Visible = false end
        for i = 1, MAX_SPARKS do spark_pool[i].Visible = false; glow_pool[i].Visible = false end
        return
    end

    local character = LocalPlayer and LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local root_pos = root.Position
    time = time + dt

    -- 1. Main Particles
    local pCount = math.min(math.floor(aura_config.particle_count), MAX_PARTICLES)
    for i = 1, pCount do
        local c = particle_pool[i]
        local angle = (i / pCount) * math.pi * 2 + time * aura_config.rotation_speed
        local r = get_clamped_radius(
            aura_config.radius - 0.5 + math.sin(time * aura_config.wave_speed + i * 0.5) * 0.5,
            aura_config.inner_radius,
            aura_config.radius
        )

        local x = root_pos.X + math.cos(angle) * r
        local z = root_pos.Z + math.sin(angle) * r
        local y = root_pos.Y + 0.5 + math.sin(time * 1.5 + i * 0.3) * 0.5

        local screen_pos, onScreen = WorldToScreen(Vector3.new(x, y, z))
        if onScreen then
            local size = aura_config.particle_size + math.sin(time * 2.5 + i * 0.5) * 0.5
            local alpha = 0.3 + math.sin(time * 2.0 + i * 0.3) * 0.3
            c.Position = Vector2.new(screen_pos.X, screen_pos.Y)
            c.Radius = math.max(size, 0.5)
            c.Color = aura_config.main_color
            c.Transparency = math.clamp(alpha * aura_config.opacity, 0, 1)
            c.Filled = aura_config.filled_particles
            c.Visible = true
        else
            c.Visible = false
        end
    end
    for i = pCount + 1, MAX_PARTICLES do particle_pool[i].Visible = false end

    -- 2. Spark Particles & Glows
    local sCount = math.min(math.floor(aura_config.spark_count), MAX_SPARKS)
    for i = 1, sCount do
        local s, g = spark_pool[i], glow_pool[i]
        local angle = (i / sCount) * math.pi * 2 + time * (aura_config.rotation_speed * 1.3)
        local r = get_clamped_radius(
            aura_config.radius * 0.6 + math.sin(time * 2.0 + i * 0.5) * 0.8,
            aura_config.inner_radius + 0.3,
            aura_config.radius * 0.9
        )

        local x = root_pos.X + math.cos(angle) * r
        local z = root_pos.Z + math.sin(angle) * r
        local y = root_pos.Y + 0.5 + math.sin(time * 2.5 + i * 0.4) * 1.2

        local screen_pos, onScreen = WorldToScreen(Vector3.new(x, y, z))
        if onScreen then
            local size = aura_config.spark_size + math.sin(time * 4.0 + i * 1.5) * 0.3
            local alpha = 0.4 + math.sin(time * 3.0 + i * 0.7) * 0.3
            s.Position = Vector2.new(screen_pos.X, screen_pos.Y)
            s.Radius = math.max(size, 0.3)
            s.Color = aura_config.spark_color
            s.Transparency = math.clamp(alpha * aura_config.opacity, 0, 1)
            s.Visible = true

            if aura_config.glow_intensity > 0 then
                g.Position = Vector2.new(screen_pos.X, screen_pos.Y)
                g.Radius = size * 2.5
                g.Color = aura_config.spark_color
                g.Transparency = math.clamp(aura_config.glow_intensity * alpha * aura_config.opacity * 0.3, 0, 1)
                g.Visible = true
            else
                g.Visible = false
            end
        else
            s.Visible = false; g.Visible = false
        end
    end
    for i = sCount + 1, MAX_SPARKS do spark_pool[i].Visible = false; glow_pool[i].Visible = false end
end)

-- INS-UI Interface Setup
local Lib = nil
pcall(function()
    local code = game:HttpGet("https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/main/uilib.min.lua")
    if type(code) == "string" and code:find("CreateWindow") then
        Lib = loadstring(code)()
    end
end)

Lib = Lib or _G.INSui or (getfenv and getfenv().INSui)

if Lib and Lib.CreateWindow then
    local Win = Lib:CreateWindow("Aura Configuration")
    local Tab = Win:Tab("Main")

    local SecGen = Tab:Section("General")
    SecGen:Toggle("Enable Aura", aura_config.enabled, function(v) aura_config.enabled = v end)
    SecGen:Toggle("Filled Particles", aura_config.filled_particles, function(v) aura_config.filled_particles = v end)

    local SecCol = Tab:Section("Colors")
    SecCol:Colorpicker("Main Color", aura_config.main_color, function(v) aura_config.main_color = v end)
    SecCol:Colorpicker("Spark Color", aura_config.spark_color, function(v) aura_config.spark_color = v end)

    local SecSize = Tab:Section("Sizes & Radius")
    SecSize:Slider("Outer Radius", 40, 1, 10, 100, "", function(v) aura_config.radius = v / 10 end)
    SecSize:Slider("Inner Radius", 15, 1, 0, 30, "", function(v) aura_config.inner_radius = v / 10 end)
    SecSize:Slider("Particle Size", 30, 1, 5, 60, "", function(v) aura_config.particle_size = v / 10 end)
    SecSize:Slider("Spark Size", 15, 1, 3, 30, "", function(v) aura_config.spark_size = v / 10 end)

    local SecSpd = Tab:Section("Counts & Speeds")
    SecSpd:Slider("Particle Count", 30, 1, 5, 80, "", function(v) aura_config.particle_count = v end)
    SecSpd:Slider("Spark Count", 15, 1, 2, 40, "", function(v) aura_config.spark_count = v end)
    SecSpd:Slider("Rotation Speed", 20, 1, 1, 50, "", function(v) aura_config.rotation_speed = v / 10 end)
    SecSpd:Slider("Wave Speed", 20, 1, 1, 40, "", function(v) aura_config.wave_speed = v / 10 end)
    SecSpd:Slider("Glow Intensity", 3, 1, 0, 10, "", function(v) aura_config.glow_intensity = v / 10 end)
    SecSpd:Slider("Opacity", 10, 1, 1, 10, "", function(v) aura_config.opacity = v / 10 end)

    Lib:Notify("Aura System", "Particle & Spark Aura Active!", 4)
end

-- External Control Functions (Preserved)
_G.set_aura_color = function(r, g, b)
    aura_config.main_color = Color3.fromRGB(r * 255, g * 255, b * 255)
end

_G.set_aura_enabled = function(enabled)
    aura_config.enabled = enabled
end

_G.get_aura_config = function()
    return aura_config
end

print("[Matcha Aura]: Loaded successfully! (Particles + Sparks)")
