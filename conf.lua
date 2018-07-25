if love.filesystem then
	require 'rocks' ()
end

function love.conf(t)
	t.identity = "golflike"
	t.version = "11.1"
    t.dependencies = {
        "forma ~> 0.2",
        "date ~> 2.1.2",
        "30log ~> 1.3.0"
    }
end
