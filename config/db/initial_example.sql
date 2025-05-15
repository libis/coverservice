INSERT INTO 
    tenants (id, name, code, key) 
VALUES 
    (1, 'ADMIN', '32DEMO_ADMIN', '02dslfjfd4f3ds24fdmklsdgdgsgb918'),
    (2, 'DEMO', '32DEMO', '022b65cdfsd23sd45sdg3sd4g4aad07b918'),
    
ON CONFLICT (id) DO
UPDATE
SET
    name = EXCLUDED.name,
    code = EXCLUDED.code;


INSERT INTO
    institutions (id, name, code, tenant_id, key)
VALUES
    (1, 'Demo institution 1', '32DEMO_INST1', 2, 'dsq21fsqdggl78ftu1y578glrifm07b918'),
    (2, 'Demo institution 2', '32DEMO_INST2', 2, 'dsqfsd21fdsqd8glrifm07b918'),
    (3, 'Demo institution 3', '32DEMO_INST3', 2, 'dsqx243s24fgsd21fsqdgb9e2083ed'),
   

ON CONFLICT (id) DO
UPDATE
SET
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    key = EXCLUDED.key,
    tenant_id = EXCLUDED.tenant_id;
