--[[
                                     
     Steamburn Awesome WM config 3.0 
     github.com/copycat-killer       
                                     
--]]

-- {{{ Required libraries
local gears      = require("gears")
local awful      = require("awful")
awful.rules      = require("awful.rules")
local tyrannical = require("tyrannical")
                   require("awful.autofocus")
local wibox      = require("wibox")
local beautiful  = require("beautiful")
local naughty    = require("naughty")
local drop       = require("scratchdrop")
local lain       = require("lain")
local APW        = require("apw/widget")
local sharetags  = require("sharetags")

-- }}}

-- {{{ Error handling
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Autostart applications
function run_once(cmd)
  findme = cmd
  firstspace = cmd:find(" ")
  if firstspace then
     findme = cmd:sub(0, firstspace-1)
  end
  awful.util.spawn_with_shell("pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd .. ")")
end

-- }}}

-- {{{ Variable definitions
-- localization
os.setlocale(os.getenv("LANG"))

-- beautiful init
beautiful.init(os.getenv("HOME") .. "/.config/awesome/themes/steamburn/theme.lua")

-- common
modkey     = "Mod4"
altkey     = "Mod1"
terminal   = "terminator"
editor     = os.getenv("EDITOR") or "vi"
editor_cmd = terminal .. " -e " .. editor

-- user defined
browser    = "firefox"
gui_editor = "gvim"
graphics   = "gimp"

-- lain
lain.layout.termfair.nmaster = 3
lain.layout.termfair.ncol    = 1

local layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Global settings
tyrannical.settings.block_children_focus_stealing = true --Block popups ()
tyrannical.settings.group_children = true --Force popups/dialogs to have the same tags as the parent client
tyrannical.settings.default_layout = awful.layout.suit.tile
-- }}}

-- {{{ Tags
tyrannical.tags = {
    {
        name        = "web",
        init        = true,
        exclusive   = true,
        screen      = 1,
        force_screen = true,
        layout      = awful.layout.suit.max.fullscreen,
        shared_number = 1,
        class = {
            "Opera"         , "Firefox"        , "Rekonq"    , "Dillo"        , "Arora",
            "Chromium"      , "nightly"        , "minefield"     }
    } ,
    {
        name        = "social",
        init        = true,
        exclusive   = true,
        screen      = 2,
	selected    = true,
        force_screen = true,
        layout      = awful.layout.suit.tile,
        shared_number = 3,
        class       = {
            "Skype" 
        }
    } ,
    {
        name        = "mail",
        init        = true,
        exclusive   = true,
        screen      = 1,
        force_screen = true,
	selected    = true,
        layout      = awful.layout.suit.max,
        shared_number = 2,
        instance    = {"Mail"},
        class       = {
            "Thunderbird"
        }
    } ,
    {
        name        = "new_tag",
        init        = false,
        exclusive   = false,
	selected    = true,
        layout      = awful.layout.suit.tile,
        fallback    = true
    } ,
}

--tags = sharetags.create_tags(tags.names, tags.layout)
-- }}}

