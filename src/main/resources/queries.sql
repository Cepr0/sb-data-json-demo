create extension pg_trgm;
create extension btree_gin;

drop index if exists parent_name_idx;
create index parent_name_idx on parents (name);

drop index if exists parent_name_pattern_idx;
create index parent_name_pattern_idx on parents (name text_pattern_ops);

drop index if exists parent_name_trigram_gin_idx;
create index parent_name_trigram_gin_idx on parents using gin (name gin_trgm_ops);

drop index if exists parent_name_trigram_gist_idx;
create index parent_name_trigram_gist_idx on parents using gist (name gist_trgm_ops);

drop index if exists parent_phones_gin_idx;
create index parent_phones_gin_idx on parents using gin (phones);

drop index if exists parent_translate_with_cast_as_text_phones_gin_trigram_idx;
create index parent_translate_with_cast_as_text_phones_gin_trigram_idx on parents
using gin (translate(cast(phones as text), ' +-.()[]', '') gin_trgm_ops);

create or replace function json2arr(_j jsonb, _key text)
  returns text[] language sql immutable as
'select array(select elem->>_key from jsonb_array_elements(_j) elem)';

drop index if exists parent_json2arr_children_name_gin_idx;
create index parent_json2arr_children_name_gin_idx on parents using gin (json2arr(children, 'name'));

create or replace function json2text(_j jsonb, _key text)
  returns text language sql immutable as
'select cast(array(select elem->>_key from jsonb_array_elements(_j) elem) as text)';

drop index if exists parent_child_name_json2text_trigram_gin_idx;
create index parent_child_name_json2text_trigram_gin_idx on parents using gin (json2text(children, 'name') gin_trgm_ops);

drop index if exists parent_child_gender_json2text_trigram_gin_idx;
create index parent_child_gender_json2text_trigram_gin_idx on parents using gin (json2text(children, 'gender') gin_trgm_ops);


drop index if exists parent_child_name_json2arr_text_trigram_gist_idx;
create index parent_child_name_json2arr_text_trigram_gist_idx on parents using gist (json2arr_text(children, 'name') gist_trgm_ops);

drop index if exists parent_child_gender_json2arr_gin_idx;
create index parent_child_gender_json2arr_gin_idx on parents using gin(json2arr(children, 'gender'));

drop index if exists parent_children_gin_jsonb_path_ops_idx;
create index parent_children_gin_jsonb_path_ops_idx on parents using gin (children jsonb_path_ops);

create or replace function json2tsvector(_json jsonb)
  returns tsvector language sql immutable as
'select to_tsvector(cast(_json as text))';


drop index if exists parent_children_gist_json2tsvector_idx;
create index parent_children_gist_json2tsvector_idx on parents using gist (json2tsvector(children));

---------------

explain analyze select * from parents p order by p.id limit 20;
explain analyze select * from parents p order by p.name desc limit 20 offset 10000;

explain analyze select * from parents p where p.id = 3;

explain analyze select * from parents p where p.name like '%elda Ha%';
explain analyze select * from parents p where p.name ~* 'zelda h';
explain analyze select * from parents p where p.name = 'Zelda Hartmann';
select set_limit(0.5);
explain analyze select * from parents p where p.name % 'sa funk';

explain analyze select p.* from parents p where p.phones ? '1-430-038-3694';
explain analyze select p.* from parents p where translate(cast(phones as text), ' +-.()[]', '') ~ '299677';

explain analyze select * from parents p
where p.name ~* 'zelda h' and translate(cast(phones as text), ' +-.()[]', '') ~ '77';

explain analyze select p.* from parents p where json2arr(p.children, 'name') @> '{Leon}';

explain analyze select p.* from parents p where json2arr(p.children, 'gender') @> '{MALE}';

explain analyze select json2text(p.children, 'name'), p.* from parents p where json2text(p.children, 'name') ~* 'helen';
explain analyze select json2text(p.children, 'gender'), p.* from parents p where json2text(p.children, 'gender') ~ '[[:<:]]FEMALE[[:>:]]' limit 20;

--------------

create or replace function json2jarr(_j jsonb, _key text)
  returns jsonb language sql immutable as
'select to_jsonb(array(select elem->>_key from jsonb_array_elements(_j) elem))';

drop index if exists parent_children_json2jarr_name_gin_idx;
create index parent_children_json2jarr_name_gin_idx on parents using gin (json2jarr(children, 'name'));

explain analyze select p.* from parents p where json2jarr(p.children, 'name') ? 'Helen';

--------------
explain analyze
select
  json2tsvector(p.children),
  p.*
from
  parents p
where
  json2tsvector(p.children) @@ to_tsquery('hellen')
