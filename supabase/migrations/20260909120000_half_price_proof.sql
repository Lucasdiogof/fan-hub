-- Meia-entrada: tipo (por lei / promocional) + comprovante obrigatório
-- quando "por lei" (Lei Federal 12.933/2013). Rodar em AMBOS os projetos
-- Supabase (Goiás e Bragantino) — schema convergido entre os dois clubes.

alter table public.tickets
  add column if not exists half_price_type text,
  add column if not exists half_price_proof_path text;

alter table public.tickets
  add constraint tickets_half_price_type_check
  check (half_price_type is null or half_price_type = any (array['law'::text, 'promotional'::text]));

-- Bucket PRIVADO (não `public`, diferente de `avatars`) — o comprovante é
-- documento pessoal (identidade/carteirinha), nunca deve ter URL pública.
insert into storage.buckets (id, name, public)
values ('half_price_proofs', 'half_price_proofs', false)
on conflict (id) do nothing;

drop policy if exists "half_price_proofs_write_own" on storage.objects;
create policy "half_price_proofs_write_own" on storage.objects
  for insert
  with check (bucket_id = 'half_price_proofs' and (storage.foldername(name))[1] = (auth.uid())::text);

drop policy if exists "half_price_proofs_read_own" on storage.objects;
create policy "half_price_proofs_read_own" on storage.objects
  for select
  using (bucket_id = 'half_price_proofs' and (storage.foldername(name))[1] = (auth.uid())::text);

drop policy if exists "half_price_proofs_delete_own" on storage.objects;
create policy "half_price_proofs_delete_own" on storage.objects
  for delete
  using (bucket_id = 'half_price_proofs' and (storage.foldername(name))[1] = (auth.uid())::text);
