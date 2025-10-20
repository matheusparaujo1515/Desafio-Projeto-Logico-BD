# Desafio de Projeto — Esquema de E-commerce (PF/PJ, Pagamentos e Entregas)

## 1. Descrição
Este repositório contém a modelagem e a implementação, em PostgreSQL, de um esquema relacional para um sistema de e-commerce. O foco é garantir consistência de dados, integridade referencial e normalização, contemplando:
- distinção entre clientes Pessoa Física (PF) e Pessoa Jurídica (PJ);
- múltiplas formas de pagamento por cliente;
- entregas com status e código de rastreio, incluindo validações de negócio.

## 2. Estrutura de Pastas
├── README.md

├── schema/
- desafio_ecommerce.sql # DDL completo (tipos, tabelas, índices, triggers)
- inserts.sql # dados de teste
- queries.sql # consultas pedidas no desafio
  
└── docs/
- modelo_conceitual.mmd # diagrama conceitual (Mermaid)
- modelo_logico.png # diagrama lógico exportado do pgAdmin (ERD)


## 3. Requisitos
- PostgreSQL 13 ou superior
- Extensões:
  - `pgcrypto` (geração de UUIDs)
  - `citext` (texto case-insensitive para e-mail)
- PL/pgSQL habilitado (para funções de gatilho)


