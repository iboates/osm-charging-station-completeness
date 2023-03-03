local srid = 4326

local tables = {}

tables.country = osm2pgsql.define_way_table('country_pre', {
    --{ column = 'name', type = 'text' },
    --{ column = 'tags', type = 'jsonb' }--,
    { column = 'geom', type = 'linestring', projection = srid }
})

function osm2pgsql.process_way(object)

    if object:grab_tag('admin_level') == "2" then
        tables.country_pre:add_row({
            --name = object.tags["name:en"],
            geom = object.as_linestring()
        })
    end

end