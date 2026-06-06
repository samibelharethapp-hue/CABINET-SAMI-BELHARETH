-- =====================================================================
-- CABINET SAMI BELHARETH — Migration initiale
-- Base de données médicale orthopédie (Tunisie · CNAM)
-- Date    : 2026-06-06
-- Tables  : 18 + 1 vue + helpers RLS
-- Sécurité: Row Level Security activé sur toutes les tables sensibles
-- =====================================================================

-- ============== EXTENSIONS =====================================
create extension if not exists "pgcrypto";   -- gen_random_uuid()
create extension if not exists "citext";     -- emails case-insensitive
create extension if not exists "pg_trgm";    -- recherche floue patients

-- ============== ENUMS ==========================================
create type user_role        as enum ('doctor', 'staff', 'patient');
create type gender_t         as enum ('M', 'F');
create type appointment_type as enum ('consultation', 'control', 'preop', 'postop', 'emergency');
create type appointment_status as enum ('scheduled','confirmed','in_progress','completed','cancelled','no_show');
create type surgery_side     as enum ('left', 'right', 'bilateral');
create type anesthesia_t     as enum ('general', 'spinal', 'epidural', 'local', 'regional');
create type surgery_status   as enum ('scheduled', 'in_progress', 'completed', 'cancelled');
create type pec_status       as enum ('pending', 'submitted', 'approved', 'rejected');
create type invoice_status   as enum ('unpaid', 'partial', 'paid', 'cancelled');
create type quote_status     as enum ('draft', 'sent', 'signed', 'invoiced', 'cancelled', 'refused');
create type payment_method   as enum ('cash','card','transfer','cnam','konnect','flouci','check');
create type history_category as enum ('medical', 'surgical', 'allergy', 'familial');
create type history_severity as enum ('low', 'medium', 'high', 'critical');
create type imaging_t        as enum ('xray', 'ct', 'mri', 'ultrasound', 'other');
create type document_t       as enum ('certificate', 'work_leave', 'sport_exemption', 'letter', 'report', 'other');

-- ============== TABLE: profiles ================================
-- Tous les utilisateurs (medecin, secretaire, patient)
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  role        user_role not null default 'patient',
  first_name  text not null,
  last_name   text not null,
  phone       text,
  email       citext,
  avatar_url  text,
  preferences jsonb default '{}'::jsonb,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

create index idx_profiles_role on public.profiles(role);

-- ============== TABLE: patients ================================
create table public.patients (
  id                       uuid primary key default gen_random_uuid(),
  profile_id               uuid references public.profiles(id) on delete set null,
  first_name               text not null,
  last_name                text not null,
  date_of_birth            date not null,
  gender                   gender_t,
  phone                    text,
  email                    citext,
  address                  text,
  city                     text,
  cnam_id                  text,
  cnam_active              boolean default false,
  blood_group              text,
  height_cm                int,
  weight_kg                numeric(5,2),
  profession               text,
  emergency_contact_name   text,
  emergency_contact_phone  text,
  notes                    text,
  search_vector            tsvector,
  created_at               timestamptz default now(),
  updated_at               timestamptz default now(),
  created_by               uuid references public.profiles(id),
  deleted_at               timestamptz
);

create index idx_patients_lastname  on public.patients using gin (last_name gin_trgm_ops);
create index idx_patients_firstname on public.patients using gin (first_name gin_trgm_ops);
create index idx_patients_phone     on public.patients(phone);
create index idx_patients_cnam      on public.patients(cnam_id);
create index idx_patients_search    on public.patients using gin (search_vector);
create index idx_patients_not_del   on public.patients(deleted_at) where deleted_at is null;

-- Trigger pour search_vector
create or replace function public.patients_search_update()
returns trigger language plpgsql as $$
begin
  new.search_vector :=
    setweight(to_tsvector('simple', coalesce(new.last_name,'')), 'A') ||
    setweight(to_tsvector('simple', coalesce(new.first_name,'')), 'A') ||
    setweight(to_tsvector('simple', coalesce(new.phone,'')), 'B') ||
    setweight(to_tsvector('simple', coalesce(new.cnam_id,'')), 'B');
  return new;
