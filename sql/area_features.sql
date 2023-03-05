select
    cs.node_id,
    c.name as country,
    ST_Area(ST_Transform(cs.geom, 3857)) as area
from
    charging_station cs
    left join country c on ST_Intersects(c.geom, cs.geom)
where
    ST_Area(cs.geom) > 0