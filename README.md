# golflike
For those who like their golf *procedurally generated*.

<p align="center">
  <img width="693" height="385" src="https://i.imgur.com/NdFAb6E.gif">
</p>

**golflike** is an attempt at making a coffee-break golf-themed roguelike. It
features a randomly generated 9-hole course, with three different environment
themes. Games are very short, mostly taking less than ten minutes.

<p align="center">
<b>Download</b>
<a href="https://github.com/nhartland/golflike/releases/download/v1.0/golflike_macos.zip">[macos]</a>
<a href="https://github.com/nhartland/golflike/releases/download/v1.0/golflike_win32.zip">[windows]</a>
<a href="https://github.com/nhartland/golflike/releases/download/v1.0/golflike.love">[linux]</a>
</p>

Löve **golflike** packages for macos, Windows and Linux can be downloaded from the releases page or the above links.

Terminal installation
---------------------

In addition to the applications above **golflike** can be played in your terminal. The easiest way to set it up is through [LuaRocks](https://luarocks.org/):
```shell
luarocks install golflike
```
**Note:** **golflike** uses the font and default 16-colour palette of your terminal. If your colourscheme is not a good match then the game might look very strange indeed!

Setup from source
-----------------

To run **golflike** from source, you will need a recent (5.1+) Lua or LuaJIT installation and the following LuaRocks packages:

 - date >= 2.1.2
 - 30log >= 1.3.0
 - forma >= 0.4
 - lcurses >= 9.0.0
 - luaposix >= 34.0.4

With these dependencies, terminal **golflike** can be run with
```shell 
lua(jit) main.lua
```

