select distinct timestamp
from cs_completeness csc
where csc.timestamp BETWEEN :start_time ::timestamp AND :end_time ::timestamp
order by csc.timestamp asc