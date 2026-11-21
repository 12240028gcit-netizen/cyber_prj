$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
$evidence = Join-Path $root '.tmp-doc\new-assignment-review'
$outDoc = Join-Path $root 'ELE201_Dawa_12240028.docx'
$outPdf = Join-Path $root 'ELE201_Dawa_12240028.pdf'
$font = 'Aptos'
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $word.Documents.Add()
$sel = $word.Selection
$doc.PageSetup.TopMargin = 54
$doc.PageSetup.BottomMargin = 54
$doc.PageSetup.LeftMargin = 62
$doc.PageSetup.RightMargin = 62

function Add-Para([string]$Text, [string]$Style = 'Normal', [bool]$Bold = $false) {
  $script:sel.Style = $Style
  $script:sel.Font.Name = $script:font
  if ($Style -eq 'Normal') { $script:sel.Font.Size = 10; $script:sel.Font.Color = 0x26374A }
  $script:sel.Font.Bold = $Bold
  $script:sel.ParagraphFormat.SpaceAfter = 6
  $script:sel.TypeText($Text)
  $script:sel.TypeParagraph()
}
function Add-Heading([string]$Text, [int]$Level = 1) {
  Add-Para $Text "Heading $Level"
  $script:sel.Font.Name = $script:font
  $script:sel.Font.Color = 0x137C72
}
function Add-Bullet([string]$Text) {
  $script:sel.Style = 'List Bullet'; $script:sel.Font.Name=$script:font; $script:sel.Font.Size=10; $script:sel.Font.Color=0x26374A
  $script:sel.TypeText($Text); $script:sel.TypeParagraph()
}
function Add-Table([string[]]$Headers, [object[]]$Rows) {
  $t = $script:doc.Tables.Add($script:sel.Range, $Rows.Count + 1, $Headers.Count)
  $t.Style = 'Table Grid'; $t.AllowAutoFit = $true; $t.AutoFitBehavior(2)
  $t.Range.Font.Name = $script:font; $t.Range.Font.Size = 8.5; $t.Range.Font.Color = 0x26374A
  for ($c=0; $c -lt $Headers.Count; $c++) { $cell=$t.Cell(1,$c+1); $cell.Range.Text=[string]$Headers[$c]; $cell.Range.Font.Bold=$true; $cell.Shading.BackgroundPatternColor=0xE8F0F8 }
  for ($r=0; $r -lt $Rows.Count; $r++) { for ($c=0; $c -lt $Headers.Count; $c++) { $t.Cell($r+2,$c+1).Range.Text=[string]$Rows[$r][$c] } }
  $script:sel.SetRange($t.Range.End,$t.Range.End); $script:sel.TypeParagraph()
}
function Add-Figure([int]$N,[string]$Title,[string]$Description,[string]$File) {
  Add-Para "Figure $N  |  $Title" 'Heading 3'
  $p=Join-Path $script:evidence $File
  if (!(Test-Path -LiteralPath $p)) { throw "Missing evidence image: $p" }
  $inline=$script:sel.InlineShapes.AddPicture($p,$false,$true)
  $inline.LockAspectRatio = -1; $inline.Width = 432
  $script:sel.TypeParagraph()
  Add-Para $Description 'Caption'
}
function Add-PageBreak { $script:sel.InsertBreak(7) }

# Cover page
$sel.Style='Title'; $sel.Font.Name=$font; $sel.Font.Size=27; $sel.Font.Bold=$true; $sel.Font.Color=0x102A43
$sel.TypeText('Secure Student Club Registration'); $sel.TypeParagraph()
$sel.Style='Subtitle'; $sel.Font.Name=$font; $sel.Font.Size=16; $sel.Font.Color=0x137C72
$sel.TypeText('ELE201 Secure Coding Project Submission'); $sel.TypeParagraph(); $sel.TypeParagraph()
Add-Para 'Individual Project Documentation and Security Evidence' 'Subtitle'
Add-Para 'Prepared for ELE201 Secure Coding' 'Normal'
Add-Table @('Submission detail','Value') @(
  ,@('Student','Dawa'),
  ,@('Student ID','12240028'),
  ,@('Project','Secure Student Club Registration and Membership Management System'),
  ,@('Assignment','ELE201 Assignment 2026'),
  ,@('Submission filename','ELE201_Dawa_12240028.pdf'),
  ,@('Local demonstration address','http://127.0.0.1:3000 (development HTTP)')
)
Add-Para 'Purpose and evidence note' 'Heading 2'
Add-Para 'This document explains the implemented student club application and maps its security controls to the assignment requirements. It includes screenshots of the project interface markup and annotated source excerpts. The interface screenshots are static captures from the project HTML and CSS; they do not prove a live login session. The local server could not be reached from the document capture environment, so live authentication and security scan results are not claimed.'
Add-PageBreak

