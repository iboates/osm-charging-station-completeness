with base as (
    select
        node_id
    from
        cs_completeness csc,
        (select ST_GeomFromGeoJSON(

        '{ "type": "Polygon", "coordinates": [ [ [ 2.052896937216265, 49.10372838793343 ], [ 2.279508366553114, 49.037564466959168 ], [ 2.501984550829071, 49.021023486715599 ], [ 2.820398420517708, 48.896966134888856 ], [ 2.82866891063949, 48.855613684279945 ], [ 2.694686970666609, 48.736518626526276 ], [ 2.624387804631456, 48.73734567553845 ], [ 2.735212372263345, 48.496674412994572 ], [ 2.516871433048279, 48.469381795592689 ], [ 2.16124035781162, 48.602536686553393 ], [ 1.871773203549222, 48.741480920599344 ], [ 1.986733016242003, 49.061548888312338 ], [ 2.052896937216265, 49.10372838793343 ] ] ]}'

        ) as geom) sa
    where
        ST_Intersects(csc.geom, sa.geom)
)

--"socket",
--"voltage",
--"output",
--"current",

select
    'brand' as tag,
    sum(case when brand then 1 else 0 end) as present,
    sum(case when not brand then 1 else 0 end) as missing,
    null::bigint as present_in_parent
from
    base b
    left join cs_completeness csc on csc.node_id = b.node_id

union all

select
    'operator' as tag,
    sum(case when operator then 1 else 0 end) as present,
    sum(case when not operator then 1 else 0 end) as missing,
    null::bigint as present_in_parent
from
    base b
    left join cs_completeness csc on csc.node_id = b.node_id

union all

select
    'capacity' as tag,
    sum(case when capacity then 1 else 0 end) as present,
    sum(case when not capacity then 1 else 0 end) as missing,
    null::bigint as present_in_parent
from
    base b
    left join cs_completeness csc on csc.node_id = b.node_id

union all

select
    'authentication' as tag,
    sum(case when authentication then 1 else 0 end) as present,
    sum(case when not authentication then 1 else 0 end) as missing,
    null::bigint as present_in_parent
from
    base b
    left join cs_completeness csc on csc.node_id = b.node_id

union all

select
    'fee' as tag,
    sum(case when fee then 1 else 0 end) as present,
    sum(case when not fee then 1 else 0 end) as missing,
    null::bigint as present_in_parent
from
    base b
    left join cs_completeness csc on csc.node_id = b.node_id

union all

select
    'parking_fee' as tag,
    sum(case when parking_fee then 1 else 0 end) as present,
    sum(case when not parking_fee then 1 else 0 end) as missing,
    null::bigint as present_in_parent
from
    base b
    left join cs_completeness csc on csc.node_id = b.node_id

union all

select
    'maxstay' as tag,
    sum(case when maxstay then 1 else 0 end) as present,
    sum(case when not maxstay then 1 else 0 end) as missing,
    null::bigint as present_in_parent
from
    base b
    left join cs_completeness csc on csc.node_id = b.node_id

union all

select
    'opening_hours' as tag,
    sum(case when opening_hours then 1 else 0 end) as present,
    sum(case when not opening_hours then 1 else 0 end) as missing,
    null::bigint as present_in_parent
from
    base b
    left join cs_completeness csc on csc.node_id = b.node_id

union all

select
    'payment' as tag,
    sum(case when brand then 1 else 0 end) as present,
    sum(case when not brand then 1 else 0 end) as missing,
    null::bigint as present_in_parent
from
    base b
    left join cs_completeness csc on csc.node_id = b.node_id

union all

select
    ':socket:type' as tag,
    sum(case when ":socket:type" then 1 else 0 end) as present,
    sum(case when not ":socket:type" then 1 else 0 end) as missing,
    sum(case when socket then 1 else 0 end) as present_in_parent
from
    base b
    left join cs_completeness csc on csc.node_id = b.node_id