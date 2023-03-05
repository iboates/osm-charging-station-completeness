select
    -- cs.node_id,
    c.name as country,
    cs.capacity as capacity,
    count(cs.capacity) as num
from
    charging_station cs
--     left join socket s on cs.node_id = s.node_id
    left join country c on ST_Intersects(c.geom, cs.geom)
where
    lower(c.name) like '%germany%'
group by
    c.name,
    cs.capacity
order by
    c.name asc,
    num desc
;