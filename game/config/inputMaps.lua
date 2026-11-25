-- game/inputMaps.lua

return {
    accept = {
        keys = { "return", "space" },
        mouse = { 1 },
        gamepad = { "a" },
    },

    exit = {
        keys = { "escape" },
        gamepad = { "start" },
    },

    move_left = {
        keys = { "left" },
        gamepad = {
            "dpleft",
            axes = {
                leftx = -1,
            },
        },
    },

    move_right = {
        keys = { "right" },
        gamepad = {
            "dpright",
            axes = {
                leftx = 1,
            },
        },
    },

    jump = {
        keys = { "space" },
        gamepad = { "a" },
    },
}
