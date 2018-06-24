function math.sign(n) return n>0 and 1 or n<0 and -1 or 0 end

-- screen configuration
canvasResolution = {width = 320, height = 180}
canvasScale = 1
canvasOffset = {x = 0, y = 0}

configuration = {
	windowedScreenScale = 3,
	fullscreen = false,
	azerty = false
}

local mainCanvas = nil
function setupScreen()
	canvasScale = configuration.windowedScreenScale 

	if configuration.fullscreen then
		local dw, dh = love.window.getDesktopDimensions()
		--print(dw, dh)

		canvasScale = math.floor(math.min(dw / canvasResolution.width, dh / canvasResolution.height))
		canvasOffset.x = (dw - (canvasResolution.width * canvasScale)) * 0.5
		canvasOffset.y = (dh - (canvasResolution.height * canvasScale)) * 0.5
	else
		canvasOffset.x = 0
		canvasOffset.y = 0
	end

	local windowW = canvasResolution.width * canvasScale
	local windowH = canvasResolution.height * canvasScale
	love.window.setMode(windowW, windowH, {fullscreen = configuration.fullscreen})

	local formats = love.graphics.getCanvasFormats()
	if formats.normal then
		mainCanvas = love.graphics.newCanvas(canvasResolution.width, canvasResolution.height)
		mainCanvas:setFilter("nearest", "nearest")
	end
end

map = {}

function love.load()
	setupScreen()

	-- create map data
	local mapImage = love.image.newImageData("map0.png")

	map.width = mapImage:getWidth()
	map.height = mapImage:getHeight()

	for y = 0, map.height - 1 do
		for x = 0, map.width - 1 do
			local r, g, b, a = mapImage:getPixel(x, y)
			local h = a * 256

			map[x + y * map.width] = {r, g, b, h}
		end
	end
end

camera = {
	position = {x = 256, y = 50, z = 256},
	fov = 0.6 * math.pi,
	yaw = 0,
	pitch = 0,
	roll = 0
}

yBuffer = {}

body = {
	position = {
		x = 0,
		y = 128,
		z = 0,
	},

	orientation = {
		x = 0,
		y = 0,
		z = 0,
	},

	linearVelocity = {
		x = 0,
		y = 0,
		z = 64.0
	},

	angularVelocity = {
		x = 0,
		y = 0.0,
		z = 0,
	}
}

function love.update(dt)
	local speed = 18.0 * dt
	local fwd = {x = math.sin(camera.yaw), y = 0, z = math.cos(camera.yaw)}
	local right = {x = -fwd.z, y = 0, z = fwd.x}

	local acc = {
		x = 0,
		y = 0,
		z = 0
	}

	if love.keyboard.isDown("z") then
		body.orientation.x = math.max(body.orientation.x - 0.5 * dt, -math.pi * 0.15)
	elseif love.keyboard.isDown("s") then
		body.orientation.x = math.min(body.orientation.x + 0.5 * dt, math.pi * 0.15)
	else
		body.orientation.x = body.orientation.x * 0.92
	end

	if love.keyboard.isDown("q") then
		body.orientation.z = math.max(body.orientation.z - 1.5 * dt, -math.pi * 0.15)
	elseif love.keyboard.isDown("d") then
		body.orientation.z = math.min(body.orientation.z + 1.5 * dt, math.pi * 0.15)
	else
		body.orientation.z = body.orientation.z * 0.5
	end

	if love.keyboard.isDown("a") then
		acc.y = acc.y - 256.0
	end
	
	if love.keyboard.isDown("e") then
		acc.y = acc.y + 256.0
	end

	-- fwd motion
	acc.x = acc.x - body.orientation.x * fwd.x * 128.0
	acc.y = acc.y - body.orientation.x * fwd.y * 128.0
	acc.z = acc.z - body.orientation.x * fwd.z * 128.0

	-- side motion
	local rot = body.orientation.x * body.orientation.z
	--acc.x = acc.x - body.orientation.z * right.x * 32.0
	--acc.y = acc.y - body.orientation.z * right.y * 32.0
	--acc.z = acc.z - body.orientation.z * right.z * 32.0

	--body.angularVelocity.y = -rot * 2.0
	body.angularVelocity.y = body.orientation.z * 2.0

	-- air drag
	acc.x = acc.x - math.sign(body.linearVelocity.x) * (body.linearVelocity.x * body.linearVelocity.x) * 0.01
	acc.y = acc.y - math.sign(body.linearVelocity.y) * (body.linearVelocity.y * body.linearVelocity.y) * 0.1
	acc.z = acc.z - math.sign(body.linearVelocity.z) * (body.linearVelocity.z * body.linearVelocity.z) * 0.01

	body.linearVelocity.x = body.linearVelocity.x + acc.x * dt
	body.linearVelocity.y = body.linearVelocity.y + acc.y * dt
	body.linearVelocity.z = body.linearVelocity.z + acc.z * dt

	body.position.x = body.position.x + body.linearVelocity.x * dt
	body.position.y = body.position.y + body.linearVelocity.y * dt
	body.position.z = body.position.z + body.linearVelocity.z * dt

	body.orientation.x = body.orientation.x + body.angularVelocity.x * dt
	body.orientation.y = body.orientation.y + body.angularVelocity.y * dt
	body.orientation.z = body.orientation.z + body.angularVelocity.z * dt

	camera.position.x = body.position.x
	camera.position.y = body.position.y
	camera.position.z = body.position.z

	camera.pitch = body.orientation.x
	camera.yaw = body.orientation.y
	camera.roll = body.orientation.z

