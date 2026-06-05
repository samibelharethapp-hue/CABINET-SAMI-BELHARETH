# Modèle de données — CABINET SAMI BELHARETH

Schéma PostgreSQL (Supabase) avec RLS.

## Tables principales

### `profiles` — Utilisateurs (médecin, secrétaire, patient)
```sql
CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  role text NOT NULL CHECK (role IN ('doctor', 'staff', 'patient')),
  first_name text NOT NULL,
  last_name text NOT NULL,
  phone text,
  email text,
  avatar_url text,
  preferences jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

### `patients` — Patients du cabinet
```sql
CREATE TABLE patients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid REFERENCES profiles(id), -- NULL si pas de compte
  first_name text NOT NULL,
  last_name text NOT NULL,
  date_of_birth date NOT NULL,
  gender text CHECK (gender IN ('M', 'F')),
  phone text,
  email text,
  address text,
  city text,
  cnam_id text, -- Identifiant CNAM
  cnam_active boolean DEFAULT false,
  blood_group text,
  height_cm int,
  weight_kg numeric(5,2),
  profession text,
  emergency_contact_name text,
  emergency_contact_phone text,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES profiles(id)
);

CREATE INDEX idx_patients_lastname ON patients(last_name);
CREATE INDEX idx_patients_phone ON patients(phone);
CREATE INDEX idx_patients_cnam ON patients(cnam_id);
```

### `medical_history` — Antécédents
```sql
CREATE TABLE medical_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid REFERENCES patients(id) ON DELETE CASCADE,
  category text NOT NULL CHECK (category IN ('medical', 'surgical', 'allergy', 'familial')),
  label text NOT NULL,
  details text,
  year int,
  severity text CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  created_at timestamptz DEFAULT now()
);
```

### `appointments` — Rendez-vous
```sql
CREATE TABLE appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid REFERENCES patients(id) ON DELETE CASCADE,
  doctor_id uuid REFERENCES profiles(id),
  type text NOT NULL CHECK (type IN ('consultation', 'control', 'preop', 'postop', 'emergency')),
  reason text,
  scheduled_at timestamptz NOT NULL,
  duration_minutes int DEFAULT 30,
  status text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show')),
  arrived_at timestamptz,
  started_at timestamptz,
  ended_at timestamptz,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_appointments_date ON appointments(scheduled_at);