# A: overview
Add-Heading 'A. Application Overview'
Add-Para 'The Secure Student Club Registration and Membership Management System provides a web-based process for students to join campus clubs. Students create an account, sign in, browse active clubs, submit membership applications, and check their request status. Club administrators review applications, approve or reject pending requests, create or edit clubs, set capacity, and view approved members.'
Add-Para 'The system has two roles: Student and Club Administrator. Student application results are scoped to the signed-in student. Administrator API routes require an administrator session and return selected student details only to authorized administrators.'
Add-Heading 'Technology and application components',2
Add-Bullet 'Frontend: HTML, CSS, and browser JavaScript in public/index.html, public/styles.css, and public/app.js.'
Add-Bullet 'Backend: Node.js and Express routes in server.js.'
Add-Bullet 'Persistence: SQLite database for users, clubs, applications, and server-side sessions.'
Add-Bullet 'Security packages: bcryptjs, express-session, connect-sqlite3, Node crypto, Zod, Helmet, express-rate-limit, and Winston.'
Add-Heading 'Main features',2
Add-Bullet 'Student registration, login, logout, club browsing, application submission, and status tracking.'
Add-Bullet 'Admin application review, club creation/editing, capacity management, and approved-member listing.'
Add-Bullet 'Server-side role checks, selected PII encryption, password hashing, validation, CSRF protection, session expiry, safe output encoding, and structured logs.'
Add-Para 'Out of scope in this version: profile editing, password reset, email verification, per-club administrator assignment, automated backup/recovery, and a production deployment.'
Add-Heading 'Cyber flow',2
Add-Para 'Browser request -> Helmet and Express middleware -> session authentication -> CSRF check for state changes -> Zod server validation -> role authorization -> parameterized SQLite query -> decrypt selected identity fields only for authorized admin responses -> JSON response -> HTML escaping before browser display. Winston records important events. Registration hashes the password and encrypts selected student details; login compares the bcrypt hash and regenerates the session ID.'
Add-Figure 1 'Student sign-in interface' 'Static screenshot from the project HTML/CSS. It shows the sign-in form layout; it does not demonstrate a live server or successful login.' 'figure-01-login-static.png'
Add-Figure 2 'Student account registration interface' 'Static screenshot from the project HTML/CSS. It shows the registration fields and password guidance; server-side registration must be demonstrated separately.' 'figure-02-registration-static.png'

