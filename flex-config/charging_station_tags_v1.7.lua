local srid = 4326

local tables = {}

tables.charging_station = osm2pgsql.define_node_table('charging_station', {
    { column = 'brand', type = 'text' },
    { column = 'operator', type = 'text' },
    { column = 'network', type = 'text' },
    { column = 'capacity', type = 'text' },
    { column = 'ref', type = 'text' },
    { column = 'voltage', type = 'text' },
    { column = 'socket', type = 'text' },
    { column = 'authentication', type = 'text' },
    { column = 'fee', type = 'text' },
    { column = 'parking_fee', type = 'text' },
    { column = 'maxstay', type = 'text' },
    { column = 'opening_hours', type = 'text' },
    { column = 'payment', type = 'text' },
    { column = 'tags', type = 'jsonb' },
    { column = 'geom', type = 'point', projection = srid }
})

tables.socket = osm2pgsql.define_node_table('socket', {
    { column = 'content', type = 'text' },
    { column = 'type', type = 'text' },
    { column = 'number', type = 'text' },
    { column = 'current', type = 'text' },
    { column = 'output', type = 'text' },
    { column = 'voltage', type = 'text' },
    { column = 'geom', type = 'point', projection = srid }
})

tables.country_pre = osm2pgsql.define_way_table('country_pre', {
    { column = 'name', type = 'text' },
    { column = 'tags', type = 'jsonb' },
    { column = 'geom', type = 'geometrycollection', projection = srid }
})

function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end


function osm2pgsql.process_node(object)

    if not object.tags.amenity or object.tags.amenity ~= 'charging_station' then
        return
    end

    tables.charging_station:insert({
        brand = object.tags.brand,
        operator = object.tags.operator,
        network = object.tags.network,
        capacity = object.tags.capacity,
        ref = object.tags.ref,
        voltage = object.tags.voltage,
        socket = object.tags.socket,
        authentication = object.tags.authentication,
        fee = object.tags.fee,
        parking_fee = object.tags.parking_fee,
        maxstay = object.tags.maxstay,
        opening_hours = object.tags.opening_hours,
        payment = object.tags.payment,
        tags = object.tags,
        geom = object.as_point()
    })

    content = nil
    type = nil
    number = nil
    current = nil
    output = nil
    voltage = nil

    socket_types = {}
    i = 0

    -- look for socket types
    for k, v in pairs(object.tags) do
        if k ~= "socket" then
            if osm2pgsql.has_prefix(k, "socket") then
                socket_type = string.match(k, "socket:(%w+)")
                if not has_value(socket_types, socket_type) then
                    -- socket:type2
                    socket_types[i] = socket_type
--                     tables.socket_type:insert({
--                         type = socket_type
--                     })
                    i = i + 1
                end
            end
        end
    end

    content = object.tags.socket

    -- look for any socket properties
    for k, socket_type in pairs(socket_types) do

        number = object.tags["socket:"..socket_type]
        current = object.tags["socket:"..socket_type..":current"]
        output = object.tags["socket:"..socket_type..":output"]
        voltage = object.tags["socket:"..socket_type..":voltage"]
        tables.socket:insert({
            content = content,
            type = socket_type,
            number = number,
            current = current,
            output = output,
            voltage = voltage,
            geom = object.as_point()
        })

    end

end

function osm2pgsql.process_way(object)

tables.country_pre:insert({
    name = object.tags["name:en"],
    geom = object.as_polygon()

})

end

function osm2pgsql.process_relation(object)

    if object:grab_tag('admin_level') == "2" then
    tables.country_pre:insert({
        name = object.tags["name:en"],
        tags = object.tags,
        geom = object:as_geometrycollection()
    })
    end

end