CREATE INDEX idx_appointments_patient ON appointments(patient_id);
```

### `consultations` — Consultations réalisées
```sql
CREATE TABLE consultations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid REFERENCES patients(id) ON DELETE CASCADE,
  doctor_id uuid REFERENCES profiles(id),
  appointment_id uuid REFERENCES appointments(id),
  consultation_date timestamptz NOT NULL DEFAULT now(),
  reason text,
  -- Examen clinique orthopédique
  pain_eva int CHECK (pain_eva BETWEEN 0 AND 10),
  flexion_degrees int,
  extension_degrees int,
  rotation_internal int,
  rotation_external int,
  -- Texte libre
  observations text,
  diagnosis text,
  diagnosis_icd10 text,
  pathology text, -- 'hallux_valgus', 'lca', 'ptg', etc.
  treatment_plan text,
  -- Méta
  duration_minutes int,
  created_at timestamptz DEFAULT now()
);
```

### `prescriptions` — Ordonnances
```sql
CREATE TABLE prescriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  consultation_id uuid REFERENCES consultations(id) ON DELETE CASCADE,
  patient_id uuid REFERENCES patients(id),
  doctor_id uuid REFERENCES profiles(id),
  issue_date date NOT NULL DEFAULT current_date,
  pdf_url text,
  notes text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE prescription_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prescription_id uuid REFERENCES prescriptions(id) ON DELETE CASCADE,
  medication_name text NOT NULL,
  dosage text,
  frequency text,
  duration text,
  quantity int,
  instructions text,
  order_index int DEFAULT 0
);
```

### `surgeries` — Chirurgies
```sql
CREATE TABLE surgeries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid REFERENCES patients(id),
  doctor_id uuid REFERENCES profiles(id),
  type text NOT NULL, -- 'ptg', 'pth', 'lca', 'hallux_valgus', etc.
  side text CHECK (side IN ('left', 'right', 'bilateral')),
  scheduled_date timestamptz NOT NULL,
  clinic text,
  operating_room text,
  anesthesia text CHECK (anesthesia IN ('general', 'spinal', 'epidural', 'local', 'regional')),
  cnam_code text, -- Cotation CNAM
  status text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
  preop_assessment_complete boolean DEFAULT false,
  cnam_pec_status text CHECK (cnam_pec_status IN ('pending', 'submitted', 'approved', 'rejected')),
  implant_details jsonb,
  cro_text text, -- Compte-rendu opératoire
  cro_pdf_url text,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now()
);
```

### `quotes` — Devis
```sql
CREATE TABLE quotes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  number text UNIQUE NOT NULL, -- DEV-2026-0142
  patient_id uuid REFERENCES patients(id),
  surgery_id uuid REFERENCES surgeries(id),
  issue_date date NOT NULL DEFAULT current_date,
  expiry_date date,
  total_ttc numeric(10,2) NOT NULL,
  cnam_covered numeric(10,2),
  patient_share numeric(10,2),
  deposit_required numeric(10,2),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'signed', 'invoiced', 'cancelled', 'refused')),
  pdf_url text,
  signed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE quote_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id uuid REFERENCES quotes(id) ON DELETE CASCADE,
  description text NOT NULL,
  unit_price numeric(10,2) NOT NULL,
  quantity int NOT NULL DEFAULT 1,
  total numeric(10,2) NOT NULL,
  order_index int DEFAULT 0
);
```

### `invoices` — Factures
```sql
CREATE TABLE invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  number text UNIQUE NOT NULL,
  patient_id uuid REFERENCES patients(id),
  quote_id uuid REFERENCES quotes(id),
  issue_date date NOT NULL DEFAULT current_date,
  due_date date,
  total_ttc numeric(10,2) NOT NULL,
  amount_paid numeric(10,2) DEFAULT 0,
  status text NOT NULL DEFAULT 'unpaid' CHECK (status IN ('unpaid', 'partial', 'paid', 'cancelled')),
  pdf_url text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid REFERENCES invoices(id),
  patient_id uuid REFERENCES patients(id),
  amount numeric(10,2) NOT NULL,
  method text NOT NULL CHECK (method IN ('cash', 'card', 'transfer', 'cnam', 'konnect', 'flouci', 'check')),
  reference text,
  paid_at timestamptz NOT NULL DEFAULT now(),
  received_by uuid REFERENCES profiles(id),
  notes text
);
```

### `cnam_pec` — Prises en charge CNAM
```sql
CREATE TABLE cnam_pec (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid REFERENCES patients(id),
  surgery_id uuid REFERENCES surgeries(id),
  act_code text NOT NULL, -- Cotation CNAM (ex: 04.01.32)
  act_label text NOT NULL,
  request_date date NOT NULL DEFAULT current_date,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'submitted', 'approved', 'rejected')),
  submitted_at timestamptz,
  approved_at timestamptz,
  cnam_reference text, -- Numéro accusé réception
  rejection_reason text,
  pdf_url text,
  documents jsonb, -- {devis: true, bilan: true, ...}
  created_at timestamptz DEFAULT now()
);
```

### `imaging` — Imagerie médicale
```sql
CREATE TABLE imaging (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid REFERENCES patients(id),
  type text NOT NULL CHECK (type IN ('xray', 'ct', 'mri', 'ultrasound', 'other')),
  body_part text, -- 'knee', 'hip', 'spine', etc.
  side text CHECK (side IN ('left', 'right', 'bilateral')),
  exam_date date NOT NULL,
  center_name text,
  radiologist text,
  findings text,
  conclusion text,
  files jsonb, -- [{url, name, type, size}]
  dicom_series_url text,
  created_at timestamptz DEFAULT now()
);
```

### `lab_results` — Biologie
```sql
CREATE TABLE lab_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid REFERENCES patients(id),
  exam_date date NOT NULL,
  lab_name text,
  results jsonb, -- { glucose: {value, unit, normal_range, status}, ... }
  abnormal_flags text[],
  pdf_url text,
  created_at timestamptz DEFAULT now()
);
```

### `documents` — Documents généraux
```sql
CREATE TABLE documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid REFERENCES patients(id),
  type text NOT NULL CHECK (type IN ('certificate', 'work_leave', 'sport_exemption', 'letter', 'report', 'other')),
  title text NOT NULL,
  content text,
  template_id uuid,
  pdf_url text,
  issued_by uuid REFERENCES profiles(id),
  issued_date date NOT NULL DEFAULT current_date,
  created_at timestamptz DEFAULT now()
);
```

### `rehab_programs` — Programmes de rééducation
```sql
CREATE TABLE rehab_programs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid REFERENCES patients(id),
  surgery_id uuid REFERENCES surgeries(id),
  pathology text NOT NULL,
  start_date date NOT NULL,
  duration_weeks int,
  total_sessions int,
  sessions_completed int DEFAULT 0,
  physio_id uuid, -- Kiné référent
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE rehab_exercises (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id uuid REFERENCES rehab_programs(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  video_url text,
  sets int,
  reps int,
  duration_seconds int,
  frequency_per_day int DEFAULT 1,
  order_index int DEFAULT 0
);

CREATE TABLE rehab_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id uuid REFERENCES rehab_programs(id),
  patient_id uuid REFERENCES patients(id),
  session_date date NOT NULL DEFAULT current_date,
  exercises_completed jsonb, -- [{exercise_id, completed, notes}]
  pain_eva int CHECK (pain_eva BETWEEN 0 AND 10),
  notes text,
  created_at timestamptz DEFAULT now()
);
```

### `messages` — Messagerie sécurisée
```sql
CREATE TABLE message_threads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid REFERENCES patients(id),
  last_message_at timestamptz DEFAULT now(),
  unread_doctor int DEFAULT 0,
  unread_patient int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id uuid REFERENCES message_threads(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES profiles(id),
  sender_role text CHECK (sender_role IN ('doctor', 'staff', 'patient')),
  content text,
  attachment_url text,
  attachment_type text,
  is_read boolean DEFAULT false,
  read_at timestamptz,
  created_at timestamptz DEFAULT now()
);
```

### `audit_log` — Traçabilité
```sql
CREATE TABLE audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id),
  action text NOT NULL,
  resource_type text NOT NULL,
  resource_id uuid NOT NULL,
  changes jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_audit_resource ON audit_log(resource_type, resource_id);
