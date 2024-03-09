-- algae

function init()
	print("yellow world")
end

function key(n, z)
	if n == 3 and z == 1 then
		reload()
	end
end

function reload()
	norns.script.load("code/algae/algae.lua")
end

function redraw()
	screen.clear()
	screen.level(5)

	screen.move(10, 20)
	screen.font_size(15)
	screen.text("algae")

	screen.move(10, 50)
	screen.font_size(8)
	screen.text("k3: reload")

	screen.update()
end