end

function getMapData(x, y)
	local _x = math.fmod(math.floor(x), map.width)
	if _x < 0 then _x = _x + map.width end

	local _y = math.fmod(math.floor(y), map.height)
	if _y < 0 then _y = _y + map.height end

	--local _x = math.floor(math.min(math.max(0, x), map.width - 1))
	--local _y = math.floor(math.min(math.max(0, y), map.height - 1))

	return map[_x + _y * map.width]
end

function getMapDataSmooth(x, y)
	local _x = math.floor(x)
	local _y = math.floor(y)

	local h0 = getMapData(_x, _y)
	local h1 = getMapData(_x + 1, _y)
	local h2 = getMapData(_x, _y + 1)
	local h3 = getMapData(_x + 1, _y + 1)

	local dx = x - _x
	local dy = y - _y

	local res = {}

	for i = 1,4 do
		local hh0 = h0[i] * (1 - dx) + h1[i] * dx
		local hh1 = h2[i] * (1 - dx) + h3[i] * dx
		res[i] = (hh0 * (1 - dy) + hh1 * dy)
	end

	return res
end

function love.mousemoved(x, y, dx, dy, istouch)
	if love.mouse.isDown(1) then
		camera.yaw = camera.yaw + dx * -0.01
	end 
end

function love.wheelmoved(x, y)
	camera.fov = camera.fov + y * 0.01
end

function renderVoxel(camera, scale_height, distance, screen_width, screen_height)
	-- precalculate viewing angle parameters
	local tanfov = math.tan(camera.fov * 0.5)
    local sinyaw = math.sin(camera.yaw)
    local cosyaw = math.cos(camera.yaw)
	local tanroll = math.tan(camera.roll)
	local horizon = screen_height * (0.5 + math.sin(camera.pitch))
	local hFov = screen_height / (tanfov * screen_width)

	-- initialize visibility array. Y position for each column on screen 
	for i = 0, screen_width do
		yBuffer[i] = screen_height
	end

    -- Draw from front to the back (low z coordinate to high z coordinate)
    local dz = 1.0
	local z = 1.
	local lineCount = 0

	local right = {
		x = cosyaw * tanfov * math.sqrt(1 + tanroll * tanroll),
		y = -sinyaw * tanfov * math.sqrt(1 + tanroll * tanroll),
	}

    while z < distance do
		-- Find line on map. This calculation corresponds to a field of view of 90°
		local pleft = {
			x = -right.x * z + sinyaw * z + camera.position.x, 
			y = -right.y * z + cosyaw * z + camera.position.z
		}

        local pright = {
			x = right.x * z + sinyaw * z + camera.position.x, 
			y = right.y * z + cosyaw * z + camera.position.z
		}

		--love.graphics.setColor(1, 0, 1, 1)
		--love.graphics.line(pleft.x, pleft.y, pright.x, pright.y)

		-- segment the line
        local dx = (pright.x - pleft.x) / screen_width
        local dy = (pright.y - pleft.y) / screen_width

		local fog = math.exp(-z * 0.001)
		--print(fog)

        -- Raster line and draw a vertical line for each segment
		for i = 0, screen_width do
			local data = getMapData(pleft.x, pleft.y)

			local roll = (screen_width / 2 - i) * tanroll

			local height_on_screen = ((camera.position.y - data[4]) / z) * hFov * screen_height + horizon + roll

			if height_on_screen < yBuffer[i] then
				love.graphics.setColor(data[1] * fog + 135.0 / 255.0 * (1.0 - fog), data[2] * fog + 206 / 255.0 * (1.0 - fog), data[3] * fog + 250 / 255.0 * (1.0 - fog), 1)
				love.graphics.line(i, height_on_screen, i, yBuffer[i])
	
				yBuffer[i] = height_on_screen
			end

            pleft.x = pleft.x + dx
			pleft.y = pleft.y + dy
		end

        -- Go to next line and increase step size when you are far away
		z = z + dz	
		if z > 512 then
			dz = dz + 0.2
		end
		
		lineCount = lineCount + 1
	end

	love.graphics.print(lineCount, 0, 0)
end

function love.draw()
	love.graphics.setCanvas(mainCanvas)
	love.graphics.setBackgroundColor(135.0 / 255.0, 206 / 255.0, 250 / 255.0, 1)
	love.graphics.clear()

	love.graphics.setLineStyle("rough")
	love.graphics.setLineWidth(1.0)
	renderVoxel(camera, 32.0, 4096, canvasResolution.width, canvasResolution.height)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setCanvas()
	love.graphics.draw(mainCanvas, canvasOffset.x, canvasOffset.y, 0, canvasScale, canvasScale)	
end
