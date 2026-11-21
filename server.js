// Load .env settings before the app reads secrets and configuration.
require('dotenv').config();
// Import file tools for reading TLS certificates and creating folders.
const fs = require('node:fs');
// Build safe paths relative to this project folder.
const path = require('node:path');
// Use this module when HTTPS is configured directly in Node.
const https = require('node:https');
// Use this module for the local HTTP development server.
const http = require('node:http');
// Use cryptographic tools for encryption, random tokens, and safe comparisons.
const crypto = require('node:crypto');
// Create the web server and API framework.
const express = require('express');
// Add server-side cookie session support.
const session = require('express-session');
// Store session records in SQLite instead of only in memory.
const SQLiteStore = require('connect-sqlite3')(session);
// Hash passwords and verify them without storing the original password.
const bcrypt = require('bcryptjs');
// Set browser security headers such as Content Security Policy.
const helmet = require('helmet');
// Limit repeated login and registration attempts.
const { rateLimit } = require('express-rate-limit');
// Write structured security and application logs.
const winston = require('winston');
// Validate request data against explicit schemas.
const { z } = require('zod');

// Create the Express application used by every route.
const app = express();
// Trust proxy headers only when explicitly configured for a trusted proxy.
if (process.env.TRUST_PROXY === '1') app.set('trust proxy', 1);
// Find the project root so file paths stay predictable.
const ROOT = __dirname;
// Choose the folder for the application database and session store.
const DATA_DIR = path.join(ROOT, 'data');
// Choose the folder for security logs.
const LOG_DIR = path.join(ROOT, 'logs');
// Create data and log folders if they are missing.
fs.mkdirSync(DATA_DIR, { recursive: true }); fs.mkdirSync(LOG_DIR, { recursive: true });
// Configure timestamped JSON logging for security events.
const logger = winston.createLogger({ level: 'info', format: winston.format.combine(winston.format.timestamp(), winston.format.json()),
  transports: [new winston.transports.File({ filename: path.join(LOG_DIR, 'security.log') }), new winston.transports.Console({ format: winston.format.simple() })] });

// Read the session signing secret from the private environment file.
const sessionSecret = process.env.SESSION_SECRET || '';
// Read the AES encryption key from the private environment file.
const encryptionKeyHex = process.env.DATA_ENCRYPTION_KEY || '';
// Reject a weak or missing session secret during startup.
if (sessionSecret.length < 32) throw new Error('SESSION_SECRET must contain at least 32 characters. See README.md.');
// Reject an encryption key unless it is exactly 32 bytes represented as hex.
if (!/^[a-fA-F0-9]{64}$/.test(encryptionKeyHex)) throw new Error('DATA_ENCRYPTION_KEY must be 64 hex characters. See README.md.');
// Convert the validated hex key into bytes for AES-256-GCM.
const encryptionKey = Buffer.from(encryptionKeyHex, 'hex');
// Enable direct TLS only when both a key and certificate path are supplied.
const useTls = Boolean(process.env.TLS_KEY_PATH && process.env.TLS_CERT_PATH);
// Set Secure cookies for production or direct HTTPS.
const secureCookies = process.env.NODE_ENV === 'production' || useTls;
// Warn if production relies on a reverse proxy for TLS.
if (process.env.NODE_ENV === 'production' && !useTls) logger.warn('TLS is expected at the production reverse proxy; set trust proxy and use HTTPS at the edge.');

