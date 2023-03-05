select
    cs.node_id,
    cs.capacity as capacity
from
    charging_station cs
where
    cs.capacity !~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$';