end$$;

create trigger trg_patients_search
  before insert or update on public.patients
  for each row execute function public.patients_search_update();

-- ============== TABLE: medical_history =========================
create table public.medical_history (
  id          uuid primary key default gen_random_uuid(),
  patient_id  uuid not null references public.patients(id) on delete cascade,
  category    history_category not null,
  label       text not null,
  details     text,
  year        int,
  severity    history_severity,
  created_at  timestamptz default now()
);

create index idx_history_patient on public.medical_history(patient_id);

-- ============== TABLE: appointments ============================
create table public.appointments (
  id               uuid primary key default gen_random_uuid(),
  patient_id       uuid not null references public.patients(id) on delete cascade,
  doctor_id        uuid references public.profiles(id),
  type             appointment_type not null default 'consultation',
  reason           text,
  scheduled_at     timestamptz not null,
  duration_minutes int default 30,
  status           appointment_status not null default 'scheduled',
  arrived_at       timestamptz,
  started_at       timestamptz,
  ended_at         timestamptz,
  notes            text,
  created_at       timestamptz default now(),
  updated_at       timestamptz default now()
);

create index idx_appointments_date     on public.appointments(scheduled_at);
create index idx_appointments_patient  on public.appointments(patient_id);
create index idx_appointments_status   on public.appointments(status);

-- ============== TABLE: consultations ===========================
create table public.consultations (
  id                 uuid primary key default gen_random_uuid(),
  patient_id         uuid not null references public.patients(id) on delete cascade,
  doctor_id          uuid references public.profiles(id),
  appointment_id     uuid references public.appointments(id),
  consultation_date  timestamptz not null default now(),
  reason             text,
  pain_eva           int check (pain_eva between 0 and 10),
  flexion_degrees    int,
  extension_degrees  int,
  rotation_internal  int,
  rotation_external  int,
  observations       text,
  diagnosis          text,
  diagnosis_icd10    text,
  pathology          text,
  treatment_plan     text,
  duration_minutes   int,
  created_at         timestamptz default now()
);

create index idx_consultations_patient on public.consultations(patient_id);
create index idx_consultations_date    on public.consultations(consultation_date desc);

-- ============== TABLE: prescriptions ===========================
create table public.prescriptions (
  id              uuid primary key default gen_random_uuid(),
  consultation_id uuid references public.consultations(id) on delete cascade,
  patient_id      uuid not null references public.patients(id),
  doctor_id       uuid references public.profiles(id),
  issue_date      date not null default current_date,
  pdf_url         text,
  notes           text,
  created_at      timestamptz default now()
);

create table public.prescription_items (
  id              uuid primary key default gen_random_uuid(),
  prescription_id uuid not null references public.prescriptions(id) on delete cascade,
  medication_name text not null,
  dosage          text,
  frequency       text,
  duration        text,
  quantity        int,
  instructions    text,
  order_index     int default 0
);

create index idx_prescriptions_patient on public.prescriptions(patient_id);

-- ============== TABLE: surgeries ===============================
create table public.surgeries (
  id                       uuid primary key default gen_random_uuid(),
  patient_id               uuid not null references public.patients(id),
  doctor_id                uuid references public.profiles(id),
  type                     text not null,
  side                     surgery_side,
  scheduled_date           timestamptz not null,
  clinic                   text,
  operating_room           text,
  anesthesia               anesthesia_t,
  cnam_code                text,
  status                   surgery_status not null default 'scheduled',
  preop_assessment_complete boolean default false,
  cnam_pec_status          pec_status,
  implant_details          jsonb,
  cro_text                 text,
  cro_pdf_url              text,
  completed_at             timestamptz,
  created_at               timestamptz default now()
);

