-- ============================================================
--  EMERGENCIA — CORRER YA en Supabase (proyecto yobhrbxrqupuqygryceb)
--  SQL Editor -> New query -> pegar TODO -> Run
--
--  Qué hace: quita el permiso de BORRADO a los clientes.
--  Por qué: hay una política antigua "FOR ALL" que permite DELETE, y
--  el código viejo de la app borra de la nube todo lo que no esté en
--  el dispositivo. Eso es lo que se llevó los registros.
--
--  NO borra datos. NO bloquea guardar. Solo impide borrar.
-- ============================================================

do $$
declare t text; p record;
begin
  foreach t in array array['clinical_records','hyperbaric_patients','hyperbaric_sessions']
  loop
    execute format('alter table public.%I enable row level security;', t);

    -- Quitar TODAS las políticas existentes, se llamen como se llamen.
    -- (La vieja "Acceso Publico HC" era FOR ALL, e incluía DELETE.)
    for p in select policyname from pg_policies
             where schemaname='public' and tablename=t
    loop
      execute format('drop policy if exists %I on public.%I;', p.policyname, t);
    end loop;

    -- Recrear solo lo necesario: leer, insertar y actualizar. Nunca borrar.
    execute format('create policy sinergia_select on public.%I for select to anon, authenticated using (true);', t);
    execute format('create policy sinergia_insert on public.%I for insert to anon, authenticated with check (true);', t);
    execute format('create policy sinergia_update on public.%I for update to anon, authenticated using (true) with check (true);', t);
    -- Sin política DELETE: ningún cliente puede borrar, ni con código viejo.
  end loop;
end $$;

-- Verificar que NO quede ninguna política que permita DELETE:
select tablename, policyname, cmd
from pg_policies
where schemaname='public'
  and tablename in ('clinical_records','hyperbaric_patients','hyperbaric_sessions')
order by tablename, cmd;
