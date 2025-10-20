-- Q1
SELECT id, name, cpf
FROM public.accounts
WHERE person_type='PF'
ORDER BY name;

-- Q2
SELECT a.name, COUNT(pm.id) AS qtde_metodos
FROM public.accounts a
LEFT JOIN public.payment_methods pm ON pm.account_id=a.id
GROUP BY a.name
HAVING COUNT(pm.id) > 1
ORDER BY qtde_metodos DESC, a.name;

-- Q3
SELECT
  o.id,
  a.name AS cliente,
  o.total_amount,
  CASE
    WHEN o.total_amount < 100  THEN 'baixo'
    WHEN o.total_amount < 1000 THEN 'médio'
    ELSE 'alto'
  END AS faixa_valor
FROM public.orders o
JOIN public.accounts a ON a.id=o.account_id
ORDER BY o.created_at DESC;

-- Q4
SELECT
  a.name AS cliente,
  o.id   AS pedido,
  d.tracking_code,
  ROUND(EXTRACT(EPOCH FROM (d.delivered_at - d.shipped_at))/86400.0,2) AS dias_transporte
FROM public.deliveries d
JOIN public.orders o   ON o.id=d.order_id
JOIN public.accounts a ON a.id=o.account_id
WHERE d.status='DELIVERED'
ORDER BY dias_transporte;

-- Q5
SELECT
  a.name AS cliente,
  COUNT(o.id)                  AS pedidos,
  SUM(o.total_amount)          AS total_gasto,
  ROUND(AVG(o.total_amount),2) AS ticket_medio
FROM public.accounts a
JOIN public.orders o ON o.account_id=a.id
GROUP BY a.name
HAVING SUM(o.total_amount) > 300
ORDER BY total_gasto DESC;

-- Q6
SELECT
  o.id AS pedido,
  a.name AS cliente,
  pm.method_type,
  COALESCE(pm.details->>'last4', pm.details->>'key_value', 'n/a') AS detalhe_chave
FROM public.orders o
JOIN public.accounts a        ON a.id=o.account_id
LEFT JOIN public.payment_methods pm ON pm.id=o.payment_method_id
ORDER BY o.created_at DESC;

-- Q7
SELECT status, COUNT(*) AS qtd
FROM public.deliveries
GROUP BY status
HAVING COUNT(*) >= 1
ORDER BY qtd DESC;

-- Q8
SELECT a.id, a.name, a.email
FROM public.accounts a
LEFT JOIN public.payment_methods pm
  ON pm.account_id=a.id AND pm.is_default=true
WHERE pm.id IS NULL;

-- Q9
WITH tot AS (
  SELECT a.id, a.name, COALESCE(SUM(o.total_amount),0) AS total_gasto
  FROM public.accounts a
  LEFT JOIN public.orders o ON o.account_id=a.id
  GROUP BY a.id, a.name
)
SELECT
  name,
  total_gasto,
  RANK() OVER (ORDER BY total_gasto DESC) AS posicao,
  CASE WHEN total_gasto >= 1000 THEN 'top'
       WHEN total_gasto >= 200  THEN 'relevante'
       ELSE 'baixo'
  END AS categoria
FROM tot
ORDER BY posicao;

-- Q10
SELECT
  o.id AS pedido,
  a.name AS cliente,
  d.status,
  d.tracking_code
FROM public.deliveries d
JOIN public.orders o   ON o.id=d.order_id
JOIN public.accounts a ON a.id=o.account_id
WHERE d.status IN ('SHIPPED','IN_TRANSIT','DELIVERED','RETURNED')
  AND d.tracking_code IS NULL;