create index idx_surgeries_patient on public.surgeries(patient_id);
create index idx_surgeries_date    on public.surgeries(scheduled_date);

-- ============== TABLE: quotes (devis) ==========================
create table public.quotes (
  id               uuid primary key default gen_random_uuid(),
  number           text unique not null,
  patient_id       uuid not null references public.patients(id),
  surgery_id       uuid references public.surgeries(id),
  issue_date       date not null default current_date,
  expiry_date      date,
  total_ttc        numeric(10,2) not null,
  cnam_covered     numeric(10,2),
  patient_share    numeric(10,2),
  deposit_required numeric(10,2),
  status           quote_status not null default 'draft',
  pdf_url          text,
  signed_at        timestamptz,
  created_at       timestamptz default now()
);

create table public.quote_lines (
  id          uuid primary key default gen_random_uuid(),
  quote_id    uuid not null references public.quotes(id) on delete cascade,
  description text not null,
  unit_price  numeric(10,2) not null,
  quantity    int not null default 1,
  total       numeric(10,2) not null,
  order_index int default 0
);

create index idx_quotes_patient on public.quotes(patient_id);
create index idx_quotes_number  on public.quotes(number);

-- ============== TABLE: invoices ================================
create table public.invoices (
  id          uuid primary key default gen_random_uuid(),
  number      text unique not null,
  patient_id  uuid not null references public.patients(id),
  quote_id    uuid references public.quotes(id),
  issue_date  date not null default current_date,
  due_date    date,
  total_ttc   numeric(10,2) not null,
  amount_paid numeric(10,2) default 0,
  status      invoice_status not null default 'unpaid',
  pdf_url     text,
  created_at  timestamptz default now()
);

create index idx_invoices_patient on public.invoices(patient_id);
create index idx_invoices_status  on public.invoices(status);

-- ============== TABLE: payments ================================
create table public.payments (
  id          uuid primary key default gen_random_uuid(),
  invoice_id  uuid references public.invoices(id),
  patient_id  uuid references public.patients(id),
  amount      numeric(10,2) not null,
  method      payment_method not null,
  reference   text,
  paid_at     timestamptz not null default now(),
  received_by uuid references public.profiles(id),
  notes       text
);

create index idx_payments_invoice on public.payments(invoice_id);
create index idx_payments_date    on public.payments(paid_at desc);

-- ============== TABLE: cnam_pec ================================
create table public.cnam_pec (
  id               uuid primary key default gen_random_uuid(),
  patient_id       uuid not null references public.patients(id),
  surgery_id       uuid references public.surgeries(id),
  act_code         text not null,
  act_label        text not null,
  request_date     date not null default current_date,
  status           pec_status not null default 'pending',
  submitted_at     timestamptz,
  approved_at      timestamptz,
  cnam_reference   text,
  rejection_reason text,
  pdf_url          text,
  documents        jsonb,
  created_at       timestamptz default now()
);

create index idx_cnam_patient on public.cnam_pec(patient_id);
create index idx_cnam_status  on public.cnam_pec(status);

-- ============== TABLE: imaging =================================
create table public.imaging (
  id                uuid primary key default gen_random_uuid(),
  patient_id        uuid not null references public.patients(id) on delete cascade,
  type              imaging_t not null,
  body_part         text,
  side              surgery_side,
  exam_date         date not null,
  center_name       text,
  radiologist       text,
  findings          text,
  conclusion        text,
  files             jsonb,
  dicom_series_url  text,
  created_at        timestamptz default now()
);

create index idx_imaging_patient on public.imaging(patient_id);
create index idx_imaging_date    on public.imaging(exam_date desc);

-- ============== TABLE: lab_results =============================
create table public.lab_results (
  id              uuid primary key default gen_random_uuid(),
  patient_id      uuid not null references public.patients(id) on delete cascade,
  exam_date       date not null,
  lab_name        text,
  results         jsonb,
  abnormal_flags  text[],
  pdf_url         text,
  created_at      timestamptz default now()
);

