-- Supports the aggregate-rating lookup used by Module 2 discovery.
create index feedback_attraction_id_idx on public.feedback(attraction_id);
