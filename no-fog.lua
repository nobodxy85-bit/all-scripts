-- No Fog Script para Project Lazarus
-- Elimina la niebla y mejora la visibilidad

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- Configuración
local NoFogEnabled = true

-- Notificación de inicio
game.StarterGui:SetCore("SendNotification", {
    Title = "No Fog";
    Text = "Script activado - Niebla eliminada";
    Duration = 3;
})

-- Función para eliminar la niebla
local function RemoveFog()
    if NoFogEnabled then
        -- Eliminar niebla
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        
        -- Mejorar brillo
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        
        -- Eliminar efectos atmosféricos
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("Atmosphere") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
                effect.Enabled = false
            end
        end
    end
end

-- Aplicar al inicio
RemoveFog()

-- Mantener activo constantemente (por si el juego intenta restaurar la niebla)
local connection = RunService.Heartbeat:Connect(function()
    RemoveFog()
end)

-- Detectar nuevos efectos que se agreguen
Lighting.ChildAdded:Connect(function(child)
    if child:IsA("Atmosphere") or child:IsA("BlurEffect") or child:IsA("ColorCorrectionEffect") then
        child.Enabled = false
    end
end)

print("No Fog activado - Visibilidad mejorada")

-- Función para desactivar (opcional)
local function ToggleFog()
    NoFogEnabled = not NoFogEnabled
    if NoFogEnabled then
        game.StarterGui:SetCore("SendNotification", {
            Title = "No Fog";
            Text = "Activado";
            Duration = 2;
        })
    else
        -- Restaurar valores normales
        Lighting.FogEnd = 1000
        Lighting.FogStart = 0
        Lighting.Brightness = 1
        game.StarterGui:SetCore("SendNotification", {
            Title = "No Fog";
            Text = "Desactivado";
            Duration = 2;
        })
    end
end

-- Opcional: Activar/desactivar con tecla (por ejemplo, "F")
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
        ToggleFog()
    end
end)