create index idx_lab_patient on public.lab_results(patient_id);

-- ============== TABLE: documents ===============================
create table public.documents (
  id           uuid primary key default gen_random_uuid(),
  patient_id   uuid references public.patients(id) on delete cascade,
  type         document_t not null,
  title        text not null,
  content      text,
  template_id  uuid,
  pdf_url      text,
  issued_by    uuid references public.profiles(id),
  issued_date  date not null default current_date,
  created_at   timestamptz default now()
);

create index idx_documents_patient on public.documents(patient_id);

-- ============== TABLE: rehab_programs ==========================
create table public.rehab_programs (
  id                  uuid primary key default gen_random_uuid(),
  patient_id          uuid not null references public.patients(id),
  surgery_id          uuid references public.surgeries(id),
  pathology           text not null,
  start_date          date not null,
  duration_weeks      int,
  total_sessions      int,
  sessions_completed  int default 0,
  physio_id           uuid,
  status              text default 'active',
  created_at          timestamptz default now()
);

create table public.rehab_exercises (
  id                  uuid primary key default gen_random_uuid(),
  program_id          uuid not null references public.rehab_programs(id) on delete cascade,
  name                text not null,
  description         text,
  video_url           text,
  sets                int,
  reps                int,
  duration_seconds    int,
  frequency_per_day   int default 1,
  order_index         int default 0
);

create table public.rehab_sessions (
  id                  uuid primary key default gen_random_uuid(),
  program_id          uuid references public.rehab_programs(id),
  patient_id          uuid references public.patients(id),
  session_date        date not null default current_date,
  exercises_completed jsonb,
  pain_eva            int check (pain_eva between 0 and 10),
  notes               text,
  created_at          timestamptz default now()
);

-- ============== TABLE: message_threads / messages ==============
create table public.message_threads (
  id              uuid primary key default gen_random_uuid(),
  patient_id      uuid not null references public.patients(id) on delete cascade,
  last_message_at timestamptz default now(),
  unread_doctor   int default 0,
  unread_patient  int default 0,
  created_at      timestamptz default now()
);

create table public.messages (
  id              uuid primary key default gen_random_uuid(),
  thread_id       uuid not null references public.message_threads(id) on delete cascade,
  sender_id       uuid references public.profiles(id),
  sender_role     user_role,
  content         text,
  attachment_url  text,
  attachment_type text,
  is_read         boolean default false,
  read_at         timestamptz,
  created_at      timestamptz default now()
);

create index idx_messages_thread on public.messages(thread_id, created_at desc);

-- ============== TABLE: audit_log ===============================
create table public.audit_log (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references public.profiles(id),
  action        text not null,
  resource_type text not null,
  resource_id   uuid not null,
  changes       jsonb,
  ip_address    inet,
  user_agent    text,
  created_at    timestamptz default now()
);

create index idx_audit_resource on public.audit_log(resource_type, resource_id);
create index idx_audit_user     on public.audit_log(user_id, created_at desc);

-- ============== TABLE: cnam_acts_catalog (référentiel) ==========
create table public.cnam_acts_catalog (
  id          uuid primary key default gen_random_uuid(),
  code        text unique not null,
  label       text not null,
  category    text,
  base_price  numeric(10,2),
  covered     boolean default true,
  created_at  timestamptz default now()
);

-- ============================================================
-- HELPERS RLS — Fonctions de rôle
-- ============================================================
create or replace function public.is_doctor()
returns boolean language sql stable security definer as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'doctor'
  )
$$;

create or replace function public.is_staff()
returns boolean language sql stable security definer as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('doctor', 'staff')
  )
$$;

create or replace function public.is_patient_of(p_patient_id uuid)
returns boolean language sql stable security definer as $$
  select exists (
    select 1 from public.patients
    where id = p_patient_id and profile_id = auth.uid()
  )
$$;

-- ============================================================
-- TRIGGER générique updated_at
-- ============================================================
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end$$;

