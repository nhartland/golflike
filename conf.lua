if love.filesystem then
    require 'rocks' ()
end

function love.conf(t)
    t.modules.joystick = false
    t.modules.physics = false
    t.title = 'golflike'
    t.package = 'golflike'
    t.loveVersion = '11.1'
    t.version = "0.5b"
    t.author = "Nathan Hartland"
    t.email = "nphartland@gmail.com"
    t.description = "A golf roguelike"
    t.homepage = "https://github.com/nhartland/golflike"
    t.identifier = nil
    t.excludeFileList = {''}
    t.compile = false
    t.identity = "golflike"
    t.version = "11.1"
    t.dependencies = {
        "forma ~> 0.4",
        "date ~> 2.1.2",
        "30log ~> 1.3.0"
    }
end
