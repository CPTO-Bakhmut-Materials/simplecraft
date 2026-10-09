function love.conf(t)
    -- love.js (the browser build, see tools/build_web.sh) is LÖVE 11.4, and it
    -- crashes on startup when the audio modules are disabled. love._os is
    -- internal, but love.system isn't loaded yet when conf.lua runs.
    --- @diagnostic disable-next-line: undefined-field
    local web = love._os == "Web"
    --- @diagnostic disable-next-line: undefined-field
    local mobile = love._os == "Android" or love._os == "iOS"

    t.identity = "love-mcraft"
    t.version = web and "11.4" or "11.5"

    t.window.title = "love-mcraft"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.vsync = 1
    t.window.depth = 24
    t.window.msaa = 4
    t.window.fullscreen = mobile -- phones and tablets have no key for it (in a browser, the page has a button)

    t.modules.audio = web
    t.modules.sound = web
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
end