create trigger trg_profiles_upd     before update on public.profiles      for each row execute function public.set_updated_at();
create trigger trg_patients_upd     before update on public.patients      for each row execute function public.set_updated_at();
create trigger trg_appointments_upd before update on public.appointments  for each row execute function public.set_updated_at();

-- ============================================================
-- RLS — Activation sur toutes les tables sensibles
-- ============================================================
alter table public.profiles            enable row level security;
alter table public.patients            enable row level security;
alter table public.medical_history     enable row level security;
alter table public.appointments        enable row level security;
alter table public.consultations       enable row level security;
alter table public.prescriptions       enable row level security;
alter table public.prescription_items  enable row level security;
alter table public.surgeries           enable row level security;
alter table public.quotes              enable row level security;
alter table public.quote_lines         enable row level security;
alter table public.invoices            enable row level security;
alter table public.payments            enable row level security;
alter table public.cnam_pec            enable row level security;
alter table public.imaging             enable row level security;
alter table public.lab_results         enable row level security;
alter table public.documents           enable row level security;
alter table public.rehab_programs      enable row level security;
alter table public.rehab_exercises     enable row level security;
alter table public.rehab_sessions      enable row level security;
alter table public.message_threads     enable row level security;
alter table public.messages            enable row level security;
alter table public.audit_log           enable row level security;

-- ============================================================
-- POLICIES — profiles
-- ============================================================
create policy "profiles_own_select" on public.profiles
  for select using (id = auth.uid());

create policy "profiles_staff_select_all" on public.profiles
  for select using (public.is_staff());

create policy "profiles_own_update" on public.profiles
  for update using (id = auth.uid());

create policy "profiles_insert_self" on public.profiles
  for insert with check (id = auth.uid());

-- ============================================================
-- POLICIES — patients
-- ============================================================
create policy "patients_staff_all" on public.patients
  for all using (public.is_staff()) with check (public.is_staff());

create policy "patients_self_read" on public.patients
  for select using (profile_id = auth.uid());

create policy "patients_self_update_limited" on public.patients
  for update using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

-- ============================================================
-- POLICIES — données médicales (medical_history, consultations, prescriptions, surgeries, imaging, lab_results, documents)
-- Staff: tout · Patient: ses propres données uniquement
-- ============================================================
create policy "history_staff" on public.medical_history for all using (public.is_staff()) with check (public.is_staff());
create policy "history_patient_read" on public.medical_history for select using (public.is_patient_of(patient_id));

create policy "consult_staff" on public.consultations for all using (public.is_staff()) with check (public.is_staff());
create policy "consult_patient_read" on public.consultations for select using (public.is_patient_of(patient_id));

create policy "presc_staff" on public.prescriptions for all using (public.is_staff()) with check (public.is_staff());
create policy "presc_patient_read" on public.prescriptions for select using (public.is_patient_of(patient_id));

create policy "presc_items_staff" on public.prescription_items for all using (public.is_staff()) with check (public.is_staff());
create policy "presc_items_patient_read" on public.prescription_items for select using (
  exists (select 1 from public.prescriptions p where p.id = prescription_id and public.is_patient_of(p.patient_id))
);

create policy "surg_staff" on public.surgeries for all using (public.is_staff()) with check (public.is_staff());
create policy "surg_patient_read" on public.surgeries for select using (public.is_patient_of(patient_id));

create policy "imaging_staff" on public.imaging for all using (public.is_staff()) with check (public.is_staff());
create policy "imaging_patient_read" on public.imaging for select using (public.is_patient_of(patient_id));

create policy "lab_staff" on public.lab_results for all using (public.is_staff()) with check (public.is_staff());
create policy "lab_patient_read" on public.lab_results for select using (public.is_patient_of(patient_id));

create policy "docs_staff" on public.documents for all using (public.is_staff()) with check (public.is_staff());
create policy "docs_patient_read" on public.documents for select using (public.is_patient_of(patient_id));