// Load SQLite support for the application database.
const sqlite3 = require('sqlite3').verbose();
// Open the persistent database file in the data folder.
const db = new sqlite3.Database(path.join(DATA_DIR, 'clubs.sqlite'));
// Create related tables in order and enable foreign-key checks.
db.serialize(() => {
// Make SQLite enforce references between related records.
  db.run('PRAGMA foreign_keys = ON');
// Define users, allowed roles, encrypted identity fields, and password hashes.
  db.run(`CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, email_hash TEXT UNIQUE NOT NULL, email_enc TEXT NOT NULL, name_enc TEXT NOT NULL, student_id_enc TEXT, password_hash TEXT NOT NULL, role TEXT NOT NULL CHECK(role IN ('student','admin')), created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)`);
// Define the club details shown to students and managed by admins.
  db.run(`CREATE TABLE IF NOT EXISTS clubs (id INTEGER PRIMARY KEY, name TEXT NOT NULL, description TEXT NOT NULL, category TEXT NOT NULL, capacity INTEGER NOT NULL DEFAULT 100, active INTEGER NOT NULL DEFAULT 1)`);
// Define membership requests, allowed statuses, and duplicate prevention.
  db.run(`CREATE TABLE IF NOT EXISTS applications (id INTEGER PRIMARY KEY, student_id INTEGER NOT NULL REFERENCES users(id), club_id INTEGER NOT NULL REFERENCES clubs(id), message TEXT NOT NULL DEFAULT '', status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected')), created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, reviewed_at TEXT, reviewed_by INTEGER REFERENCES users(id), UNIQUE(student_id, club_id))`);
// Check whether the database needs its starter club records.
  db.all('SELECT count(*) AS n FROM clubs', (err, rows) => { if (!err && rows[0].n === 0) {
// Prepare a parameterized insert for starter clubs.
    const ins = db.prepare('INSERT INTO clubs(name,description,category,capacity) VALUES(?,?,?,?)');
// Add sample clubs only when the club table is empty.
    [['Cybersecurity Society','Learn practical security, ethical hacking, and digital safety.','Technology',80],['Robotics Club','Build, program, and compete with robots.','Engineering',60],['Photography Club','Explore visual storytelling, composition, and campus events.','Arts',70],['Environmental Action Club','Organize sustainability and conservation projects.','Community',100]].forEach(x=>ins.run(...x)); ins.finalize();
  }});
});
// Run a parameterized SQL command and return its ID/change count.
const run = (sql, params=[]) => new Promise((resolve,reject)=>db.run(sql,params,function(err){err?reject(err):resolve({id:this.lastID,changes:this.changes})}));
// Read one database row using bound parameters.
const get = (sql, params=[]) => new Promise((resolve,reject)=>db.get(sql,params,(err,row)=>err?reject(err):resolve(row)));
// Read multiple database rows using bound parameters.
const all = (sql, params=[]) => new Promise((resolve,reject)=>db.all(sql,params,(err,rows)=>err?reject(err):resolve(rows)));
// Encrypt a value with AES-256-GCM and store its IV and authentication tag.
function encrypt(value) { const iv=crypto.randomBytes(12), cipher=crypto.createCipheriv('aes-256-gcm',encryptionKey,iv); const data=Buffer.concat([cipher.update(String(value),'utf8'),cipher.final()]); return [iv.toString('hex'),cipher.getAuthTag().toString('hex'),data.toString('hex')].join(':'); }
// Decrypt the value and verify its authentication tag before returning it.
function decrypt(value) { const [iv,tag,data]=value.split(':'); const decipher=crypto.createDecipheriv('aes-256-gcm',encryptionKey,Buffer.from(iv,'hex')); decipher.setAuthTag(Buffer.from(tag,'hex')); return Buffer.concat([decipher.update(Buffer.from(data,'hex')),decipher.final()]).toString('utf8'); }
// Make a keyed email digest so the app can find accounts without a plaintext email index.
const emailDigest = email => crypto.createHmac('sha256',encryptionKey).update(email.toLowerCase()).digest('hex');

