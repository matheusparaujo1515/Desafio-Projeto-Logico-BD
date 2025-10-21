-- ===============================================================
-- DESAFIO DE PROJETO – ESQUEMA DE E-COMMERCE (PF/PJ, PAGAMENTOS, ENTREGAS)
-- Banco: PostgreSQL 13+
-- ===============================================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS citext;

-- ===============================================================
-- TIPOS ENUMERADOS
-- ===============================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'person_type') THEN
    CREATE TYPE person_type AS ENUM ('PF', 'PJ');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method_type') THEN
    CREATE TYPE payment_method_type AS ENUM ('CREDIT_CARD', 'PIX', 'BOLETO');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'delivery_status') THEN
    CREATE TYPE delivery_status AS ENUM (
      'CREATED', 'PACKED', 'SHIPPED', 'IN_TRANSIT', 'DELIVERED', 'RETURNED', 'CANCELED'
    );
  END IF;
END$$;

-- ===============================================================
-- TABELAS
-- ===============================================================

-- Tabela: accounts
CREATE TABLE IF NOT EXISTS public.accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email CITEXT UNIQUE NOT NULL,
  person_type person_type NOT NULL,
  cpf TEXT UNIQUE,
  cnpj TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_accounts_pf_pj CHECK (
    (person_type = 'PF' AND cpf IS NOT NULL AND cnpj IS NULL)
    OR
    (person_type = 'PJ' AND cnpj IS NOT NULL AND cpf IS NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_accounts_cpf  ON public.accounts (cpf)  WHERE cpf  IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_accounts_cnpj ON public.accounts (cnpj) WHERE cnpj IS NOT NULL;

-- Tabela: payment_methods
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  method_type payment_method_type NOT NULL,
  label TEXT NOT NULL,
  details JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_payment_methods_default_per_account
  ON public.payment_methods(account_id)
  WHERE is_default = true;

-- Tabela: orders
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE RESTRICT,
  payment_method_id UUID REFERENCES public.payment_methods(id) ON DELETE SET NULL,
  total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tabela: deliveries
CREATE TABLE IF NOT EXISTS public.deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  status delivery_status NOT NULL DEFAULT 'CREATED',
  tracking_code TEXT,
  carrier TEXT,
  shipped_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_deliveries_tracking_required CHECK (
    (status IN ('SHIPPED','IN_TRANSIT','DELIVERED','RETURNED') AND tracking_code IS NOT NULL)
    OR
    (status IN ('CREATED','PACKED','CANCELED'))
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_deliveries_tracking_unique
  ON public.deliveries(tracking_code) WHERE tracking_code IS NOT NULL;

-- ===============================================================
-- FUNÇÕES E TRIGGERS
-- ===============================================================

-- Atualização automática do updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END$$;

DROP TRIGGER IF EXISTS t_accounts_set_updated ON public.accounts;
CREATE TRIGGER t_accounts_set_updated
BEFORE UPDATE ON public.accounts
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Garantir que o método de pagamento pertence ao mesmo cliente
CREATE OR REPLACE FUNCTION public.trg_orders_payment_belongs()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.payment_method_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.payment_methods pm
    WHERE pm.id = NEW.payment_method_id
      AND pm.account_id = NEW.account_id
  ) THEN
    RAISE EXCEPTION 'Payment method % does not belong to account %',
      NEW.payment_method_id, NEW.account_id
      USING ERRCODE = '23503';
  END IF;

  RETURN NEW;
END$$;

DROP TRIGGER IF EXISTS t_orders_payment_belongs ON public.orders;
CREATE TRIGGER t_orders_payment_belongs
BEFORE INSERT OR UPDATE OF payment_method_id, account_id
ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.trg_orders_payment_belongs();

