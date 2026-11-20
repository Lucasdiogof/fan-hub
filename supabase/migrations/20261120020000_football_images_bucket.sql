-- ============================================================================
-- Bucket PÚBLICO `football-images`: escudos de times materializados pela Edge
-- Function `football-refresh` (OneFootball não manda CORS; o Web não pode
-- depender de proxy). Leitura pública (URL pública do Storage); escrita só
-- via service_role (sem policy em storage.objects para anon/authenticated).
-- Só escudos: limite de 2 MB por arquivo e apenas image/*. Idempotente; sem
-- literal de clube.
-- ============================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('football-images', 'football-images', true, 2097152, array['image/*'])
on conflict (id) do update
  set public = true,
      file_size_limit = 2097152,
      allowed_mime_types = array['image/*'];