# B: security controls and screenshots
Add-PageBreak
Add-Heading 'B. Security Implementation Details'
Add-Para 'The rubric asks for authentication and authorization, encryption and protection, validation and sanitization, session management, error handling and logging, secure communication, and testing/auditing. The following sections explain how each is implemented and state the limits of the current local evidence.'
Add-Heading '1. User authentication and authorization',2
Add-Para 'Registration validates the submitted fields, checks for an existing email digest, hashes the password with bcrypt cost 12, encrypts selected identity fields, assigns the student role, and creates a regenerated session. Login looks up the user, compares the supplied password with the bcrypt hash, returns the same generic error for a failed attempt, regenerates the session ID on success, and issues a fresh CSRF token. Login and registration attempts are rate-limited. The auth middleware returns 401 for a signed-out request; the role middleware returns 403 when the role is not allowed. Student application queries include the current session user ID.'
Add-Para 'Code locations: server.js registration/login handlers, auth and role middleware, /api/applications, and /api/admin routes. The browser switches between student and admin panels, but server-side route checks provide the security boundary.'
Add-Figure 3 'Password hashing and role checks' 'Annotated source excerpts from server.js. bcrypt.hash stores a one-way password hash; bcrypt.compare verifies a login; auth and role middleware protect routes.' 'figure-auth.png'
Add-Heading '2. Data encryption and protection',2
Add-Para 'Names, emails, and student IDs are encrypted at rest using AES-256-GCM with a random 12-byte IV and an authentication tag. The key is read from DATA_ENCRYPTION_KEY. A keyed HMAC digest of the normalized email supports lookup without storing a plaintext email index. Passwords are bcrypt hashes, not reversible encryption. SQLite query helpers bind parameters.'
Add-Para 'Limitations: only selected identity fields are encrypted, not the entire database, logs, backups, or host filesystem. The encryption key is also currently used for the email HMAC; a stronger deployment would derive separate keys. Losing the key prevents decrypting stored identity values. Never place .env, real student records, or secrets in screenshots or a shared archive.'
Add-Figure 4 'AES-GCM data protection' 'Annotated source excerpts show AES-GCM cipher creation, authentication tag use, decryption, and protected database columns. No secret key or real student data is shown.' 'figure-data.png'
Add-Heading '3. Input validation and output sanitization',2
Add-Para 'Zod schemas validate email, password, name, student ID, messages, club fields, numeric capacity, and allowed application decisions. The server rejects invalid fields before database operations. Request bodies are limited to 20 KB. SQL values are supplied as bound parameters. Browser code escapes HTML-significant characters before inserting dynamic data. Helmet sets a restrictive Content Security Policy. HTML form constraints provide user guidance but do not replace server validation.'
Add-Para 'The project uses contextual HTML encoding in its escape helper; it does not use a separate DOMPurify package. Avoid describing this as "DOMPurify sanitization."'
Add-Figure 5 'Server validation and browser output encoding' 'Annotated source excerpts show a Zod schema, validation middleware, parameter binding, the CSP, and the browser escape helper.' 'figure-validation.png'
Add-Heading '4. Session management',2
Add-Para 'Sessions are stored in SQLite. The cookie is HttpOnly, SameSite=Strict, and has a 30-minute rolling maximum age. Its Secure flag is conditional on production mode or direct TLS. Login and registration regenerate the session ID, reducing session fixation risk. A session-bound random CSRF token is compared in constant time on state-changing requests. Logout destroys the server-side session and clears the cookie.'
Add-Para 'Current local setup: NODE_ENV is development and TLS key/certificate paths are empty. Therefore the local connection is HTTP and does not demonstrate a Secure cookie.'
Add-Figure 6 'Session cookie, CSRF, and logout controls' 'Annotated source excerpts show the SQLite session store, cookie flags and expiry, CSRF comparison, session regeneration, and session destruction.' 'figure-sessions.png'
Add-Heading '5. Error handling and logging',2
Add-Para 'Winston writes timestamped structured events to logs/security.log and the console. The application logs authentication outcomes and major account, application, and club actions. The central Express error handler returns a generic response instead of a stack trace or database error. Internal error messages are written to the private log, so access to logs should be restricted.'
Add-Figure 7 'Structured logging and safe error response' 'Annotated source excerpts show the Winston logger, security event logging, and the central generic error response.' 'figure-logging.png'
Add-Heading '6. Secure communication',2
Add-Para 'server.js can create an HTTPS server if both TLS_KEY_PATH and TLS_CERT_PATH point to valid files. It otherwise starts HTTP. Production can terminate TLS at a trusted reverse proxy; TRUST_PROXY should be enabled only behind a trusted proxy. The app does not itself redirect HTTP to HTTPS. The current local configuration is development HTTP, so the rubrics HTTPS requirement is not yet evidenced as active.'
Add-Figure 8 'HTTPS configuration and current limitation' 'Source excerpt shows the optional TLS path and HTTP fallback. This is evidence of code support, not an active HTTPS connection or certificate. Configure and capture a valid HTTPS deployment before claiming this rubric item complete.' 'figure-transport.png'
Add-Heading '7. Security testing and auditing',2
Add-Para 'SECURITY.md contains a checklist and instructions to record actual results. A prior PowerShell output supplied during project preparation showed the health endpoint returning HTTP 200 and ok=true. That proves reachability only. This capture environment could not connect to the local app, and no OWASP ZAP report or full penetration test is available here. Do not report expected outcomes as measured results.'
Add-Para 'GDPR, FERPA, and HIPAA compliance is not claimed. Institutional review, retention rules, lawful basis, operational controls, and applicable policy decisions are outside this teaching prototype.'
Add-Figure 9 'Security testing evidence plan' 'Annotated excerpt from SECURITY.md. It shows the audit procedure, not completed scan results. Add dated evidence of checks and remediation before final Moodle submission.' 'figure-audit.png'