-- {{{ Client settings
tyrannical.properties.intrusive = {
     "kcalc"        , "xcalc"               ,
}
tyrannical.properties.floating = {
    "kcalc"        , "xcalc"          ,
}
tyrannical.properties.centered = {
    "kcalc"
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Menu
mymainmenu = awful.menu.new({ items = require("menugen").build_menu(),
                              theme = { height = 16, width = 130 }})

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox
markup = lain.util.markup
gray   = "#94928F"
red  = "#EB8F8F"

-- Textclock
mytextclock = awful.widget.textclock(" %H:%M ")

-- Calendar
lain.widgets.calendar:attach(mytextclock)

-- Mail IMAP check
mailwidget = lain.widgets.imap({
    timeout  = 180,
    server   = "server",
    mail     = "mail",
    password = "keyring get mail",
    settings = function()
        mail  = ""
        count = ""

        if mailcount > 0 then
            mail = "Mail "
            count = mailcount .. " "
        end

        widget:set_markup(markup(gray, mail) .. count)
    end
})

-- CPU
cpuwidget = lain.widgets.sysload({
    settings = function()
        widget:set_markup(markup(gray, " Cpu ") .. load_1 .. " ")
    end
})

-- MEM
memwidget = lain.widgets.mem({
    settings = function()
        widget:set_markup(markup(gray, " Mem ") .. mem_now.used .. " ")
    end
})

-- /home fs
fshomeupd = lain.widgets.fs({
    partition = "/home",
    settings  = function()
	local color
        if fs_now.used < 90 then
	    color = gray
        else
	    color = red
        end
        widget:set_markup(markup(color, " Disk ") .. fs_now.used .. "% ")
    end
})

-- Net checker
netwidget = lain.widgets.net({
    settings = function()
        if net_now.state == "up" then net_state = "On"
        else net_state = "Off" end
        widget:set_markup(markup(gray, " Net ") .. net_state .. " ")
    end
})

-- Pulseaudio volume
volumewidget = APW

-- Weather
yawn = lain.widgets.yawn(123456)

-- Separators
first = wibox.widget.textbox(markup.font("Tamsyn 4", " "))
spr = wibox.widget.textbox(' ')

-- Keyboard map indicator and changer
kbdcfg = {}
kbdcfg.cmd = "setxkbmap"
kbdcfg.layout = { { "us", "En" }, { "ru", "Ru" } }
kbdcfg.clients = {}
kbdcfg.current = 1  -- us is our default layout
kbdcfg.widget = wibox.widget.textbox()
kbdcfg.widget:set_text(" " .. kbdcfg.layout[kbdcfg.current][2] .. " ")
kbdcfg.switch = function ()
  kbdcfg.current = kbdcfg.current % #(kbdcfg.layout) + 1
  if client.focus then
    kbdcfg.clients[client.focus] = kbdcfg.current
  end
  local t = kbdcfg.layout[kbdcfg.current]
  kbdcfg.widget:set_text(" " .. t[2] .. " ")
  os.execute( kbdcfg.cmd .. " -layout '" .. t[1] .. ",us'" )
end
kbdcfg.reset = function (client)
  current = kbdcfg.clients[client] or 1
  kbdcfg.current = current
  local t = kbdcfg.layout[current]
  kbdcfg.widget:set_text(" " .. t[2] .. " ")
  os.execute( kbdcfg.cmd .. " -layout '" .. t[1] .. ",us'" )
end

-- Create a wibox for each screen and add it
mywibox = {}
mybottomwibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytasklist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end))
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

-- Writes a string representation of the current layout in a textbox widget
function updatelayoutbox(layout, s)
--    local screen = s or 1
--    local txt_l = beautiful["layout_txt_" .. awful.layout.getname(awful.layout.get(screen))] or ""
--    layout:set_text(txt_l)
end

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()

    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))

    -- Create a taglist widget
    -- mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)
    mytaglist[s] = sharetags.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s, height = 18 })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(first)
    left_layout:add(mytaglist[s])
    left_layout:add(spr)
    left_layout:add(mylayoutbox[s])
    left_layout:add(spr)
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(spr)
    --right_layout:add(mailwidget)
    right_layout:add(cpuwidget)
    right_layout:add(memwidget)
    right_layout:add(fshomeupd)
    right_layout:add(netwidget)
    right_layout:add(volumewidget)
    right_layout:add(kbdcfg.widget)
    right_layout:add(mytextclock)

    -- Now bring it all together
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)

    -- Create the bottom wibox
    mybottomwibox[s] = awful.wibox({ position = "bottom", screen = s, border_width = 0, height = 32 })

    -- Widgets that are aligned to the bottom left
    bottom_left_layout = wibox.layout.fixed.horizontal()
    bottom_left_layout:add(mylauncher)

    -- Now bring it all together (with the tasklist in the middle)
    bottom_layout = wibox.layout.align.horizontal()
    bottom_layout:set_left(bottom_left_layout)
    bottom_layout:set_middle(mytasklist[s])
    mybottomwibox[s]:set_widget(bottom_layout)

    -- Set proper backgrounds, instead of beautiful.bg_normal
    -- mywibox[s]:set_bg(beautiful.topbar_path .. screen[mouse.screen].workarea.width .. ".png")
    mybottomwibox[s]:set_bg("#242424")

    -- Create a borderbox above the bottomwibox
    lain.widgets.borderbox(mybottomwibox[s], s, { position = "top", color = "#0099CC" } )
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

