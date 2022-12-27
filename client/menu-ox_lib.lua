if Config.Menu == "ox_lib" then
    if lib then
        Config.mainMenu = "x-fps_main_menu"
        Config.fpsMenu = "x-fps_fps_menu"
        Config.visualMenu = "x-fps_visual_menu"
        Config.lightsMenu = "x-fps_light_menu"
        Config.dayLightsMenu = "x-fps_day_light_menu"
        Config.nightLightsMenu = "x-fps_night_light_menu"

        local function goBack(keyPressed, menuToGoBack)
            if keyPressed and keyPressed == "Backspace" then
                if not menuToGoBack then menuToGoBack = Config.mainMenu end
                lib.showMenu(menuToGoBack)
            end
        end
        -- Main Menu
        lib.registerMenu({
            id = Config.mainMenu,
            title = "X-FPS",
            position = "top-right",
            options = {
                { label = "🆙 FPS Booster Menu", args = { menu = Config.fpsMenu } },
                { label = "👓 Visual Modifier Menu", args = { menu = Config.visualMenu } },
                { label = "💡 Vehicle Lights Menu", args = { menu = Config.lightsMenu } }
            }
        },
        function(_, _, args)
            if args.menu then
                lib.showMenu(args.menu)
            end
        end)
        
        -- FPS Booster Menu
        lib.registerMenu({
            id = Config.fpsMenu,
            title = "FPS Booster Menu",
            position = "top-right",
            options = {
                { label = "🆙 FPS Booster Menu" }
            },
            onClose = goBack
        })

        -- Visual Modifier Menu
        local function setUpVisualTimecycleMenuButtons()
            local options = {}
            for index in pairs(Config.visualTimecycles) do
                table.insert(options, {
                    label = (Config.visualTimecycles[index].icon or "❇").." "..Config.visualTimecycles[index].name,
                    args = { onClick = function()
                        ClearTimecycleModifier()
                        ClearExtraTimecycleModifier()
                        SetTimecycleModifier(Config.visualTimecycles[index].modifier)
                        if Config.visualTimecycles[index].extraModifier then SetExtraTimecycleModifier(Config.visualTimecycles[index].extraModifier) end
                    end },
                    close = false
                })
            end
            table.insert(options, {
                label = "🔁 Reset",
                args = { onClick = function()
                    ClearTimecycleModifier()
                    ClearExtraTimecycleModifier()
                    SetTimecycleModifier()
                    ClearTimecycleModifier()
                    ClearExtraTimecycleModifier()
                end },
                close = false
            })
            return options
        end
        lib.registerMenu({
            id = Config.visualMenu,
            title = "Visual Modifier Menu",
            position = "top-right",
            options = setUpVisualTimecycleMenuButtons(),
            onClose = goBack,
        },
        function(_, _, args)
            if args.onClick then
                args.onClick()
            end
        end)

        -- Vehicle Lights Menu
        Config.multiplier = 1
        local function calculateLightProgress(light)
            local max = light.max / Config.multiplier
            local value = (light.modifiedValue or light.defaultValue) / Config.multiplier
            return (value * 100) / max
        end
        local function onLightSettingChange(light, newValue, settingName, time, selectedOption, menuToSet)
            light.modifiedValue = newValue * Config.multiplier
            SetVisualSettingFloat(("car.%s.%s.emissive.on"):format(settingName, time), light.modifiedValue + 0.0)
            lib.setMenuOptions(menuToSet, {
                label = "💡 "..light.name,
                progress = calculateLightProgress(light),
                close = false,
                args = { onClick = function(selected)
                    Config.openMenu = lib.getOpenMenu()
                    lib.hideMenu()
                    local input = lib.inputDialog("X-FPS", {
                        { type = "slider", label = light.name, default = light.modifiedValue / Config.multiplier, min = light.min, max = light.max / Config.multiplier }
                    })
                    if input then
                        onLightSettingChange(light, input[1], settingName, time, selected, Config.openMenu)
                    end
                    lib.showMenu(Config.openMenu)
                    Config.openMenu = nil
                end }
            }, selectedOption)
        end
        local function setUpLightMenuButtons(timeToSet)
            local options = {}
            for name, v in pairs(Config.vehicleLightsSetting) do
                for time, light in pairs(v) do
                    if time == timeToSet then
                        table.insert(options, {
                            label = "💡 "..light.name,
                            progress = calculateLightProgress(light),
                            args = { onClick = function(selected)
                                Config.openMenu = lib.getOpenMenu()
                                lib.hideMenu()
                                local input = lib.inputDialog("X-FPS", {
                                    { type = "slider", label = light.name, default = light.defaultValue / Config.multiplier, min = light.min, max = light.max / Config.multiplier }
                                })
                                if input then
                                    onLightSettingChange(light, input[1], name, time, selected, Config.openMenu)
                                end
                                lib.showMenu(Config.openMenu)
                                Config.openMenu = nil
                            end },
                            close = false
                        })
                    end
                end
            end
            return options
        end
        lib.registerMenu({
            id = Config.lightsMenu,
            title = "Vehicle Lights Menu",
            position = "top-right",
            options = {
                { label = "💡 Vehicle Lights Menu (DAY)", args = { menu = Config.dayLightsMenu } },
                { label = "💡 Vehicle Lights Menu (NIGHT)", args = { menu = Config.nightLightsMenu } },
                { label = "Ⓜ Multiplier", values = { "1x", "10x", "100x", "1000x" }, defaultIndex = Config.multiplier, close = false },
            },
            onClose = goBack,
            onSideScroll = function(selected, scrollIndex, _)
                if scrollIndex == 1 then
                    Config.multiplier = 1
                elseif scrollIndex == 2 then
                    Config.multiplier = 10
                elseif scrollIndex == 3 then
                    Config.multiplier = 100
                elseif scrollIndex == 4 then
                    Config.multiplier = 1000
                end
                lib.setMenuOptions(Config.lightsMenu, { label = "Ⓜ Multiplier", values = { "1x", "10x", "100x", "1000x" }, defaultIndex = scrollIndex, close = false }, selected)
            end,
        },
        function(_, _, args)
            if args and args.menu then
                lib.showMenu(args.menu)
            end
        end)
        lib.registerMenu({
            id = Config.dayLightsMenu,
            title = "Vehicle Lights Menu (DAY)",
            position = "top-right",
            options = setUpLightMenuButtons("day"),
            onClose = function(keyPressed)
                goBack(keyPressed, Config.lightsMenu)
            end
        },
        function(selected, _, args)
            if args and args.onClick then
                args.onClick(selected)
            end
        end)
        lib.registerMenu({
            id = Config.nightLightsMenu,
            title = "Vehicle Lights Menu (NIGHT)",
            position = "top-right",
            options = setUpLightMenuButtons("night"),
            onClose = function(keyPressed)
                goBack(keyPressed, Config.lightsMenu)
            end
        },
        function(selected, _, args)
            if args and args.onClick then
                args.onClick(selected)
            end
        end)
    else
        error("Error: ox_lib resource is not properly loaded inside x-fps!")
    end
end