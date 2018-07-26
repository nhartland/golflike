package = "golflike"
version = "scm-1"
source = {
   url = "git://github.com/nhartland/golflike",
}

description = {
   summary = "A golf roguelike",
   detailed = [[ ]],
   homepage = "https://github.com/nhartland/golflike",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1",
   "date >= 2.1.2",
   "30log >= 1.3.0",
   "forma >= 0.2",
   "lcurses >= 9.0.0"
}
build = {
   type = "builtin",
   modules = {},
   install = {
      lua = {
            ["game.lib.log"] = "game/lib/log.lua"
        },
      bin = {
         golflike = "main.lua"
      }
   }
}
