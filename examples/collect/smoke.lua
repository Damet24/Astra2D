local Components = require("engine.ecs.component")

local Smoke = {}

function Smoke.install(engine)
    -- Bypass LÖVE's interactive error screen so failures produce a nonzero exit.
    function love.run()
        local ok, message = xpcall(function()
            love.load()
            local field = engine.sceneManager.stack[1].scene
            assert(engine.sceneManager.stack[1].id == "field")
            assert(engine.resourceManager.resources.hud)
            local player = field.world:getComponent(field.player, Components.Transform)

            love.keypressed("d")
            love.update(120 / 140)
            love.keyreleased("d")
            assert(math.abs(player.x - 220) < 0.001 and field.collected == 1, "movement or pickup failed")
            local cameraX, cameraY = field.camera:getPosition()
            assert(cameraX == player.x and cameraY == player.y, "camera did not follow")
            love.graphics.clear()
            love.draw()
            love.graphics.present()

            love.keypressed("escape")
            love.update(1 / 60)
            love.keyreleased("escape")
            assert(#engine.sceneManager.stack == 2 and engine.sceneManager.stack[2].id == "pause")
            assert(engine.resourceManager.resources.hud.consumers[field])
            assert(engine.resourceManager.resources.hud.consumers[engine.sceneManager.stack[2].scene])
            love.keypressed("d")
            love.update(1)
            love.keyreleased("d")
            assert(math.abs(player.x - 220) < 0.001, "field updated while paused")
            love.graphics.clear()
            love.draw()
            love.graphics.present()

            love.keypressed("escape")
            love.update(1 / 60)
            love.keyreleased("escape")
            assert(#engine.sceneManager.stack == 1 and engine.resourceManager.resources.hud.consumers[field])
            love.keypressed("right")
            love.update(230 / 140)
            love.keyreleased("right")
            love.keypressed("w")
            love.update(100 / 140)
            love.keyreleased("w")
            assert(field.collected == 2, "second pickup failed")
            love.keypressed("d")
            love.update(250 / 140)
            love.keyreleased("d")
            love.keypressed("down")
            love.update(200 / 140)
            love.keyreleased("down")
            assert(field.collected == 3, "third pickup failed")
            love.graphics.clear()
            love.draw()
            love.graphics.present()
            love.keypressed("r")
            love.update(1 / 60)
            love.keyreleased("r")
            local restarted = engine.sceneManager.stack[1].scene
            assert(restarted ~= field and restarted.collected == 0, "restart failed")
            assert(not engine.resourceManager.resources.hud.consumers[field])
            assert(engine.resourceManager.resources.hud.consumers[restarted])
            love.quit()
            assert(next(engine.resourceManager.resources) == nil, "resources not released")
        end, debug.traceback)
        if not ok then
            pcall(function() engine:quit() end)
            io.stderr:write(message .. "\n")
        else
            print("collect smoke test passed")
        end
        return function() return ok and 0 or 1 end
    end
end

return Smoke
