drop table if exists cs_completeness;
create table cs_completeness as (
    select distinct on (cs.node_id)
        cs.node_id as node_id,
        case when cs.brand is not null then true else false end as brand,
        case when cs.operator is not null then true else false end as operator,
        case when cs.capacity is not null then true else false end as capacity,
        case when cs.authentication is not null then true else false end as authentication,
        case when cs.fee is not null then true else false end as fee,
        case when cs.parking_fee is not null then true else false end as parking_fee,
        case when cs.maxstay is not null then true else false end as maxstay,
        case when cs.opening_hours is not null then true else false end as opening_hours,
        case when cs.payment is not null then true else false end as payment,
        case when cs.socket is not null then true else false end as socket,
        case when cs.voltage is not null then true else false end as voltage,
        case when cs.output is not null then true else false end as output,
        case when cs.current is not null then true else false end as current,
        case when s.type is not null then true else false end as ":socket:type",
        case when s.number is not null then true else false end as ":socket:type:number",
        case when s.output is not null then true else false end as ":socket:type:output",
        case when s.voltage is not null then true else false end as ":socket:type:voltage",
        case when s.current is not null then true else false end as ":socket:type:current",
        st_centroid(cs.geom) as geom
    from
        charging_station cs
    left join
        socket s on cs.node_id = s.node_id
);
alter table cs_completeness add primary key (node_id);
create index on cs_completeness using gist (geom);