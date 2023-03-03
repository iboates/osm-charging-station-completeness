local srid = 4326

local tables = {}

tables.country = osm2pgsql.define_way_table('country', {
    { column = 'name', type = 'text' },
    { column = 'tags', type = 'jsonb' },
    { column = 'geom', type = 'geometrycollection', projection = srid }
})

function osm2pgsql.process_relation(object)

    if object:grab_tag('admin_level') == "2" then
    tables.country:insert({
        name = object.tags["name:en"],
        tags = object.tags,
        geom = object:as_geometrycollection()
    })
    end

    -- for _, member in ipairs(object.members) do
    --     if member.type == 'w' then
    --         tables.country:insert({
    --             name = object.tags["name:en"],
    --             --tags = member.tags,
    --             geom = member:as_linestring()
    --         })
    --     end
    -- end

end