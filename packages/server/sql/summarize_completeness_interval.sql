with timestamps as (select distinct timestamp
                    from cs_completeness csc
                    where csc.timestamp BETWEEN :start_time ::timestamp AND :end_time ::timestamp
                    order by csc.timestamp asc),

base as (
    select
        csc.timestamp,
        node_id
    from
        timestamps,
        cs_completeness csc,
        (select ST_GeomFromGeoJSON(

            -- paris
            -- '{ "type": "Polygon", "coordinates": [ [ [ 2.052896937216265, 49.10372838793343 ], [ 2.279508366553114, 49.037564466959168 ], [ 2.501984550829071, 49.021023486715599 ], [ 2.820398420517708, 48.896966134888856 ], [ 2.82866891063949, 48.855613684279945 ], [ 2.694686970666609, 48.736518626526276 ], [ 2.624387804631456, 48.73734567553845 ], [ 2.735212372263345, 48.496674412994572 ], [ 2.516871433048279, 48.469381795592689 ], [ 2.16124035781162, 48.602536686553393 ], [ 1.871773203549222, 48.741480920599344 ], [ 1.986733016242003, 49.061548888312338 ], [ 2.052896937216265, 49.10372838793343 ] ] ]}'

            -- world
            '{ "type": "Polygon", "coordinates": [ [ [ -178.110583175489609, -64.124606182978042 ], [ -178.110583175489609, 77.811002033278356 ], [ 177.292375412511888, 76.945484633547409 ], [ 179.578415026071099, -68.096537001147169 ], [ -178.110583175489609, -64.124606182978042 ] ] ] }'

            -- custom
            -- :study_area

        ) as geom) sa
    where
        ST_Intersects(csc.geom, sa.geom)
        and
        csc.timestamp in (select timestamp from timestamps)
),

summary as (
    select
        b.timestamp, 'brand' as tag,
        sum(case when brand then 1 else 0 end) as present,
        sum(case when not brand then 1 else 0 end) as missing,
        null::bigint as present_in_parent
    from
        base b
    left join
        cs_completeness csc on csc.node_id = b.node_id
    group by
        b.timestamp

    union all

    select
        b.timestamp,
        'operator' as tag,
        sum(case when operator then 1 else 0 end) as present,
        sum(case when not operator then 1 else 0 end) as missing,
        null::bigint as present_in_parent
    from
        base b
        left join cs_completeness csc on csc.node_id = b.node_id
    group by
        b.timestamp

    union all

    select
        b.timestamp,
        'capacity' as tag,
        sum(case when capacity then 1 else 0 end) as present,
        sum(case when not capacity then 1 else 0 end) as missing,
        null::bigint as present_in_parent
    from
        base b
        left join cs_completeness csc on csc.node_id = b.node_id
    group by
        b.timestamp

        union all

    select
        b.timestamp,
        'authentication' as tag,
        sum(case when authentication then 1 else 0 end) as present,
        sum(case when not authentication then 1 else 0 end) as missing,
        null::bigint as present_in_parent
    from
        base b
        left join cs_completeness csc on csc.node_id = b.node_id
    group by
        b.timestamp

        union all

    select
        b.timestamp,
        'fee' as tag,
        sum(case when fee then 1 else 0 end) as present,
        sum(case when not fee then 1 else 0 end) as missing,
        null::bigint as present_in_parent
    from
        base b
        left join cs_completeness csc on csc.node_id = b.node_id
    group by
        b.timestamp

        union all

    select
        b.timestamp,
        'parking_fee' as tag,
        sum(case when parking_fee then 1 else 0 end) as present,
        sum(case when not parking_fee then 1 else 0 end) as missing,
        null::bigint as present_in_parent
    from
        base b
        left join cs_completeness csc on csc.node_id = b.node_id
    group by
        b.timestamp

        union all

    select
        b.timestamp,
        'maxstay' as tag,
        sum(case when maxstay then 1 else 0 end) as present,
        sum(case when not maxstay then 1 else 0 end) as missing,
        null::bigint as present_in_parent
    from
        base b
        left join cs_completeness csc on csc.node_id = b.node_id
    group by
        b.timestamp

        union all

    select
        b.timestamp,
        'opening_hours' as tag,
        sum(case when opening_hours then 1 else 0 end) as present,
        sum(case when not opening_hours then 1 else 0 end) as missing,
        null::bigint as present_in_parent
    from
        base b
        left join cs_completeness csc on csc.node_id = b.node_id
    group by
        b.timestamp

        union all

    select
        b.timestamp,
        'payment' as tag,
        sum(case when brand then 1 else 0 end) as present,
        sum(case when not brand then 1 else 0 end) as missing,
        null::bigint as present_in_parent
    from
        base b
        left join cs_completeness csc on csc.node_id = b.node_id
    group by
        b.timestamp

        union all

    select
        b.timestamp,
        ':socket:type' as tag,
        sum(case when ":socket:type" then 1 else 0 end) as present,
        sum(case when not ":socket:type" then 1 else 0 end) as missing,
        sum(case when socket then 1 else 0 end) as present_in_parent
    from
        base b
        left join cs_completeness csc on csc.node_id = b.node_id
    group by
        b.timestamp

        union all

    select
        b.timestamp,
        ':socket:type:number' as tag,
        sum(case when ":socket:type:number" then 1 else 0 end) as present,
        sum(case when not ":socket:type:number" then 1 else 0 end) as missing,
        sum(case when number then 1 else 0 end)::bigint as present_in_parent
    from
        base b
        left join cs_completeness csc on csc.node_id = b.node_id
    group by
        b.timestamp

        union all

    select
        b.timestamp,
        ':socket:type:output' as tag,
        sum(case when ":socket:type:output" then 1 else 0 end) as present,
        sum(case when not ":socket:type:output" then 1 else 0 end) as missing,
        sum(case when output then 1 else 0 end)::bigint as present_in_parent
    from
        base b
        left join cs_completeness csc on csc.node_id = b.node_id
    group by
        b.timestamp

        union all

    select
        b.timestamp,
        ':socket:type:voltage' as tag,
        sum(case when ":socket:type:voltage" then 1 else 0 end) as present,
        sum(case when not ":socket:type:voltage" then 1 else 0 end) as missing,
        sum(case when voltage then 1 else 0 end)::bigint as present_in_parent
    from
        base b
        left join cs_completeness csc on csc.node_id = b.node_id
    group by
        b.timestamp

        union all

    select
        b.timestamp,
        ':socket:type:current' as tag,
        sum(case when ":socket:type:current" then 1 else 0 end) as present,
        sum(case when not ":socket:type:current" then 1 else 0 end) as missing,
        sum(case when current then 1 else 0 end)::bigint as present_in_parent
    from
        base b
        left join cs_completeness csc on csc.node_id = b.node_id
    group by
        b.timestamp

)

select
    tag,
    array_agg(present) as present,
    array_agg(missing) as missing,
    array_agg(present_in_parent) as missing
from
    summary
group by
    tag