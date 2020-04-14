function love.conf(t)
    t.title = 'golflike'
    t.package = 'golflike'
    t.version = "11.3"
    t.author = "Nathan Hartland"
    t.email = "nphartland@gmail.com"
    t.description = "A golf roguelike"
    t.homepage = "https://github.com/nhartland/golflike"
    t.identifier = nil
    t.excludeFileList = {''}
    t.compile = false
    t.identity = "golflike"
    t.modules.joystick = false
    t.modules.physics = false
end