// 3
// Normalize and validate email addresses on the server.
const emailSchema = z.string().trim().email().max(254).transform(v=>v.toLowerCase());
// Require a longer password with lowercase, uppercase, and number characters.
const passwordSchema = z.string().min(12).max(128).regex(/[a-z]/).regex(/[A-Z]/).regex(/[0-9]/);
// Allow reasonable names while rejecting unexpected characters and lengths.
const nameSchema = z.string().trim().min(2).max(80).regex(/^[\p{L}\p{M} .'-]+$/u);
// Validate student identifiers before they reach database code.
const idSchema = z.string().trim().min(3).max(24).regex(/^[A-Za-z0-9-]+$/);
// Limit and trim optional application messages.
const messageSchema = z.string().trim().max(500).default('');
// Hide Express version details from response headers.
app.disable('x-powered-by');
// Apply browser security headers and restrict loaded content to this site.
app.use(helmet({ contentSecurityPolicy:{ directives:{ defaultSrc:["'self'"], scriptSrc:["'self'"], styleSrc:["'self'"], imgSrc:["'self'","data:"], connectSrc:["'self'"], objectSrc:["'none'"], baseUri:["'self'"], frameAncestors:["'none'"] } }, referrerPolicy:{policy:'no-referrer'} }));
// Accept JSON/form input with a small maximum request size.
app.use(express.json({limit:'20kb'})); app.use(express.urlencoded({extended:false,limit:'20kb'}));
// Store server-side sessions with HttpOnly, SameSite, expiry, and conditional Secure flags.
app.use(session({ name:'club.sid', secret:sessionSecret, resave:false, saveUninitialized:false, store:new SQLiteStore({db:'sessions.sqlite',dir:DATA_DIR,table:'sessions',concurrentDB:true}), cookie:{ httpOnly:true, secure:secureCookies, sameSite:'strict', maxAge:30*60*1000 }, rolling:true }));
// Prevent sensitive pages from being cached by the browser.
app.use((req,res,next)=>{ res.setHeader('Cache-Control','no-store'); next(); });
// Provide a simple endpoint to confirm that the server is responding.
app.get('/api/health',(req,res)=>res.json({ok:true,service:'secure-student-club-system'}));
// Limit login attempts to reduce password guessing.
const loginLimiter=rateLimit({windowMs:15*60*1000,limit:10,standardHeaders:true,legacyHeaders:false,message:{error:'Too many attempts. Try again later.'}});
// Limit account creation attempts.
const registerLimiter=rateLimit({windowMs:60*60*1000,limit:5,standardHeaders:true,legacyHeaders:false});
// Require a session-bound CSRF token for state-changing requests.
function csrf(req,res,next){ if(req.method==='GET'||req.method==='HEAD'||req.method==='OPTIONS') return next(); const token=req.get('x-csrf-token')||req.body?._csrf; if(!req.session.csrf||!token||String(token).length!==req.session.csrf.length||!crypto.timingSafeEqual(Buffer.from(req.session.csrf),Buffer.from(String(token)))) return res.status(403).json({error:'Security token expired. Refresh and try again.'}); next(); }
// Reject protected requests when no user is signed in.
function auth(req,res,next){ if(!req.session.user) return res.status(401).json({error:'Please sign in.'}); next(); }
// Allow a route only when the signed-in user has an allowed role.
function role(...roles){return (req,res,next)=>{if(!req.session.user||!roles.includes(req.session.user.role))return res.status(403).json({error:'You do not have permission to perform this action.'});next();}}
// Validate request fields on the server and return safe field errors.
function validate(schema,source='body'){return(req,res,next)=>{const parsed=schema.safeParse(req[source]); if(!parsed.success)return res.status(400).json({error:'Please check the submitted information.',fields:parsed.error.issues.map(i=>i.path.join('.'))}); req.validated=parsed.data; next();}}
// Create a random CSRF token that the browser must send back.
app.get('/api/csrf',(req,res)=>{req.session.csrf=crypto.randomBytes(32).toString('hex'); res.json({csrfToken:req.session.csrf});});
// Combine registration fields into one server-side validation schema.
const registerSchema=z.object({name:nameSchema,email:emailSchema,password:passwordSchema,studentId:idSchema});

// 3
// Register a student: validate, prevent duplicate email, hash password, encrypt identity, then create a fresh session.
app.post('/api/register',registerLimiter,csrf,validate(registerSchema),async(req,res,next)=>{try{const d=req.validated; if(await get('SELECT id FROM users WHERE email_hash=?',[emailDigest(d.email)]))return res.status(409).json({error:'An account with that email already exists.'}); const hash=await bcrypt.hash(d.password,12); const result=await run('INSERT INTO users(email_hash,email_enc,name_enc,student_id_enc,password_hash,role) VALUES(?,?,?,?,?,?)',[emailDigest(d.email),encrypt(d.email),encrypt(d.name),encrypt(d.studentId),hash,'student']); req.session.regenerate(err=>{if(err)return next(err);req.session.user={id:result.id,role:'student',name:d.name};req.session.csrf=crypto.randomBytes(32).toString('hex');logger.info('account_registered',{userId:result.id});res.status(201).json({ok:true,user:req.session.user,csrfToken:req.session.csrf});});}catch(e){next(e);}});
// Define the fields accepted by the login endpoint.
const loginSchema=z.object({email:emailSchema,password:z.string().min(1).max(128)});
// Sign in: find account, compare bcrypt hash, regenerate session, and issue a fresh CSRF token.
app.post('/api/login',loginLimiter,csrf,validate(loginSchema),async(req,res,next)=>{try{const d=req.validated;const user=await get('SELECT * FROM users WHERE email_hash=?',[emailDigest(d.email)]);const valid=user&&await bcrypt.compare(d.password,user.password_hash);if(!valid){logger.warn('login_failed',{ip:req.ip});return res.status(401).json({error:'Email or password is incorrect.'});}req.session.regenerate(err=>{if(err)return next(err);req.session.user={id:user.id,role:user.role,name:decrypt(user.name_enc)};req.session.csrf=crypto.randomBytes(32).toString('hex');logger.info('login_succeeded',{userId:user.id,role:user.role});res.json({ok:true,user:req.session.user,csrfToken:req.session.csrf});});}catch(e){next(e);}});
// Sign out by destroying the session and clearing its cookie.
app.post('/api/logout',auth,csrf,(req,res)=>{const id=req.session.user.id;req.session.destroy(err=>{if(err)return res.status(500).json({error:'Could not end session.'});res.clearCookie('club.sid',{httpOnly:true,secure:secureCookies,sameSite:'strict'});logger.info('logout',{userId:id});res.json({ok:true});});});
// Return the current session user so the page can restore its state.
app.get('/api/me',(req,res)=>res.json({user:req.session.user||null}));
// Show active clubs; this public list contains no private student records.
app.get('/api/clubs',async(req,res,next)=>{try{res.json(await all('SELECT id,name,description,category,capacity FROM clubs WHERE active=1 ORDER BY name'));}catch(e){next(e);}});
// Return only the signed-in student account own applications.
app.get('/api/applications',auth,async(req,res,next)=>{try{const rows=await all(`SELECT a.id,a.status,a.message,a.created_at,c.id club_id,c.name club_name FROM applications a JOIN clubs c ON c.id=a.club_id WHERE a.student_id=? ORDER BY a.created_at DESC`,[req.session.user.id]);res.json(rows);}catch(e){next(e);}});
// Accept student applications only after login, role, CSRF, and field checks.
app.post('/api/applications',auth,role('student'),csrf,validate(z.object({clubId:z.coerce.number().int().positive(),message:messageSchema})),async(req,res,next)=>{try{const d=req.validated;if(!await get('SELECT id FROM clubs WHERE id=? AND active=1',[d.clubId]))return res.status(404).json({error:'Club not found.'});const result=await run('INSERT INTO applications(student_id,club_id,message) VALUES(?,?,?)',[req.session.user.id,d.clubId,d.message]);logger.info('application_submitted',{userId:req.session.user.id,clubId:d.clubId,applicationId:result.id});res.status(201).json({ok:true});}catch(e){if(e.code==='SQLITE_CONSTRAINT')return res.status(409).json({error:'You already applied to this club.'});next(e);}});
// Allow admins to view requests and decrypt student details for review.
app.get('/api/admin/applications',auth,role('admin'),async(req,res,next)=>{try{const rows=await all(`SELECT a.id,a.status,a.message,a.created_at,u.id student_id,u.name_enc,u.email_enc,u.student_id_enc,c.name club_name FROM applications a JOIN users u ON u.id=a.student_id JOIN clubs c ON c.id=a.club_id ORDER BY CASE a.status WHEN 'pending' THEN 0 ELSE 1 END,a.created_at`);res.json(rows.map(x=>({id:x.id,status:x.status,message:x.message,created_at:x.created_at,studentId:x.student_id,name:decrypt(x.name_enc),email:decrypt(x.email_enc),institutionId:decrypt(x.student_id_enc),club_name:x.club_name})));}catch(e){next(e);}});
// Allow admins to decide pending requests and enforce club capacity.
app.patch('/api/admin/applications/:id',auth,role('admin'),csrf,validate(z.object({status:z.enum(['approved','rejected'])})),async(req,res,next)=>{try{const id=Number(req.params.id);if(!Number.isSafeInteger(id))return res.status(400).json({error:'Invalid application.'});if(req.validated.status==='approved'){const appRow=await get("SELECT a.club_id,c.capacity FROM applications a JOIN clubs c ON c.id=a.club_id WHERE a.id=? AND a.status='pending'",[id]);if(!appRow)return res.status(404).json({error:'Pending application not found.'});const count=await get("SELECT count(*) AS n FROM applications WHERE club_id=? AND status='approved'",[appRow.club_id]);if(count.n>=appRow.capacity)return res.status(409).json({error:'This club has reached its member capacity.'});}const out=await run("UPDATE applications SET status=?,reviewed_at=CURRENT_TIMESTAMP,reviewed_by=? WHERE id=? AND status='pending'",[req.validated.status,req.session.user.id,id]);if(!out.changes)return res.status(404).json({error:'Pending application not found.'});logger.info('application_reviewed',{adminId:req.session.user.id,applicationId:id,status:req.validated.status});res.json({ok:true});}catch(e){next(e);}});
// Restrict the club-management list to admins.
app.get('/api/admin/clubs',auth,role('admin'),async(req,res,next)=>{try{res.json(await all('SELECT * FROM clubs ORDER BY name'));}catch(e){next(e);}});
// Validate club name, description, category, capacity, and active status.
const clubSchema=z.object({name:z.string().trim().min(2).max(80),description:z.string().trim().min(10).max(500),category:z.string().trim().min(2).max(40),capacity:z.coerce.number().int().min(1).max(1000),active:z.coerce.boolean().default(true)});
// Create a club after admin, CSRF, validation, and duplicate-name checks.
app.post('/api/admin/clubs',auth,role('admin'),csrf,validate(clubSchema),async(req,res,next)=>{try{const d=req.validated;if(await get('SELECT id FROM clubs WHERE lower(name)=lower(?)',[d.name]))return res.status(409).json({error:'A club with that name already exists.'});const out=await run('INSERT INTO clubs(name,description,category,capacity,active) VALUES(?,?,?,?,?)',[d.name,d.description,d.category,d.capacity,d.active?1:0]);logger.info('club_created',{adminId:req.session.user.id,clubId:out.id});res.status(201).json({ok:true});}catch(e){next(e);}});
// Update a club with the same authorization and duplicate-name protections.
app.put('/api/admin/clubs/:id',auth,role('admin'),csrf,validate(clubSchema),async(req,res,next)=>{try{const id=Number(req.params.id);if(!Number.isSafeInteger(id))return res.status(400).json({error:'Invalid club.'});const d=req.validated;if(await get('SELECT id FROM clubs WHERE lower(name)=lower(?) AND id<>?',[d.name,id]))return res.status(409).json({error:'A different club already uses that name.'});const out=await run('UPDATE clubs SET name=?,description=?,category=?,capacity=?,active=? WHERE id=?',[d.name,d.description,d.category,d.capacity,d.active?1:0,id]);if(!out.changes)return res.status(404).json({error:'Club not found.'});logger.info('club_updated',{adminId:req.session.user.id,clubId:id});res.json({ok:true});}catch(e){next(e);}});
// Show approved membership details only to admins.
app.get('/api/admin/members',auth,role('admin'),async(req,res,next)=>{try{const rows=await all(`SELECT u.name_enc,u.email_enc,u.student_id_enc,c.name club_name,a.created_at FROM applications a JOIN users u ON a.student_id=u.id JOIN clubs c ON a.club_id=c.id WHERE a.status='approved' ORDER BY c.name`);res.json(rows.map(x=>({name:decrypt(x.name_enc),email:decrypt(x.email_enc),studentId:decrypt(x.student_id_enc),club:x.club_name,joinedAt:x.created_at})));}catch(e){next(e);}});
// Make the README guide available from the running application.
app.get('/project-guide',(req,res)=>res.type('text/plain').sendFile(path.join(ROOT,'README.md')));
// Make the security checklist available from the running application.
app.get('/security-guide',(req,res)=>res.type('text/plain').sendFile(path.join(ROOT,'SECURITY.md')));
// Serve the browser interface files from the public folder.
app.use(express.static(path.join(ROOT,'public'),{etag:false,maxAge:0}));
// Log internal request errors but return a generic message to the browser.
app.use((err,req,res,next)=>{logger.error('request_error',{message:err.message,route:req.path,method:req.method});if(res.headersSent)return next(err);res.status(500).json({error:'Something went wrong. Please try again.'});});

// Create the configured admin once; store a bcrypt hash and encrypted identity fields.
async function bootstrapAdmin(){const email=process.env.ADMIN_EMAIL,password=process.env.ADMIN_PASSWORD;if(!email||!password){logger.warn('Admin not seeded: set ADMIN_EMAIL and ADMIN_PASSWORD in .env');return;}const parsed=emailSchema.safeParse(email), validPassword=passwordSchema.safeParse(password);if(!parsed.success||!validPassword.success)throw new Error('ADMIN_EMAIL or ADMIN_PASSWORD does not meet validation rules.');if(await get('SELECT id FROM users WHERE email_hash=?',[emailDigest(parsed.data)]))return;const hash=await bcrypt.hash(password,12);await run('INSERT INTO users(email_hash,email_enc,name_enc,password_hash,role) VALUES(?,?,?,?,?)',[emailDigest(parsed.data),encrypt(email),encrypt(process.env.ADMIN_NAME||'Club Administrator'),hash,'admin']);logger.info('admin_seeded');}
// Start HTTPS when TLS files exist; otherwise start the local HTTP server and log startup failures.
bootstrapAdmin().then(()=>{const port=Number(process.env.PORT||3000);const host=process.env.HOST||'127.0.0.1';if(useTls){const server=https.createServer({key:fs.readFileSync(process.env.TLS_KEY_PATH),cert:fs.readFileSync(process.env.TLS_CERT_PATH)},app);server.listen(port,host,()=>logger.info('server_started',{url:`https://${host}:${port}`,port,https:true}));}else http.createServer(app).listen(port,host,()=>logger.info('server_started',{url:`http://${host}:${port}`,port,https:false,environment:process.env.NODE_ENV||'development'}));}).catch(e=>{logger.error('startup_failed',{message:e.message});process.exit(1);});
