select
    cs.node_id,
    'polygon_but_area_too_small' as reason,
    cs.capacity,
    ST_Area(ST_Transform(cs.geom, 3857)) as area_3857
from
    charging_station cs
where
    ST_Area(cs.geom) < 100 and ST_Area(cs.geom) > 0

union all

select
    cs.node_id,
    'capacity_suspiciously_high' as reason,
    cs.capacity,
    ST_Area(ST_Transform(cs.geom, 3857)) as area_3857
from
    charging_station cs
where
    cs.capacity ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$'
    and
    cs.capacity::real > 4
    and
    ST_Area(cs.geom) = 0