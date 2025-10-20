BEGIN;

-- Contas
INSERT INTO public.accounts (name, email, person_type, cpf)
VALUES
  ('Ana Souza','ana@cliente.com','PF','111.222.333-44'),
  ('Bruno Lima','bruno@cliente.com','PF','555.666.777-88')
ON CONFLICT (email) DO NOTHING;

INSERT INTO public.accounts (name, email, person_type, cnpj)
VALUES
  ('Loja Boa Ltda','contato@lojaboa.com.br','PJ','12.345.678/0001-90'),
  ('Tech Import S/A','suporte@techimport.com','PJ','98.765.432/0001-10')
ON CONFLICT (email) DO NOTHING;

-- Métodos de pagamento
INSERT INTO public.payment_methods (account_id, method_type, label, details, is_default)
SELECT id,'CREDIT_CARD','Meu Visa final 4242',
       jsonb_build_object('brand','VISA','last4','4242','holder','Ana Souza'),true
FROM public.accounts WHERE email='ana@cliente.com';

INSERT INTO public.payment_methods (account_id, method_type, label, details, is_default)
SELECT id,'PIX','Chave Pix - CPF',
       jsonb_build_object('key_type','CPF','key_value','11122233344'),false
FROM public.accounts WHERE email='ana@cliente.com';

INSERT INTO public.payment_methods (account_id, method_type, label, details, is_default)
SELECT id,'PIX','Chave Pix - Email',
       jsonb_build_object('key_type','EMAIL','key_value','bruno@cliente.com'),true
FROM public.accounts WHERE email='bruno@cliente.com';

INSERT INTO public.payment_methods (account_id, method_type, label, details, is_default)
SELECT id,'BOLETO','Boleto faturado - D+15',
       jsonb_build_object('bank','001','agreement','12345','terms','D+15'),true
FROM public.accounts WHERE email='contato@lojaboa.com.br';

INSERT INTO public.payment_methods (account_id, method_type, label, details, is_default)
SELECT id,'CREDIT_CARD','Corporate Mastercard 7777',
       jsonb_build_object('brand','MASTERCARD','last4','7777','holder','Tech Import'),true
FROM public.accounts WHERE email='suporte@techimport.com';

INSERT INTO public.payment_methods (account_id, method_type, label, details, is_default)
SELECT id,'PIX','Chave Pix - CNPJ',
       jsonb_build_object('key_type','CNPJ','key_value','98765432000110'),false
FROM public.accounts WHERE email='suporte@techimport.com';

-- Pedidos
INSERT INTO public.orders (account_id, payment_method_id, total_amount)
SELECT a.id, pm.id, 350.00
FROM public.accounts a
JOIN public.payment_methods pm ON pm.account_id=a.id AND pm.is_default=true
WHERE a.email='ana@cliente.com'
LIMIT 1;

INSERT INTO public.orders (account_id, payment_method_id, total_amount)
SELECT a.id, pm.id, 120.00
FROM public.accounts a
JOIN public.payment_methods pm ON pm.account_id=a.id AND pm.method_type='PIX'
WHERE a.email='ana@cliente.com'
LIMIT 1;

INSERT INTO public.orders (account_id, payment_method_id, total_amount)
SELECT a.id, pm.id, 89.90
FROM public.accounts a
JOIN public.payment_methods pm ON pm.account_id=a.id AND pm.is_default=true
WHERE a.email='bruno@cliente.com'
LIMIT 1;

INSERT INTO public.orders (account_id, payment_method_id, total_amount)
SELECT a.id, pm.id, 5000.00
FROM public.accounts a
JOIN public.payment_methods pm ON pm.account_id=a.id AND pm.is_default=true
WHERE a.email='contato@lojaboa.com.br'
LIMIT 1;

-- Entregas
INSERT INTO public.deliveries (order_id, status, tracking_code, carrier, shipped_at, created_at)
SELECT o.id,'SHIPPED','BR123456789BR','Correios',now()-interval '2 days',now()
FROM public.orders o
JOIN public.accounts a ON a.id=o.account_id
WHERE a.email='ana@cliente.com'
ORDER BY o.created_at LIMIT 1;

INSERT INTO public.deliveries (order_id, status, created_at)
SELECT o.id,'PACKED',now()
FROM public.orders o
JOIN public.accounts a ON a.id=o.account_id
WHERE a.email='ana@cliente.com'
ORDER BY o.created_at DESC LIMIT 1;

INSERT INTO public.deliveries (order_id, status, tracking_code, carrier, shipped_at, delivered_at, created_at)
SELECT o.id,'DELIVERED','BR987654321BR','Correios',
       now()-interval '5 days',now()-interval '2 days',now()
FROM public.orders o
JOIN public.accounts a ON a.id=o.account_id
WHERE a.email='bruno@cliente.com'
LIMIT 1;

INSERT INTO public.deliveries (order_id, status, tracking_code, carrier, shipped_at, created_at)
SELECT o.id,'IN_TRANSIT','TB1122334455','Transportadora Boa',
       now()-interval '1 day',now()
FROM public.orders o
JOIN public.accounts a ON a.id=o.account_id
WHERE a.email='contato@lojaboa.com.br'
LIMIT 1;

COMMIT;