-- ============================================================
-- POLICIES — RDV
-- Staff: tout · Patient: ses propres RDV (lecture + création)
-- ============================================================
create policy "appt_staff" on public.appointments for all using (public.is_staff()) with check (public.is_staff());
create policy "appt_patient_read" on public.appointments for select using (public.is_patient_of(patient_id));
create policy "appt_patient_insert" on public.appointments for insert with check (public.is_patient_of(patient_id));

-- ============================================================
-- POLICIES — Facturation (quotes, invoices, payments)
-- Staff: tout · Patient: lecture uniquement de ses documents
-- ============================================================
create policy "quotes_staff" on public.quotes for all using (public.is_staff()) with check (public.is_staff());
create policy "quotes_patient_read" on public.quotes for select using (public.is_patient_of(patient_id));

create policy "qlines_staff" on public.quote_lines for all using (public.is_staff()) with check (public.is_staff());
create policy "qlines_patient_read" on public.quote_lines for select using (
  exists (select 1 from public.quotes q where q.id = quote_id and public.is_patient_of(q.patient_id))
);

create policy "inv_staff" on public.invoices for all using (public.is_staff()) with check (public.is_staff());
create policy "inv_patient_read" on public.invoices for select using (public.is_patient_of(patient_id));

create policy "pay_staff" on public.payments for all using (public.is_staff()) with check (public.is_staff());
create policy "pay_patient_read" on public.payments for select using (public.is_patient_of(patient_id));

-- ============================================================
-- POLICIES — CNAM PEC
-- ============================================================
create policy "pec_staff" on public.cnam_pec for all using (public.is_staff()) with check (public.is_staff());
create policy "pec_patient_read" on public.cnam_pec for select using (public.is_patient_of(patient_id));

-- ============================================================
-- POLICIES — Rééducation
-- ============================================================
create policy "rehab_prog_staff" on public.rehab_programs for all using (public.is_staff()) with check (public.is_staff());
create policy "rehab_prog_patient_read" on public.rehab_programs for select using (public.is_patient_of(patient_id));

create policy "rehab_exo_staff" on public.rehab_exercises for all using (public.is_staff()) with check (public.is_staff());
create policy "rehab_exo_patient_read" on public.rehab_exercises for select using (
  exists (select 1 from public.rehab_programs rp where rp.id = program_id and public.is_patient_of(rp.patient_id))
);

create policy "rehab_sess_staff" on public.rehab_sessions for all using (public.is_staff()) with check (public.is_staff());
create policy "rehab_sess_patient_all" on public.rehab_sessions for all using (public.is_patient_of(patient_id)) with check (public.is_patient_of(patient_id));

-- ============================================================
-- POLICIES — Messagerie
-- Staff: tout · Patient: ses threads uniquement
-- ============================================================
create policy "threads_staff" on public.message_threads for all using (public.is_staff()) with check (public.is_staff());
create policy "threads_patient" on public.message_threads for select using (public.is_patient_of(patient_id));

create policy "messages_staff" on public.messages for all using (public.is_staff()) with check (public.is_staff());
create policy "messages_patient_select" on public.messages for select using (
  exists (select 1 from public.message_threads t where t.id = thread_id and public.is_patient_of(t.patient_id))
);
create policy "messages_patient_insert" on public.messages for insert with check (
  exists (select 1 from public.message_threads t where t.id = thread_id and public.is_patient_of(t.patient_id))
  and sender_id = auth.uid()
);

-- ============================================================
-- POLICIES — Audit log
-- Lecture: doctor uniquement · Écriture: tous (via triggers)
-- ============================================================
create policy "audit_doctor_read" on public.audit_log for select using (public.is_doctor());
create policy "audit_insert" on public.audit_log for insert with check (true);