CREATE INDEX idx_audit_user ON audit_log(user_id, created_at DESC);
```

## Vues utiles

### Patients actifs avec dernière visite
```sql
CREATE VIEW v_patients_with_last_visit AS
SELECT
  p.*,
  (SELECT MAX(scheduled_at) FROM appointments WHERE patient_id = p.id) AS last_appointment,
  (SELECT COUNT(*) FROM consultations WHERE patient_id = p.id) AS consultation_count,
  (SELECT COUNT(*) FROM surgeries WHERE patient_id = p.id AND status = 'completed') AS surgery_count
FROM patients p;
```

### Tableau de bord médecin
```sql
CREATE VIEW v_doctor_dashboard AS
SELECT
  date_trunc('day', scheduled_at) AS day,
  COUNT(*) AS total_appointments,
  COUNT(*) FILTER (WHERE status = 'completed') AS completed,
  COUNT(*) FILTER (WHERE type = 'emergency') AS emergencies
FROM appointments
WHERE scheduled_at >= now() - interval '30 days'
GROUP BY date_trunc('day', scheduled_at);
```

## Notes d'implémentation

- **UUIDs** partout pour faciliter le offline-first sync
- **Soft delete** : ajouter `deleted_at` aux tables sensibles plutôt que `DELETE`
- **Versioning** : trigger sur les tables médicales pour conserver l'historique (`consultations_history`)
- **Full-text search** sur `patients` (nom, prénom, téléphone, CNAM) via `tsvector`
- **Indexes** sur toutes les FK et colonnes filtrées fréquemment
