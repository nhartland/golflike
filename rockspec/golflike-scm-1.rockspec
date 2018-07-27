package = "golflike"
version = "scm-1"
source = {
   url = "git://github.com/nhartland/golflike",
}

description = {
   summary = "A golf roguelike",
   detailed = [[ golflike is an attempt at making a coffee-break golf-themed
   roguelike. It features a randomly generated 9-hole course, with three
   different environment themes. Games are very short, mostly taking less than
   ten minutes.]],
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
   modules = {
          -- GolfLike
            ["golflike.aim"]          = "golflike/aim.lua",
            ["golflike.astar"]        = "golflike/astar.lua",
            ["golflike.bresenham"]    = "golflike/bresenham.lua",
            ["golflike.clubs"]        = "golflike/clubs.lua",
            ["golflike.common"]       = "golflike/common.lua",
            ["golflike.competition"]  = "golflike/competition.lua",
            ["golflike.draw"]         = "golflike/draw.lua",
            ["golflike.exitconf"]     = "golflike/exitconf.lua",
            ["golflike.flight"]       = "golflike/flight.lua",
            ["golflike.geometry"]     = "golflike/geometry.lua",
            ["golflike.help"]         = "golflike/help.lua",
            ["golflike.hole"]         = "golflike/hole.lua",
            ["golflike.keymap"]       = "golflike/keymap.lua",
            ["golflike.loading"]      = "golflike/loading.lua",
            ["golflike.map"]          = "golflike/map.lua",
            ["golflike.mapgen"]       = "golflike/mapgen.lua",
            ["golflike.maprender"]    = "golflike/maprender.lua",
            ["golflike.markov"]       = "golflike/markov.lua",
            ["golflike.menu"]         = "golflike/menu.lua",
            ["golflike.message"]      = "golflike/message.lua",
            ["golflike.par"]          = "golflike/par.lua",
            ["golflike.pqueue"]       = "golflike/pqueue.lua",
            ["golflike.random"]       = "golflike/random.lua",
            ["golflike.score_hole"]   = "golflike/score_hole.lua",
            ["golflike.state"]        = "golflike/state.lua",
            ["golflike.suffix_data"]  = "golflike/suffix_data.lua",
            ["golflike.surname_data"] = "golflike/surname_data.lua",
            ["golflike.town_data"]    = "golflike/town_data.lua",
            ["golflike.transition"]   = "golflike/transition.lua",
            ["golflike.util"]         = "golflike/util.lua",
            ["golflike.lib.log"]      = "golflike/lib/log.lua",
            ["golflike.lib.cmwc"]     = "golflike/lib/cmwc.lua",
          -- GolfTerm
            ["golfterm.io"]             = "golfterm/io.lua",
            ["golfterm.colour"]         = "golfterm/colour.lua",
            ["golfterm.keys"]           = "golfterm/keys.lua",
            ["golfterm.lcurses_driver"] = "golfterm/lcurses_driver.lua",
            ["golfterm.plua_driver"]    = "golfterm/plua_driver.lua"

   },
   install = {
      bin = {
         golflike = "main.lua"
      }
   }
}