# C: component breakdown
Add-PageBreak
Add-Heading 'C. Component Breakdown'
Add-Para 'The table identifies each major component, its purpose, the security feature it contributes, and where to find it in the project.'
Add-Table @('Component','Purpose','Security feature and source location') @(
 ,@('Authentication','Create accounts and sign users in/out.','bcrypt cost 12, rate limits, generic failed-login response, session rotation. server.js registration/login routes; public/app.js form handlers.'),
 ,@('Authorization','Restrict student and admin actions.','auth/role middleware; student-owned application query; admin routes. server.js API routes.'),
 ,@('Data protection','Persist user and membership records.','AES-GCM selected identity fields; HMAC email lookup; parameterized SQLite operations. server.js crypto helpers and data schema.'),
 ,@('Input validation and output','Check inputs and render responses safely.','Zod schemas, 20 KB request limit, bound SQL values, HTML escaping, Helmet CSP. server.js and public/app.js.'),
 ,@('Session management','Maintain login state.','SQLite session store, 30-minute expiry, HttpOnly/SameSite, conditional Secure, CSRF, logout. server.js.'),
 ,@('Membership workflow','Submit and review club applications.','Unique student/club request, pending-only decisions, capacity check, reviewer/time fields, audit events. server.js.'),
 ,@('Club management','Create and update clubs.','Admin-only routes, validation, duplicate-name checks, parameterized SQL. server.js and public/app.js.'),
 ,@('Error handling and logs','Handle failures and record events.','Generic user-facing errors and Winston structured logs. server.js.'),
 ,@('Secure communication','Protect traffic in deployment.','Optional direct TLS or trusted reverse proxy guidance. Current local run remains HTTP. server.js and README.md.'),
 ,@('Security audit','Plan and report security checks.','SECURITY.md verification checklist; actual scan evidence remains to be added.')
)

# D: challenge and fixes
Add-PageBreak
Add-Heading 'D. Challenges and Solutions'
Add-Table @('Challenge encountered','Resolution and lesson') @(
 ,@('SESSION_SECRET missing or too short prevented server startup.','A long random value was placed in the private .env file. The server validates length before starting.'),
 ,@('DATA_ENCRYPTION_KEY still contained placeholder text and failed the 64-hex-character requirement.','A fresh 32-byte random key was configured as 64 hex characters. Keep the key private and preserve a protected backup.'),
 ,@('TLS_KEY_PATH was entered as key text rather than a path to a certificate file.','Clear TLS paths for local HTTP; direct HTTPS requires actual matching key and certificate files.'),
 ,@('Club form reset error occurred after an asynchronous save.','The handler captures the form reference before awaiting the API request and resets only after success.'),
 ,@('PowerShell displayed a web-content parsing warning during the health check.','The response still returned HTTP 200. Use Invoke-WebRequest -UseBasicParsing for the local health check.')
)
Add-Para 'The app has previously returned a successful health response according to the supplied PowerShell output, but that result did not prove login, RBAC, CSRF, injection handling, or TLS.'

# E: security summary
Add-Heading 'E. Security Summary'
Add-Table @('Security objective','Implementation in this project','Current evidence limit') @(
 ,@('Confidentiality','bcrypt password hashes, AES-GCM selected identity fields, keyed email lookup, role-restricted private records.','Database file and backups are not encrypted as a whole; local traffic is HTTP.'),
 ,@('Integrity','Server validation, prepared SQL, CSRF tokens, server-side roles, uniqueness checks, pending-only decisions, capacity checks, audit events.','Full attack testing and independent code review are not documented.'),
 ,@('Availability','Login/registration limits, small request-body limit, persistent SQLite storage, generic error handling.','No configured backup, monitoring, disaster recovery, or multi-instance deployment.')
)
Add-Para 'The system demonstrates security controls in source code, but this report does not claim every rubric item has passed live verification. HTTPS deployment and completed security-test evidence remain outstanding.'

