CREATE OR REPLACE FUNCTION array_greatest(anyarray)
RETURNS anyelement
LANGUAGE SQL
AS $$
  SELECT max(elements) FROM unnest($1) elements
$$;

select
    -- cs.node_id,
    cs.capacity,
    array_greatest(string_to_array(trim(regexp_replace(capacity, '\D+', ',', 'g'), ','), ',')::int[]) as greatest_number_found_in_capacity,
    s.*
from
    charging_station cs
    left join socket s on cs.node_id = s.node_id
where
    array_greatest(string_to_array(trim(regexp_replace(capacity, '\D+', ',', 'g'), ','), ',')::int[]) > 50
;