order by
  p.name
limit 20;

explain analyze
select distinct
  p.*
from
  parents p
  left join jsonb_array_elements(p.children) c on true
where
  json2text(p.children, 'name') ~* 'olga'
  and
  translate(cast(phones as text), ' +-.()[]', '') ~ '776'
  and
  --   (child->>'age')::int > 15
  --   and
  json2arr(p.children, 'gender') @> '{MALE}'
  and
  (c ->> 'birthDate')::date between '2000-01-01' and '2010-12-31'
  order by
    p.name
limit 20 offset 0;

explain analyze
select distinct
  p.*
from
  parents p, jsonb_array_elements(p.children) c
where
  (c ->> 'age')::int between 10 and 12;

explain analyze
select
  p.*
from
  parents p
where exists(
  select from jsonb_array_elements(p.children) c
--   where (c ->> 'age')::int between 10 and 12
  where (c->>'birthDate')::date between '2000-01-01' and '2010-12-31'
) limit 20 offset 100;

explain analyze
with t as (select id, jsonb_array_elements(children) as c from parents)
select
  *
from
  parents
where
  id in (select id from t where (c->>'age')::int between 10 and 12);


explain analyze
select distinct
  p.*
from
  parents p, jsonb_array_elements(p.children) c
where
  p.name ~* 'olga'
    and
  (c->>'age')::int between 10 and 12
order by p.id;

---------------

drop index if exists parent_children_gin_idx;
create index parent_children_gin_idx on parents using gin (children);

---------------

drop index if exists parent_children_trigram_idx;
create index parent_children_trigram_idx on parents using gin (cast(name as text) gin_trgm_ops);

drop index if exists parent_children_gin_idx;
create index parent_children_gin_idx on parents using gin (children);

drop index if exists parent_children_name_gin_idx;
create index parent_children_name_gin_idx on parents using gin ((children->'name'));


explain analyze
select
  p.*
from
  parents p, unnest(p.phones) phone
where
  phone = '+1234567'
;

explain analyze
select
  p.*
from
  parents p
where
  p.phones @> '{+1234567}'
;

explain analyze
select
  p.*
from
  parents p, jsonb_array_elements(p.children) c, jsonb_array_elements(p.phones) phone
where
  c->>'name' ~ '[34]'
  and phone::text ~ '345'
order by
  name
limit 20;
offset 10000;

select set_limit(0.8);
explain analyze
select
  similarity(p1.name, p2.name) as sim, p1.name, p2.name
from
  parents p1
  join parents p2 on p1.name <> p2.name and p1.name % p2.name
order by sim;

select set_limit(0.8);
explain analyse
select
  *
from
  parents p
where
  p.name % 'parent22';

explain analyse
select
  *
from
  parents p, unnest(p.phones) phone
where
  phone % '12345';

explain analyze
select
  p.*
from
  parents p
where
  p.children @> '[{"name": "child1_1000"}]'
;

explain analyze
select
  p.*
from
  parents p
where
  json2arr(p.children, 'name') @> '{child1_1000}';
;

select p.* from parents p where p.phones::text[] @> cast('{+1234567}' as text[]);

explain analyze
select
  p.*
from
  parents p
where
  p.children::text like 'child1_4567%'
;

explain analyze
select
  p.*,
  json2arr(p.children, 'name')::text
from
  parents p
where
  p.children @> cast('[{"name": "child1_1000"}]' as jsonb);
;

create or replace function json2arr_text(_j jsonb, _key text)
  returns text language sql immutable as
'select cast(ARRAY(select elem ->> _key from jsonb_array_elements(_j) elem) as text)';

drop index if exists parent_child_name_pattern_idx;
create index parent_child_name_pattern_idx on parents (json2arr_text(children, 'name') text_pattern_ops);

drop index if exists parent_child_name_json2arr_text_trigram_gin_idx;
create index parent_child_name_json2arr_text_trigram_gin_idx on parents using gin (json2arr_text(children, 'name') gin_trgm_ops);

drop index if exists parent_child_name_json2arr_text_trigram_gist_idx;
create index parent_child_name_json2arr_text_trigram_gist_idx on parents using gist (json2arr_text(children, 'name') gist_trgm_ops);

drop index if exists parent_child_gender_json2arr_gin_idx;
create index parent_child_gender_json2arr_gin_idx on parents using gin (json2arr(children, 'gender'));

select set_limit(0.8);
explain analyze
select
  p.*,
  json2arr_text(p.children, 'name')
from
  parents p
where
  json2arr_text(p.children, 'name') % 'child1_1111'
  and
  json2arr(children, 'gender') @> '{MALE}'
limit 20
;


