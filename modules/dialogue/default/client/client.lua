local promises = {}
local activeDialogue = nil
local pendingCameraDestroy = false
Dialogue = {}

local cam = nil
local npc = nil

function Dialogue.CloseDialogue(name)
    -- Instead of destroying immediately, wait to see if new dialogue opens
    pendingCameraDestroy = true
    activeDialogue = nil
    
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "close",
        name = name
    })

    -- Wait brief moment to see if new dialogue opens
    CreateThread(function()
        Wait(50) -- Small delay to allow new dialogue to open
        if pendingCameraDestroy and not activeDialogue then
            -- No new dialogue opened, safe to destroy camera
            RenderScriptCams(false, 1, 1000, 1, 0)
            SetCamActive(cam, false)
            DestroyCam(cam, false)
            cam = nil
        end
    end)
    
    promises[name] = nil
end

--- Open a dialogue with the player
--- @param name string
--- @param dialogue string
--- @param options table example = {{  id = string, label = string}}
function Dialogue.OpenDialogue(entity, name, dialogue, options, onSelected, onCancelled)
    -- Cancel any pending camera destroy
    pendingCameraDestroy = false
    activeDialogue = name

    -- camera magic! 
    if entity then        
        local pedHeading = GetEntityHeading(entity)
        -- Convert heading to radians and calculate offset
        local angleRad = math.rad(pedHeading)
        local offsetX = math.sin(angleRad) * 1.5
        local offsetY = math.cos(angleRad) * 1.5
        
        -- Get position in front of ped based on their heading
        local endLocation = GetEntityCoords(entity) + vector3(offsetX, offsetY, 1.0)
      
        if not cam then cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", 1) end
        local camPos = GetCamCoord(cam)
        local dist = #(endLocation - camPos)
        local abs = cam and math.abs(dist)
        if not abs or abs > 0.5 then 
            print(abs)          
            endLocation = GetEntityCoords(entity) + vector3(offsetX, offsetY, 1.0)
            local camAngle = (pedHeading + 180.0) % 360.0
            SetCamRot(cam, 0.0, 0.0, camAngle, 2)
            SetCamCoord(cam, endLocation.x, endLocation.y, endLocation.z)
            RenderScriptCams(true, 1, 1000, 1, 0)
            SetCamActive(cam, true)
        end      
    end
    SendNUIMessage({
        type = "open",
        text =  dialogue,
        name = name,
        options = options
    })
    SetNuiFocus(true, true)
 
    local wrappedFunction = function(selected)                
        SetNuiFocus(false, false)
        Dialogue.CloseDialogue(name)
        onSelected(selected)
    end
    promises[name] = wrappedFunction
end

RegisterCommand("dialogue", function()
    local pos = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0, 2.0, 0)
    local timeout = 500 
    local model = `a_f_y_hipster_01`
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
        timeout = timeout - 1
        if timeout == 0 then
            print("Failed to load model")
            return
        end
    end
    local prop = CreatePed(0, model, pos.x, pos.y, pos.z, 0.0, false, false)

    Wait(750)
    Dialogue.OpenDialogue( prop, "Akmed" , "Hello how are you doing my friend?", { 
            {
                label = "Trade with me",
                id = 'something',
            },
            {
                label = "Goodbye",
                id = 'someotherthing',
            },
        },
        function(selectedId)
            if selectedId == 'something' then
                Dialogue.OpenDialogue( prop, "Akmed" , "Thank you for wanting to purchase me lucky charms", { 
                    {
                        label = "Fuck off",
                        id = 'something',                       
                    },
                    {
                        label = "Goodbye",
                        id = 'someotherthing',
                    },
                },
                function(selectedId)
                    DeleteEntity(prop)
                    if selectedId == "something" then 
                        print("You hate lucky charms")
                    else
                        print("Thanks for keeping it civil")
                    end
                end
            )
            end
        end
    )
end)

RegisterNuiCallback("dialogue:SelectOption", function(data)
    local promis = promises[data.name]
    if not promis then return end
    promis(data.id)
end)

-- { label: 'Hello there! this is some long text that i am Dialogueing', id: '1' },
-- { label: 'Trade with me', id: '2' },
-- { label: 'Goodbye', id: '3' }
