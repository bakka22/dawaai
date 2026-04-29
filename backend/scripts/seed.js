const pool = require('../src/db/config');

async function seed() {
  console.log('Seeding database with comprehensive data...');
  
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    // Get existing customer user id
    const customerResult = await client.query(
      "SELECT id FROM users WHERE role = 'customer' LIMIT 1"
    );
    const customerId = customerResult.rows[0]?.id;
    
    // Get pharmacist user id
    const pharmacistResult = await client.query(
      "SELECT id FROM users WHERE role = 'pharmacist' LIMIT 1"
    );
    const pharmacistId = pharmacistResult.rows[0]?.id;
    
    // Get driver user id
    const driverResult = await client.query(
      "SELECT id FROM users WHERE role = 'driver' LIMIT 1"
    );
    const driverId = driverResult.rows[0]?.id;

    if (!customerId) {
      // Create test customer
      const customer = await client.query(`
        INSERT INTO users (phone, role, password_hash)
        VALUES ('+249123456001', 'customer', 'test123')
        RETURNING id
      `);
      var newCustomerId = customer.rows[0].id;
    }
    
    if (!pharmacistId) {
      // Create test pharmacist
      const pharmacist = await client.query(`
        INSERT INTO users (phone, role, password_hash)
        VALUES ('+249123456002', 'pharmacist', 'test123')
        RETURNING id
      `);
      var newPharmacistId = pharmacist.rows[0].id;
    }

    const actualCustomerId = customerId || newCustomerId;
    const actualPharmacistId = pharmacistId || newPharmacistId;
    
    console.log('Using customer ID:', actualCustomerId);
    console.log('Using pharmacist ID:', actualPharmacistId);
    
    // Insert medications (comprehensive list)
    await client.query(`
      INSERT INTO medications (id, name, active_ingredient, synonyms, is_flagged)
      VALUES 
        (1, 'Panadol', 'Paracetamol', '["بانادول", "باراسيتامول", " acetaminophen"]', false),
        (2, 'Panadol Extra', 'Paracetamol + Caffeine', '["بانادول إكسترا"]', false),
        (3, 'Amoxicillin', 'Amoxicillin', '["اموكسيسيلين", "أموكسيل", "amox"]', false),
        (4, 'Brufen', 'Ibuprofen', '["بروفين", "إيبوبروفين", "advil"]', false),
        (5, 'Flagyl', 'Metronidazole', '["فلاجيل", "ميترونيدازول"]', true),
        (6, 'Augmentin', 'Amoxicillin + Clavulanic Acid', '["أوجمنتين"]', false),
        (7, 'Zantac', 'Ranitidine', '["زانتاك", "رانيتيدين"]', false),
        (8, 'Lasix', 'Furosemide', '["لازيكس", "فوروسيميد"]', true),
        (9, 'Glucophage', 'Metformin', '["جلوكوفاج", "ميتفورمين"]', false),
        (10, 'Ciprofloxacin', 'Ciprofloxacin', '["سبروفلوكساسين", "سيبرو"]', false),
        (11, 'Omeprazole', 'Omeprazole', '["أوميبرازول", "بروتونيك"]', false),
        (12, 'Aspirin', 'Acetylsalicylic Acid', '["أسبرين", "أسبرين"]', false),
        (13, 'Voltaren', 'Diclofenac', '["فولتارين", "ديكلوفيناك"]', false),
        (14, 'Ventolin', 'Salbutamol', '["فنتولين", "سالبوتامول"]', true),
        (15, 'Neurobion', 'Vitamin B Complex', '["نيوروبيون", "فيتامين ب"]', false)
      ON CONFLICT (id) DO NOTHING
    `);
    
    // Insert pharmacies with opening/closing hours
    await client.query(`
      INSERT INTO pharmacies (id, owner_id, name, lat, lng, is_approved, city, address, phone, opening_time, closing_time)
      VALUES 
        (1, $1, 'صيدلية الخرائط الكبرى', 15.5007, 32.5599, true, 'الخرطوم', 'شارع الوحدة', '+249123456001', '08:00', '22:00'),
        (2, $1, 'صيدلية الواحة', 15.5020, 32.5600, true, 'الخرtrum', 'شارع المكتبة', '+249123456002', '09:00', '21:00'),
        (3, $1, 'صيدلية النهضة', 15.5030, 32.5580, true, 'الخرطم', 'شارع النيل', '+249123456003', '07:00', '23:00'),
        (4, $1, 'صيدلية الحارة الجديدة', 15.5040, 32.5570, true, 'الخرطم', 'حي الحارة', '+249123456004', '24:00', '24:00'),
        (5, $1, 'صيدلية المعلم', 15.5050, 32.5610, false, 'أم درمان', 'شارع المعلم', '+249123456005', '08:00', '20:00')
      ON CONFLICT (id) DO NOTHING
    `, [actualPharmacistId]);
    
    // Insert pharmacy inventory
    await client.query(`
      INSERT INTO pharmacy_inventory (pharmacy_id, medication_id, is_in_stock, price, quantity)
      VALUES 
        -- Pharmacy 1 inventory
        (1, 1, true, 50.00, 100),
        (1, 2, true, 45.00, 80),
        (1, 3, true, 150.00, 50),
        (1, 4, true, 75.00, 60),
        (1, 5, false, 200.00, 0),
        (1, 6, true, 180.00, 40),
        (1, 7, true, 60.00, 70),
        (1, 11, true, 40.00, 90),
        -- Pharmacy 2 inventory
        (2, 1, true, 48.00, 120),
        (2, 2, false, 150.00, 0),
        (2, 3, true, 145.00, 30),
        (2, 4, true, 70.00, 50),
        (2, 8, true, 90.00, 25),
        (2, 9, true, 55.00, 80),
        -- Pharmacy 3 inventory (24h)
        (3, 1, true, 55.00, 200),
        (3, 2, true, 160.00, 100),
        (3, 4, true, 80.00, 100),
        (3, 5, true, 220.00, 30),
        (3, 6, true, 190.00, 60),
        (3, 10, true, 120.00, 40),
        (3, 14, true, 45.00, 50),
        -- Pharmacy 4 inventory
        (4, 1, true, 50.00, 150),
        (4, 2, true, 155.00, 75),
        (4, 3, true, 160.00, 50),
        (4, 11, true, 45.00, 100),
        (4, 12, true, 35.00, 200),
        (4, 13, true, 85.00, 60)
      ON CONFLICT DO NOTHING
    `);
    
    // Insert quotes
    await client.query(`
      INSERT INTO quotes (id, customer_id, status, expires_at)
      VALUES 
        (1, $1, 'BROADCASTING', NOW() + INTERVAL '20 minutes'),
        (2, $1, 'ACCEPTED', NOW() - INTERVAL '1 hour'),
        (3, $1, 'EXPIRED', NOW() - INTERVAL '30 minutes')
      ON CONFLICT (id) DO NOTHING
    `, [actualCustomerId]);
    
    // Insert quote responses
    await client.query(`
      INSERT INTO quote_responses (id, quote_id, pharmacy_id, total_price, status)
      VALUES 
        (1, 1, 1, 250.00, 'PENDING'),
        (2, 1, 2, 280.00, 'PENDING'),
        (3, 1, 3, 235.00, 'PENDING'),
        (4, 2, 1, 180.00, 'ACCEPTED'),
        (5, 2, 2, 195.00, 'REJECTED')
      ON CONFLICT (id) DO NOTHING
    `);
    
    // Insert orders (various statuses)
    await client.query(`
      INSERT INTO orders (id, customer_id, pharmacy_id, quote_id, status, total_price, delivery_fee, payment_status, prescription_confirmed)
      VALUES 
        (1, $1, 1, 1, 'COMPLETED', 250.00, 25.00, 'UNPAID', true),
        (2, $1, 2, 2, 'PREPARING', 180.00, 25.00, 'UNPAID', true),
        (3, $1, 3, 3, 'IN_TRANSIT', 320.00, 30.00, 'PAID', true),
        (4, $1, 1, 1, 'PENDING', 150.00, 25.00, 'UNPAID', false),
        (5, $1, 4, null, 'PENDING', 95.00, 25.00, 'UNPAID', false)
      ON CONFLICT (id) DO NOTHING
    `, [actualCustomerId]);
    
    // Insert order items
    await client.query(`
      INSERT INTO order_items (id, order_id, medication_id, quantity, price)
      VALUES 
        (1, 1, 1, 2, 50.00),
        (2, 1, 2, 1, 150.00),
        (3, 2, 1, 1, 48.00),
        (4, 2, 3, 1, 145.00),
        (5, 3, 5, 1, 220.00),
        (6, 3, 4, 1, 80.00),
        (7, 4, 1, 2, 50.00),
        (8, 5, 1, 1, 50.00),
        (9, 5, 11, 1, 40.00)
      ON CONFLICT (id) DO NOTHING
    `);
    
    // Insert order segments
    await client.query(`
      INSERT INTO order_segments (id, order_id, pharmacy_id, status, delivery_fee, subtotal)
      VALUES 
        (1, 1, 1, 'DELIVERED', 25.00, 250.00),
        (2, 2, 2, 'READY', 25.00, 180.00),
        (3, 3, 3, 'IN_TRANSIT', 30.00, 320.00),
        (4, 4, 1, 'PENDING', 25.00, 150.00),
        (5, 5, 4, 'PENDING', 25.00, 95.00)
      ON CONFLICT (id) DO NOTHING
    `);
    
    // Insert cosmetic products
    await client.query(`
      INSERT INTO cosmetic_products (id, name, brand, target_skin_type, concerns, price, description, image_url, why_this, is_active)
      VALUES 
        (1, 'مرطب للبشرة الجافة', 'CeraVe', 'dry', '["جفاف", "تقشير"]', 250.00, 'مرطب مكثف للبشرة الجافة جداً', null, '["آمن للبشرة الجافة", "يحتوي على السيراميد"]', true),
        (2, 'غسول للبشرة الدهنية', 'Neutrogena', 'oily', '["حب الشباب", "دهون"]', 180.00, 'غسول يزيل الدهون بفعالية', null, '["مضاد لحب الشباب", "ينظم إفراز油脂"]', true),
        (3, 'كريم للوجه الحساس', 'La Roche-Posay', 'sensitive', '["تهيج", "احمرار"]', 320.00, 'كريم مهدئ للبشرة الحساسة', null, '["هيpoallergenic", "خالٍ من العطر"]', true),
        (4, 'ماسك ترطيب عميق', 'The Ordinary', 'all', '["جفاف", "تعب"]', 150.00, 'ماسك ترطيب عميق للاستخدام الليلي', null, '["ترطيب 24 ساعة", "آمن لجميع أنواع البشرة"]', true),
        (5, 'سيروم فيتامين سي', 'Paula Choice', 'combination', '["acne", "dark_spots"]', 450.00, 'سيروم تركيز عالي لفيتامين سي', null, '["مبيض للبقع", "مضاد للأكسدة"]', true),
        (6, 'تونر للتخلص من الرؤوس السوداء', 'COSRX', 'oily', '["blackheads", "enlarged_pores"]', 200.00, 'تونر AHA/BHA للتخلص من الرؤوس السوداء', null, '["يقلل المسام", "ينعم البشرة"]', true),
        (7, 'كريم حماية من الشمس SPF50', 'La Roche-Posay', 'all', '["حماية", "وقاية"]', 380.00, 'كريم حماية من الشمس بمعامل SPF50', null, '["حماية كاملة من UVA/UVB", "مقاوم للماء"]', true),
        (8, 'مصل الهيالورونيك أسيد', 'The Ordinary', 'dry', '["جفاف", "خطوط دقيقة"]', 220.00, 'مصل مرطب للخطوط الدقيقة', null, '["ترطيب عميق", "يملأ الخطوط الدقيقة"]', true),
        (9, 'غسول كلينيكال للبشرة المختلطة', 'CeraVe', 'combination', '["oiliness", "dryness"]', 170.00, 'غسول متوازن للبشرة المختلطة', null, '["يفتح المسام", "لا يجفف البشرة"]', true),
        (10, 'كريم العين المضاد للتجاعيد', 'Neutrogena', 'sensitive', '["انتفاخ", "تجاعيد"]', 290.00, 'كريم العين المضاد للتجاعيد والانتفاخ', null, '["يقلل الانتفاخ", "يخفي الهالات السوداء"]', true)
      ON CONFLICT (id) DO NOTHING
    `);
    
    // Insert user profile for cosmetics personalization
    await client.query(`
      INSERT INTO user_profiles (user_id, skin_type, concerns, budget_range, sensitivities)
      VALUES 
        ($1, 'dry', '["جفاف", "تقشير"]', 'medium', '["عطر"]')
      ON CONFLICT (user_id) DO UPDATE SET
        skin_type = 'dry',
        concerns = '["جفاف", "تقشير"]'
    `, [actualCustomerId]);
    
    // Insert admin user if not exists
    await client.query(`
      INSERT INTO users (phone, role, password_hash)
      VALUES ('+249999999999', 'admin', 'admin123')
      ON CONFLICT DO NOTHING
    `);
    
    await client.query('COMMIT');
    console.log('Database seeded successfully!');
    
    // Print summary
    console.log('\n========== DATABASE SUMMARY ==========');
    const summary = await Promise.all([
      client.query('SELECT COUNT(*) as cnt FROM users'),
      client.query('SELECT COUNT(*) as cnt FROM medications'),
      client.query('SELECT COUNT(*) as cnt FROM pharmacies WHERE is_approved = true'),
      client.query('SELECT COUNT(*) as cnt FROM orders'),
      client.query('SELECT COUNT(*) as cnt FROM cosmetic_products'),
      client.query('SELECT COUNT(*) as cnt FROM user_profiles'),
    ]);
    
    console.log('Users: ' + summary[0].rows[0].cnt);
    console.log('Medications: ' + summary[1].rows[0].cnt);
    console.log('Approved Pharmacies: ' + summary[2].rows[0].cnt);
    console.log('Orders: ' + summary[3].rows[0].cnt);
    console.log('Cosmetic Products: ' + summary[4].rows[0].cnt);
    console.log('User Profiles: ' + summary[5].rows[0].cnt);
    console.log('==========================================\n');
    
    console.log('Test Credentials:');
    console.log('- Customer: +249123456001 / test123');
    console.log('- Pharmacist: +249123456002 / test123');
    console.log('- Admin: +249999999999 / admin123');
    
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Seed error:', err);
  } finally {
    client.release();
    process.exit(0);
  }
}

seed();