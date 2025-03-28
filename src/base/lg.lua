---Draw a filled rectangle
---@param pos pos Position to draw at
---@param width number Width of rectangle
---@param height? number Height of rectangle (defaults to width)
function love.graphics.fillRect(pos, width, height)
    love.graphics.rectangle("fill", pos.x, pos.y, width, height or width)
end

---Draw a rectangle outline
---@param pos pos Position to draw at
---@param width number Width of rectangle
---@param height? number Height of rectangle (defaults to width)
function love.graphics.outlineRect(pos, width, height)
    love.graphics.rectangle("line", pos.x, pos.y, width, height or width)
end

return love.graphics
