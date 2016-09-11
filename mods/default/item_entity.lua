-- mods/default/item_entity.lua

local builtin_item = minetest.registered_entities["__builtin:item"]

local item = {
	set_item = function(self, itemstring)
		builtin_item.set_item(self, itemstring)

		local stack = ItemStack(itemstring)
		local itemdef = minetest.registered_items[stack:get_name()]
		if itemdef and itemdef.groups.flammable then
			-- frequency for the ignition check will depend on flammability
			self.ignite_time = math.max(20 / itemdef.groups.flammable, 1)
		end
	end,

	on_step = function(self, dtime)
		builtin_item.on_step(self, dtime)

		if self.ignite_time then
			if self.burning then
				-- The item is currently burning! remove it after burntime expires
				self.burn_time = self.burn_time - dtime
				if self.burn_time < 0 then
					-- disappear in a smoke puff
					self.object:remove()
					local p = self.object:getpos()
					minetest.add_particlespawner({
						amount = 3,
						time = 0.1,
						minpos = {x=p.x, y=p.y, z=p.z},
						maxpos = {x=p.x, y=p.y+0.2, z=p.z},
						minacc = {x=-0.5,y=5,z=-0.5},
						maxacc = {x=0.5,y=5,z=0.5},
						minexptime = 0.1,
						minsize = 2,
						maxsize = 4,
						texture = "smoke_puff.png"
					})
				end
			else
				-- flammable, check for igniters every ignite_time interval
				self.ignite_timer = (self.ignite_timer or 0) + dtime
				if self.ignite_timer > self.ignite_time then
					self.ignite_timer = 0

					local node = minetest.get_node(self.object:getpos())
					local igniter = minetest.get_item_group(node.name, "igniter")
					if igniter > 0 then
						self.burning = true
						-- Additional burning boost if it's in lava
						igniter = igniter + minetest.get_item_group(node.name, "lava")
						self.burn_time = 20 / igniter
					end
				end
			end
		end
	end,
}

-- set defined item as new __builtin:item, with the old one as fallback table
setmetatable(item, builtin_item)
minetest.register_entity(":__builtin:item", item)