kbdcfg.widget:buttons(
    awful.util.table.join(awful.button({ }, 1, function () kbdcfg.switch() end))
)
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(

    -- Alt + Right Shift switches the current keyboard layout
    awful.key({ altkey }, "Shift_L", function () kbdcfg.switch() end),
    awful.key({ "Shift" }, "Alt_L", function () kbdcfg.switch() end),

    -- Lock screen
    -- CTRL - ALT - l
    awful.key({ altkey, "Control" }, "#" .. 46, function () awful.util.spawn("dm-tool lock") end),

    -- By direction client focus (across screens)
    -- keys h, j, k, l
    awful.key({ modkey }, "#" .. 43,
        function()
            awful.client.focus.global_bydirection("left")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "#" .. 44,
        function()
            awful.client.focus.bydirection("down")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "#" .. 45,
        function()
            awful.client.focus.bydirection("up")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "#" .. 46,
        function()
            awful.client.focus.global_bydirection("right")
            if client.focus then client.focus:raise() end
        end),

    -- By direction client swap
    -- keys h, j, k, l
    awful.key({ modkey, "Control" }, "#" .. 43, function() awful.client.swap.bydirection("left") end),
    awful.key({ modkey, "Control" }, "#" .. 44, function() awful.client.swap.bydirection("down") end),
    awful.key({ modkey, "Control" }, "#" .. 45, function() awful.client.swap.bydirection("up") end),
    awful.key({ modkey, "Control" }, "#" .. 46, function() awful.client.swap.bydirection("right") end),

    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            local cur_screen = mouse.screen
            local tag = awful.tag.selected(cur_screen)
            if tag then
                next_screen = cur_screen%screen.count() + 1
                awful.tag.setscreen(tag, next_screen)
                awful.tag.viewonly(tag)
                mouse.screen = next_screen
            end
        end),

    awful.key({ modkey,           }, "space",  function () awful.layout.inc(layouts,  1)  end),
    awful.key({ modkey, "Shift"   }, "space",  function () awful.layout.inc(layouts, -1)  end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r",      awesome.restart),
    awful.key({ modkey, "Control" }, "q",      awesome.quit),

    -- Dropdown terminal
    awful.key({ modkey,	          }, "z",      function () drop(terminal) end),

    -- Widgets popups
    awful.key({ altkey,           }, "h",      function () fshomeupd.show(7) end),
    awful.key({ altkey,           }, "w",      function () yawn.show(7) end),

    -- ALSA volume control
    awful.key({ }, "XF86AudioRaiseVolume", volumewidget.Up ),
    awful.key({ }, "XF86AudioLowerVolume", volumewidget.Down ),
    awful.key({ }, "XF86AudioMute", volumewidget.ToggleMute ),

    -- Copy to clipboard
    awful.key({ modkey }, "c", function () os.execute("xsel -p -o | xsel -i -b") end),

    -- User programs
    awful.key({ modkey }, "q", function () awful.util.spawn(browser) end),
    awful.key({ modkey }, "i", function () awful.util.spawn(browser2) end),
    awful.key({ modkey }, "s", function () awful.util.spawn(gui_editor) end),
    awful.key({ modkey }, "g", function () awful.util.spawn(graphics) end),

    -- Prompt
    awful.key({ modkey }, "r", function () mypromptbox[mouse.screen]:run() end),
    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(
    -- Close client
    awful.key({ modkey }, 'Escape', function (c) c:kill() end),
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 10 do
    local keycode = "#" .. i+9

    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, keycode,
                  function ()
                        local cur_screen = mouse.screen
                        local tag = sharetags.tags.get_by_shared_number(i)
                        if tag then
                            awful.tag.viewonly(tag)
                            scr = awful.tag.getscreen(tag)
                            if scr ~= mouse.screen then
                                awful.screen.focus(scr)
                                -- local cltbl = awful.client.visible(scr)
                                -- if #cltbl then
                                --     client.focus = cltbl[1]
                                -- else
                                --     mouse.screen = scr
                                -- end
                            end
                        else
                            awful.prompt.run({prompt = "<span fgcolor='red'>new tag: </span>"},
                            mypromptbox[cur_screen].widget,
                            function (text)
                                if #text>0 then
                                    local properties = tyrannical.tags_by_name["new_tag"];
                                    tag = awful.tag.add(text, properties)
                                    awful.tag.viewonly(tag)
                                end
                            end,
                            nil)
                        end
                  end),
        awful.key({ modkey, "Control" }, keycode,
                  function ()
                      local tag = sharetags.tags.get_by_shared_number(i)
                      if client.focus and tag then
                          awful.client.movetotag(tag)
                     end
                  end),
        awful.key({ modkey, "Shift" }, keycode,
                  function ()
                      local tag = sharetags.tags.get_by_shared_number(i)
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     size_hints_honor = false } },
}
-- }}}

-- {{{ Signals
-- signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup and not c.size_hints.user_position
       and not c.size_hints.program_position then
        awful.placement.no_overlap(c)
        awful.placement.no_offscreen(c)
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- the title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c,{size=16}):set_widget(layout)
    end
end)

-- No border for maximized clients
client.connect_signal("focus",
    function(c)
        if c.maximized_horizontal == true and c.maximized_vertical == true then
            c.border_color = beautiful.border_normal
        else
            c.border_color = beautiful.border_focus
        end
        kbdcfg.reset(c)
    end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- {{{ Arrange signal handler
for s = 1, screen.count() do screen[s]:connect_signal("arrange", function ()
        local clients = awful.client.visible(s)
        local layout  = awful.layout.getname(awful.layout.get(s))

        if #clients > 0 then -- Fine grained borders and floaters control
            for _, c in pairs(clients) do -- Floaters always have borders
                if awful.client.floating.get(c) or layout == "floating" then
                    c.border_width = beautiful.border_width

                -- No borders with only one visible client
                elseif #clients == 1 or layout == "max" then
                    clients[1].border_width = 0
                else
                    c.border_width = beautiful.border_width
                end
            end
        end
      end)
end
-- }}}

run_once("firefox");
run_once("skype");
run_once("thunderbird");