# F: repository
Add-Heading 'F. Repository or Drive Link'
Add-Para 'Submission platform specified by the assignment: VLE Moodle.'
Add-Para "Repository link was not provided. Insert the real GitLab or Drive URL before submission."
Add-Para 'Required naming convention: ELE201_Dawa_12240028.zip for the project archive and ELE201_Dawa_12240028.pdf for this report. Exclude .env, session files, databases containing personal records, and logs from a public/shared archive.'

# G: audit matrix
Add-PageBreak
Add-Heading 'G. Security Verification Checklist'
Add-Para "The status column distinguishes the result previously supplied from checks that still need to be run and recorded in your local environment."
Add-Table @('Check','Expected evidence','Status in this report') @(
 ,@('Health endpoint','HTTP 200 and JSON ok=true.','Previously supplied PowerShell result; not recaptured here.'),
 ,@('Signed-out user requests applications','HTTP 401.','Not run for this report.'),
 ,@('Student requests administrator endpoint','HTTP 403.','Not run for this report.'),
 ,@('Invalid registration or missing CSRF','Safe 400 validation response or 403 CSRF response.','Not run for this report.'),
 ,@('Duplicate application and club capacity','409 duplicate response; capacity rule enforced.','Not run for this report.'),
 ,@('SQL injection-style input','Input remains data; no query structure change.','Not run for this report.'),
 ,@('XSS-style text','Text is encoded and does not execute as script.','Not run for this report.'),
 ,@('Logout/session reuse','Old session no longer authenticates; protected request returns 401.','Not run for this report.'),
 ,@('Repeated failed logins','Rate limiter rejects excess attempts.','Not run for this report.'),
 ,@('HTTPS and Secure cookie','Valid HTTPS certificate, HTTPS page, Secure cookie.','Not configured in current local setup.'),
 ,@('OWASP ZAP/code review','Dated findings, fixes, retest results, and screenshots.','No scan or formal review result supplied.')
)
Add-Para 'For every check, record the date, environment, expected result, actual result, and remediation. Do not turn the expected result into a claimed pass. Redact session cookies, secret values, and real student information from evidence.'

# Viva notes
Add-Heading 'Viva Preparation'
Add-Heading 'Short system walkthrough',2
Add-Bullet '"The browser sends the form. Express validates it on the server and checks the session, CSRF token, and role for protected operations."'
Add-Bullet '"Passwords are hashed using bcrypt. Selected student identity fields are encrypted with AES-256-GCM before they are saved."'
Add-Bullet '"SQL values use parameters, and browser output is HTML-escaped to reduce injection risks."'
Add-Bullet '"The server stores login sessions in SQLite, rotates session IDs after login, and destroys sessions at logout."'
Add-Bullet '"Winston records security events. In this local configuration the app uses HTTP, so I am not claiming HTTPS is active."'
Add-Heading 'Likely questions',2
Add-Para 'Why bcrypt? It stores a one-way password hash and makes password guessing more expensive. Why AES-GCM? It encrypts selected personal information and checks ciphertext integrity. Why enforce roles in Express? A user can bypass hidden browser controls, so every protected API must check permission on the server. What does CSRF protection do? It requires a random token tied to the user session on state-changing requests. Is the current demo HTTPS? No. It uses local development HTTP; TLS support exists but is not configured or demonstrated. What testing is complete? The health response was previously reported as HTTP 200; the full manual security matrix and external scan still need actual results.'
Add-Heading 'Before uploading',2
Add-Bullet 'Replace static interface captures with fresh screenshots from the running application if the instructor expects live interaction evidence.'
Add-Bullet 'Configure valid HTTPS and capture the certificate and Secure cookie only if claiming transport protection is active.'
Add-Bullet 'Run and document the required manual checks or OWASP ZAP scan; include actual findings and fixes.'
Add-Bullet 'Insert the actual GitLab or viewable Drive link in Section F.'
Add-Bullet 'Upload ELE201_Dawa_12240028.pdf and the required project ZIP to VLE Moodle.'

# Save editable DOCX and matching PDF
$doc.SaveAs2($outDoc,16)
$doc.ExportAsFixedFormat($outPdf,17)
$pages=$doc.ComputeStatistics(2)
$doc.Close(0); $word.Quit()
[Runtime.InteropServices.Marshal]::ReleaseComObject($doc)|Out-Null
[Runtime.InteropServices.Marshal]::ReleaseComObject($word)|Out-Null
Write-Output "Created submission DOCX and PDF with $pages pages."