-- ============================================================
-- POLICY — Catalogue CNAM (public en lecture, staff en écriture)
-- ============================================================
alter table public.cnam_acts_catalog enable row level security;
create policy "cnam_catalog_read_all" on public.cnam_acts_catalog for select using (true);
create policy "cnam_catalog_write_doctor" on public.cnam_acts_catalog for all using (public.is_doctor()) with check (public.is_doctor());

-- ============================================================
-- TRIGGER : Création automatique du profile à l'inscription
-- ============================================================
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, first_name, last_name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'first_name', 'Nouveau'),
    coalesce(new.raw_user_meta_data->>'last_name', 'Utilisateur'),
    new.email,
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'patient')
  );
  return new;
end$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- SEED : Catalogue actes CNAM orthopédie (barème indicatif TND)
-- ============================================================
insert into public.cnam_acts_catalog (code, label, category, base_price) values
  ('04.01.32', 'Prothèse Totale du Genou (PTG)',         'chirurgie', 17500),
  ('04.01.33', 'Prothèse Unicompartimentale (PUC)',      'chirurgie', 15000),
  ('04.01.41', 'Prothèse Totale de Hanche (PTH)',        'chirurgie', 24000),
  ('04.01.42', 'Reprise de Prothèse de Hanche',          'chirurgie', 28000),
  ('04.02.41', 'Hallux Valgus percutané unilatéral',     'chirurgie',  3250),
  ('04.02.42', 'Hallux Valgus percutané bilatéral',      'chirurgie', 11000),
  ('04.02.43', 'Hallux Valgus chevron + DMMO',           'chirurgie',  4000),
  ('04.03.55', 'Ligamentoplastie LCA + matériel',        'chirurgie',  8000),
  ('04.03.56', 'Suture méniscale',                       'chirurgie',  5500),
  ('04.04.27', 'Suture tendon Achille',                  'chirurgie',  7500),
  ('04.05.10', 'Arthroscopie cheville',                  'chirurgie',  5500),
  ('04.05.11', 'Ligamentoplastie cheville (LLE)',        'chirurgie', 11000),
  ('04.06.20', 'Libération canal carpien',               'chirurgie',  1800),
  ('04.06.21', 'Libération canal cubital',               'chirurgie',  2000),
  ('04.07.30', 'Suture coiffe arthroscopique',           'chirurgie', 11000),
  ('04.07.31', 'Latarjet (épaule)',                      'chirurgie', 11000),
  ('04.07.32', 'Acromioplastie',                         'chirurgie',  6000),
  ('04.08.40', 'Transposition TTA + MPFL',               'chirurgie', 10000),
  ('04.09.50', 'Doigt à ressaut',                        'chirurgie',  1200),
  ('04.10.60', 'Fracture luxation trapézo-métacarpienne','chirurgie',  1500),
  ('02.01.18', 'Infiltration L5-S1',                     'medical',     200),
  ('02.01.19', 'Infiltration épaule (intra-articulaire)','medical',     150),
  ('01.01.01', 'Consultation orthopédiste',              'consultation', 80),
  ('01.01.02', 'Consultation de contrôle',               'consultation', 50);

-- ============================================================
-- VIEWS utiles
-- ============================================================
create or replace view public.v_patients_summary as
select
  p.*,
  (select max(scheduled_at) from public.appointments where patient_id = p.id) as last_appointment,
  (select count(*) from public.consultations where patient_id = p.id)         as consultation_count,
  (select count(*) from public.surgeries where patient_id = p.id and status='completed') as surgery_count
from public.patients p
where p.deleted_at is null;

-- ============================================================
-- 🎉 FIN DE LA MIGRATION
-- ============================================================
-- ✅ 22 tables créées (18 métier + 4 catalogue/audit)
-- ✅ Row Level Security activée partout
-- ✅ Politiques par rôle: doctor / staff / patient
-- ✅ Triggers updated_at + recherche full-text patients
-- ✅ Profile auto-créé à l'inscription
-- ✅ Catalogue CNAM orthopédie pré-rempli (24 actes)
-- ============================================================
