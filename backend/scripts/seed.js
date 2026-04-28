const pool = require('../src/db/config');

async function seed() {
  console.log('Seeding database...');
  
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
    
    if (!customerId || !pharmacistId) {
      console.log('No customer or pharmacist users found. Please run auth tests first to create users.');
      await client.query('ROLLBACK');
      process.exit(0);
    }
    
    // Insert medications
    await client.query(`
      INSERT INTO medications (id, name, active_ingredient, synonyms, is_flagged)
      VALUES 
        (1, 'Panadol', 'Paracetamol', '["بانادول", "باراسيتامول"]', false),
        (2, 'Amoxicillin', 'Amoxicillin', '["اموكسيسيلين", "أموكسيل"]', false),
        (3, 'Brufen', 'Ibuprofen', '["بروفين", "إيبوبروفين"]', false),
        (4, 'Flagyl', 'Metronidazole', '["فلاجيل", "ميترونيدازول"]', true)
      ON CONFLICT (id) DO NOTHING
    `);
    
    // Insert pharmacies
    await client.query(`
      INSERT INTO pharmacies (id, owner_id, name, lat, lng, is_approved, city, address, phone)
      VALUES 
        (1, $1, 'صيدلية الخرائط الكبرى', 15.5007, 32.5599, true, 'الخرطوم', 'شارع الوحدة', '+249123456001'),
        (2, $1, 'صيدلية الواحة', 15.5020, 32.5600, true, 'الخرطوم', 'شارع library', '+249123456002'),
        (3, $1, 'صيدلية النهضة', 15.5030, 32.5580, false, 'الخردم', 'شارع Nile', '+249123456003')
      ON CONFLICT (id) DO NOTHING
    `, [pharmacistId]);
    
    // Insert pharmacy inventory
    await client.query(`
      INSERT INTO pharmacy_inventory (pharmacy_id, medication_id, is_in_stock, price, quantity)
      VALUES 
        (1, 1, true, 50.00, 100),
        (1, 2, true, 150.00, 50),
        (1, 3, false, 80.00, 0),
        (2, 1, true, 45.00, 80),
        (2, 2, true, 140.00, 60),
        (2, 3, true, 75.00, 40),
        (2, 4, true, 200.00, 20)
      ON CONFLICT DO NOTHING
    `);
    
    // Insert quotes
    await client.query(`
      INSERT INTO quotes (id, customer_id, status, expires_at)
      VALUES 
        (1, $1, 'BROADCASTING', NOW() + INTERVAL '20 minutes'),
        (2, $1, 'EXPIRED', NOW() - INTERVAL '30 minutes')
      ON CONFLICT (id) DO NOTHING
    `, [customerId]);
    
    // Insert quote responses
    await client.query(`
      INSERT INTO quote_responses (id, quote_id, pharmacy_id, total_price, status)
      VALUES 
        (1, 1, 1, 250.00, 'PENDING'),
        (2, 1, 2, 280.00, 'PENDING')
      ON CONFLICT (id) DO NOTHING
    `);
    
    // Insert orders
    await client.query(`
      INSERT INTO orders (id, customer_id, pharmacy_id, quote_id, status, total_price, delivery_fee, payment_status)
      VALUES 
        (1, $1, 1, 1, 'COMPLETED', 250.00, 25.00, 'UNPAID'),
        (2, $1, 2, 1, 'PENDING', 180.00, 25.00, 'UNPAID')
      ON CONFLICT (id) DO NOTHING
    `, [customerId]);
    
    // Insert order items
    await client.query(`
      INSERT INTO order_items (id, order_id, medication_id, quantity, price)
      VALUES 
        (1, 1, 1, 2, 50.00),
        (2, 1, 2, 3, 150.00),
        (3, 2, 1, 1, 45.00),
        (4, 2, 2, 1, 140.00)
      ON CONFLICT (id) DO NOTHING
    `);
    
    // Insert order segments
    await client.query(`
      INSERT INTO order_segments (id, order_id, pharmacy_id, status, delivery_fee, subtotal)
      VALUES 
        (1, 1, 1, 'DELIVERED', 25.00, 250.00),
        (2, 2, 2, 'PENDING', 25.00, 180.00)
      ON CONFLICT (id) DO NOTHING
    `);
    
    // Insert cosmetic products
    await client.query(`
      INSERT INTO cosmetic_products (id, name, brand, target_skin_type, concerns, price, description, is_active)
      VALUES 
        (1, 'مرطب للبشرة الجافة', 'CeraVe', 'dry', '["جفاف", "تقشير"]', 250.00, 'مرطب intensive للبشرة الجافة', true),
        (2, 'غسول للبشرة الدهنية', 'Neutrogena', 'oily', '["حب الشباب", "دهون"]', 180.00, 'غسول يزيل الدهون بفعالية', true),
        (3, 'كريم للوجه الحساس', 'La Roche-Posay', 'sensitive', '["تهيج", "احمرار"]', 320.00, 'كريم مهدئ للبشرة الحساسة', true),
        (4, 'ماسك ترطيب', 'The Ordinary', 'all', '["جفاف", "تعب"]', 150.00, 'ماسك ترطيب عميق', true),
        (5, 'سيروم فيتامين سي', 'Paula Choice', 'combination', '["acne", "dark_spots"]', 450.00, 'سيروم تركيز عالي لفيتامين سي', true)
      ON CONFLICT (id) DO NOTHING
    `);
    
    await client.query('COMMIT');
    console.log('Database seeded successfully!');
    
    // Print summary
    const summary = await Promise.all([
      client.query('SELECT COUNT(*) as cnt FROM users'),
      client.query('SELECT COUNT(*) as cnt FROM medications'),
      client.query('SELECT COUNT(*) as cnt FROM pharmacies'),
      client.query('SELECT COUNT(*) as cnt FROM orders'),
      client.query('SELECT COUNT(*) as cnt FROM cosmetic_products'),
    ]);
    
    console.log('\nDatabase Summary:');
    console.log('- Users:', summary[0].rows[0].cnt);
    console.log('- Medications:', summary[1].rows[0].cnt);
    console.log('- Pharmacies:', summary[2].rows[0].cnt);
    console.log('- Orders:', summary[3].rows[0].cnt);
    console.log('- Cosmetic Products:', summary[4].rows[0].cnt);
    
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Seed error:', err);
  } finally {
    client.release();
    process.exit(0);
  }
}

seed();