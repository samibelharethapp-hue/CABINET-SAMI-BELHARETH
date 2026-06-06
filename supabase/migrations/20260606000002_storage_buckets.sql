-- =====================================================================
-- CABINET SAMI BELHARETH — Migration Storage
-- Buckets pour imagerie médicale, documents, ordonnances, avatars
-- =====================================================================

-- ============== BUCKETS ========================================
-- Tous les buckets sont PRIVÉS sauf 'avatars'. L'accès se fait via signed URLs.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('patient-imaging', 'patient-imaging', false, 104857600, -- 100 MB max
    array['image/jpeg','image/png','image/dicom','application/dicom','application/pdf']::text[]),
  ('documents', 'documents', false, 20971520, -- 20 MB max
    array['application/pdf','image/jpeg','image/png','application/vnd.openxmlformats-officedocument.wordprocessingml.document']::text[]),
  ('prescriptions', 'prescriptions', false, 5242880, -- 5 MB max
    array['application/pdf']::text[]),
  ('quotes-invoices', 'quotes-invoices', false, 5242880, -- 5 MB max
    array['application/pdf']::text[]),
  ('rehab-videos', 'rehab-videos', false, 524288000, -- 500 MB max
    array['video/mp4','video/webm','image/jpeg','image/png']::text[]),
  ('avatars', 'avatars', true, 2097152, -- 2 MB max (public)
    array['image/jpeg','image/png','image/webp']::text[])
on conflict (id) do nothing;

-- ============================================================
-- STORAGE POLICIES — patient-imaging
-- ============================================================
-- Staff peut tout · Patient peut lire ses propres imageries (chemin: <patient_id>/...)
create policy "imaging_staff_all" on storage.objects
  for all using (
    bucket_id = 'patient-imaging' and public.is_staff()
  );

create policy "imaging_patient_read" on storage.objects
  for select using (
    bucket_id = 'patient-imaging'
    and public.is_patient_of((storage.foldername(name))[1]::uuid)
  );

-- ============================================================
-- STORAGE POLICIES — documents (certificats, lettres, CR)
-- ============================================================
create policy "documents_staff_all" on storage.objects
  for all using (
    bucket_id = 'documents' and public.is_staff()
  );

create policy "documents_patient_read" on storage.objects
  for select using (
    bucket_id = 'documents'
    and public.is_patient_of((storage.foldername(name))[1]::uuid)
  );

-- ============================================================
-- STORAGE POLICIES — prescriptions
-- ============================================================
create policy "prescriptions_staff_all" on storage.objects
  for all using (
    bucket_id = 'prescriptions' and public.is_staff()
  );

create policy "prescriptions_patient_read" on storage.objects
  for select using (
    bucket_id = 'prescriptions'
    and public.is_patient_of((storage.foldername(name))[1]::uuid)
  );

-- ============================================================
-- STORAGE POLICIES — quotes-invoices
-- ============================================================
create policy "qi_staff_all" on storage.objects
  for all using (
    bucket_id = 'quotes-invoices' and public.is_staff()
  );

create policy "qi_patient_read" on storage.objects
  for select using (
    bucket_id = 'quotes-invoices'
    and public.is_patient_of((storage.foldername(name))[1]::uuid)
  );

-- ============================================================
-- STORAGE POLICIES — rehab-videos
-- Doctor uploade · Tous les utilisateurs authentifiés lisent
-- (Les patients voient les exercices de leur programme uniquement,
-- contrôlé côté app via les signed URLs limitées dans le temps)
-- ============================================================
create policy "rehab_doctor_write" on storage.objects
  for all using (
    bucket_id = 'rehab-videos' and public.is_doctor()
  );

create policy "rehab_authenticated_read" on storage.objects
  for select using (
    bucket_id = 'rehab-videos' and auth.role() = 'authenticated'
  );

-- ============================================================
-- STORAGE POLICIES — avatars (public)
-- Chacun gère son propre avatar (chemin: <user_id>/...)
-- ============================================================
create policy "avatars_public_read" on storage.objects
  for select using (bucket_id = 'avatars');

create policy "avatars_self_write" on storage.objects
  for insert with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "avatars_self_update" on storage.objects
  for update using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "avatars_self_delete" on storage.objects
  for delete using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- ============================================================
-- 🎉 FIN MIGRATION STORAGE
-- ============================================================
-- ✅ 6 buckets créés
-- ✅ Politiques d'accès par rôle (doctor / staff / patient)
-- ✅ Structure dossier : <patient_id>/<filename> ou <user_id>/<filename>
-- ============================================================
