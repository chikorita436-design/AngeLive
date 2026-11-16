-- =====================================================================
--  Panel autoadministrable · Landing de Ange
--  Pega TODO este script en Supabase → SQL Editor → New query → Run.
--  ANTES de ejecutarlo, cambia el correo de la línea de abajo por el
--  correo con el que ella va a entrar al panel (/admin).
-- =====================================================================

-- 1) Correo de la dueña (el único que podrá editar)
create or replace function public.es_admin() returns boolean
language sql stable as $$
  select lower(coalesce(auth.jwt() ->> 'email','')) = lower('CORREO-DE-ELLA@gmail.com')
$$;

-- 2) Tabla con el contenido de la página (una sola fila, id = 1)
create table if not exists public.sitio (
  id         int primary key,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.sitio enable row level security;

drop policy if exists "sitio: lectura publica" on public.sitio;
create policy "sitio: lectura publica" on public.sitio
  for select using (true);

drop policy if exists "sitio: solo la duena edita" on public.sitio;
create policy "sitio: solo la duena edita" on public.sitio
  for update to authenticated using (public.es_admin()) with check (public.es_admin());

-- Contenido inicial (lo mismo que tiene hoy la página)
insert into public.sitio (id, data) values (1, '{
  "nombre": "Ange",
  "usuario": "ange594",
  "link_tango": "https://www.tango.me/ange594",
  "link_telegram": "https://t.me/Sami192078",
  "frase": "Ven a verme en vivo.",
  "texto_portada": "Pasa al chat, dime hola y quédate un ratito conmigo. Te prometo muy buena compañía.",
  "texto_sobre_mi": "Transmito en vivo en Tango y me encanta que me escriban en el chat para contarme cómo les fue el día… o qué travesura traen en mente. Entra a mi directo, saluda y quédate un ratito.",
  "fotos": [
    {
      "url": "foto-1.jpg",
      "path": null
    },
    {
      "url": "foto-2.jpg",
      "path": null
    },
    {
      "url": "foto-3.jpg",
      "path": null
    },
    {
      "url": "foto-4.jpg",
      "path": null
    },
    {
      "url": "foto-5.jpg",
      "path": null
    },
    {
      "url": "foto-6.jpg",
      "path": null
    },
    {
      "url": "foto-7.jpg",
      "path": null
    }
  ],
  "video": "directo.mp4",
  "video_portada": "directo-portada.jpg",
  "video_path": null,
  "poster_path": null
}'::jsonb)
on conflict (id) do nothing;

-- 3) Carpeta pública para fotos y videos (bucket "media")
insert into storage.buckets (id, name, public)
values ('media', 'media', true)
on conflict (id) do update set public = true;

drop policy if exists "media: la duena ve sus archivos" on storage.objects;
create policy "media: la duena ve sus archivos" on storage.objects
  for select to authenticated using (bucket_id = 'media' and public.es_admin());

drop policy if exists "media: la duena sube" on storage.objects;
create policy "media: la duena sube" on storage.objects
  for insert to authenticated with check (bucket_id = 'media' and public.es_admin());

drop policy if exists "media: la duena reemplaza" on storage.objects;
create policy "media: la duena reemplaza" on storage.objects
  for update to authenticated using (bucket_id = 'media' and public.es_admin());

drop policy if exists "media: la duena borra" on storage.objects;
create policy "media: la duena borra" on storage.objects
  for delete to authenticated using (bucket_id = 'media' and public.es_admin());
