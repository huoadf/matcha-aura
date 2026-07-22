# Matcha Particle & Spark Aura Studio

A high-performance, fully customizable Particle & Spark 3D Aura system for **Matcha LuaVM** (Roblox external script), powered by the official **[INS ui](https://github.com/neaxusxgod-png/INS-ui)** menu library.

## 🚀 Execution Loadstring

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/huoadf/matcha-aura/main/aura.lua"))()
```

## ✨ What's New & Included
- **Official INS-UI Integration**: Sleek modern tabbed UI with setting icons, settings tab (`Press P to toggle`), and interactive widgets.
- **4 Aura Pattern Modes**:
  - `Dual Ring`: Rotating inner & outer rings with wave bobbing.
  - `Vortex Helix`: Particle energy tornado spiraling vertically around your avatar.
  - `Expanding Shockwave`: Rhythmic pulse waves expanding outwards.
  - `Halo & Floor Ring`: Dual rings with a floating halo above the head and a floor ring at the feet.
- **Target-Lock & ESP**: Lock your aura onto yourself (`LocalPlayer`), the `Closest Player`, or `Random Player`.
- **Full Customization**: Particle counts ($1 \to 80$), spark counts ($1 \to 40$), inner/outer radius, particle sizes, glow intensity, master opacity, and color pickers + rainbow HSV modes.
- **120 FPS Optimization**: Pre-allocated `Drawing.new("Circle")` memory pools to ensure zero memory leaks.
