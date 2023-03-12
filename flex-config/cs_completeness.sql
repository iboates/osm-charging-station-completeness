drop table if exists cs_completeness;
create table cs_completeness as (
    select distinct on (cs.node_id)
        cs.node_id as node_id,
        case when cs.capacity is not null then true else false end as capacity,
        case when cs.operator is not null then true else false end as operator,
        case when s.type is not null then true else false end as socket_type,
        case when s.number is not null then true else false end as socket_number,
        case when s.output is not null then true else false end as socket_output,
        st_centroid(cs.geom) as geom
    from
        charging_station cs
    left join
        socket s on cs.node_id = s.node_id
);
alter table cs_completeness add primary key (node_id);
create index on cs_completeness using gist (geom);