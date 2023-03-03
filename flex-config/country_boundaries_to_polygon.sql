drop table if exists country;
create table country as (

    with a as (
        select
            st_asewkt((st_dump(geom)).geom) as geom,
            st_geometrytype((st_dump(geom)).geom) as geom_type,
            name
        from
            country_pre
    ),

    b as (
        select
            ST_Node(st_collect(geom)) as geom,
            name
        from
            a
        where
            geom_type = 'ST_LineString'
        group by
            name
    )

    select
        (ST_Dump(st_polygonize(geom))).geom as geom,
        name
    from
        b
    group by
        name
)

drop table country_pre;