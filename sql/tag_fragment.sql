select
    '[[TAG_VALUE]]' as tag,
    sum(case when [[TAG_VALUE]] then 1 else 0 end) as present,
    sum(case when not [[TAG_VALUE]] then 1 else 0 end) as missing
from
    base b
    left join cs_completeness csc on csc.node_id = b.node_id