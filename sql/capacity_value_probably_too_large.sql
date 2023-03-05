select
    cs.node_id,
    c.name as country,
    cs.capacity::real as capacity
from
    charging_station cs
    left join country c on ST_Intersects(c.geom, cs.geom)
where
    cs.capacity ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$'
    and
    cs.capacity::real > 4
    and
    ST_Area(cs.geom) = 0