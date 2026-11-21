$ErrorActionPreference='Stop'
$script:parts = [System.Collections.Generic.List[string]]::new()
function Rtf([string]$s) {
  $s=$s.Replace('\','\\').Replace('{','\{').Replace('}','\}')
  $b=New-Object System.Text.StringBuilder
  foreach($ch in $s.ToCharArray()) { if([int]$ch -gt 127){ [void]$b.Append('\u'+([int]$ch)+'?') } else { [void]$b.Append($ch) } }
  $b.ToString()
}
function RHead([string]$s,[int]$level=1) { $size=if($level -eq 1){32}else{25}; $before=if($level -eq 1){260}else{180}; $script:parts.Add("\pard\sb$before\sa100\keepn\fs$size\cf1\b $(Rtf $s)\b0\cf0\fs20\par") }
function P([string]$s) { $script:parts.Add("\pard\sa100\sl260\slmult1\fs20\cf0 $(Rtf $s)\par") }
function B([string]$s) { $script:parts.Add("\pard\li360\fi-220\sa65\fs20\cf0\bullet\tab $(Rtf $s)\par") }
function E([int]$n,[string]$title,[string]$description,[string]$status='Capture from the running application before final submission.') { $script:parts.Add("\pard\sb100\sa120\brdrt\brdrl\brdrb\brdrr\brdrs\brdrw10\brdrcf2\highlight2\cf1\fs19\b FIGURE $n - $(Rtf $title)\b0\par\pard\li180\ri180\sa70\highlight2\cf0\fs18 $(Rtf $description)\par\pard\li180\ri180\sa100\highlight2\cf1\fs17 Evidence status: $(Rtf $status)\highlight0\par") }
function TableRows([object[]]$items) { foreach($item in $items){ $script:parts.Add("\pard\li180\ri180\sa75\fs18\cf0\b $(Rtf ([string]$item[0]))\b0  $(Rtf ([string]$item[1]))\par") } }

$script:parts.Add('{\rtf1\ansi\deff0{\fonttbl{\f0 Aptos;}{\f1 Consolas;}}{\colortbl;\red16\green42\blue67;\red253\green243\blue215;\red71\green116\blue170;}\paperw12240\paperh15840\margl1080\margr1080\margt900\margb900\viewkind4\widowctrl')
# Cover
$script:parts.Add('\pard\sb1800\sa240\qc\fs54\cf1\b Secure Student Club Registration\b0\par')
$script:parts.Add('\pard\sa240\qc\fs32\cf3 ELE201 Secure Coding Project Documentation\par')
$script:parts.Add('\pard\sa550\qc\fs22 Individual Project and Security Implementation Report\par')
$script:parts.Add('\pard\sa180\qc\fs22 Student: Dawa\par\pard\sa180\qc\fs22 Student ID: 12240028\par\pard\sa180\qc\fs22 Date: 12 November 2026\par\pard\sa500\qc\fs20 Local demo: http://127.0.0.1:3000\par')
P 'Purpose: This report answers the ELE201 documentation requirements by describing the implemented application, mapping security controls to source code, and identifying evidence still needed. The developer-provided PowerShell output shows the local health endpoint returned HTTP 200. That confirms server reachability only; login and the full security test set still need verification.'
$script:parts.Add('\page')

RHead 'A. Application Overview'
P 'The Secure Student Club Registration and Membership Management System replaces informal club sign-up with a web workflow. Students register, sign in, browse clubs, submit membership applications, and view pending, approved, or rejected decisions. Club administrators review applications, approve or reject pending requests, create and edit club listings, set member capacity, and view approved members.'
P 'The two roles are Student and Club Administrator. Students can browse clubs and access only their own applications. Administrators can review requests and maintain club information. Express checks authorization on the server for each restricted API route.'
P 'Technologies: Node.js, Express, SQLite, HTML, CSS, browser JavaScript, bcryptjs, express-session with a SQLite store, Node crypto (AES-256-GCM and HMAC), Zod, Helmet, express-rate-limit, and Winston.'
RHead 'Main features',2
B 'Student registration, login, logout, club browsing, membership applications, and status tracking.'
B 'Administrator review of applications, club creation and editing, member capacity settings, and approved-member list.'
B 'Encrypted student identity fields, server-side role checks, validated inputs, CSRF protection, secure session configuration, and structured security logs.'
P 'Scope note: profile editing, password reset, email verification, per-club administrator assignment, automated backups, and production deployment are not implemented in this version.'
RHead 'Cyber flow',2
P 'Browser -> Helmet and Express middleware -> session and CSRF checks -> Zod validation -> role authorization -> parameterized SQLite operation -> AES-GCM decryption only for an authorized admin response -> JSON response -> escaped browser rendering. Winston records important events. Registration hashes passwords with bcrypt and encrypts student PII before storage. Login compares the bcrypt hash and rotates the session ID.'
RHead 'Run configuration',2
P 'Install dependencies with npm install, keep .env private, and start with npm start. On the same computer, open http://127.0.0.1:3000. The health endpoint is http://127.0.0.1:3000/api/health. Local development uses HTTP and is not HTTPS evidence.'
$script:parts.Add('\page')

RHead 'B. Security Implementation Details'
RHead '1. Authentication and authorization',2
P 'Passwords are stored as bcrypt hashes using cost 12. Registration and login validate values on the server. Login uses a generic error for unknown email or incorrect password and is rate-limited. Successful registration and login regenerate the session ID. The auth middleware requires a signed-in session; the role middleware requires admin for admin endpoints. Student application queries are scoped to the session user.'
P 'Source references: server.js registration/login handlers, bcrypt.hash and bcrypt.compare, auth and role middleware, /api/applications, and /api/admin routes. Passwords are not stored or logged in plaintext.'
E 1 'Registration and sign-in pages' 'Capture both forms in a browser using test data. Keep the browser address bar visible and do not show real student details.'
E 2 'bcrypt hashing and server-side RBAC' 'Capture bcrypt code, auth/role middleware, and a student request to an administrator endpoint returning 403.'
RHead '2. Data encryption and protection',2
P 'Names, emails, and student IDs are encrypted with AES-256-GCM using a random 12-byte IV and an authentication tag. The 32-byte key is read from DATA_ENCRYPTION_KEY in .env. A keyed HMAC of normalized email supports lookup without a plaintext email index. Passwords use bcrypt. SQL values use bound parameters.'
P 'Selected identity fields are encrypted at rest; this does not encrypt the whole SQLite file, logs, backups, or host filesystem. Losing the key makes those encrypted values unrecoverable. Key rotation requires migration. Never include secret values in screenshots or a repository.'
E 3 'AES-GCM protection at rest' 'Capture encryption/decryption code and a database row showing ciphertext and a password hash. Redact the key and personal data.'
RHead '3. Input validation and output sanitization',2
P 'Zod schemas enforce types, formats, length bounds, numeric ranges, and allowed status values on the server. Request bodies are limited to 20 KB. Prepared SQL statements prevent input from changing query structure. Browser code escapes HTML-significant characters before inserting dynamic text. Helmet CSP limits script and style sources to the local origin and blocks object embedding.'
P 'HTML input constraints provide usability but are not the security boundary; server validation is. This version uses contextual HTML encoding in its render helper and does not include a separate DOMPurify package.'
E 4 'Validation, parameterized queries, CSP, and output encoding' 'Capture Zod schemas, a prepared query, the escape helper, and an invalid-input response with a safe message.'
RHead '4. Session management',2
P 'Sessions are stored in SQLite with a 30-minute rolling expiry. Login and registration regenerate the session identifier. Cookies use HttpOnly and SameSite=Strict. Secure is enabled when direct TLS is configured or NODE_ENV is production. State-changing routes require a random session-bound CSRF token. Logout destroys the server-side session and clears the cookie.'
P 'The current local environment uses HTTP, so it does not demonstrate the Secure cookie attribute. Capture cookie flags only after using HTTPS.'
E 5 'Session expiration, cookie flags, CSRF, and logout' 'Capture session configuration, the CSRF request, cookie flags on HTTPS, and a logged-out API request returning 401. Redact cookie values.'
RHead '5. Error handling and logging',2
P 'Asynchronous route errors go to a central handler that returns a generic message instead of stack traces or database details. Winston writes timestamped JSON events to logs/security.log and the console. Events cover registration, login success/failure, logout, application submission/review, and club changes. Passwords, CSRF tokens, and session IDs are not logged.'
E 6 'Safe error handling and Winston audit log' 'Capture the error handler, logger setup, a safe user-facing error, and a minimized structured log entry.'
RHead '6. Secure communication',2
P 'The app can serve HTTPS directly when TLS key and certificate paths are set. A trusted reverse proxy can terminate TLS; TRUST_PROXY=1 is appropriate only behind a trusted proxy. The current local run is HTTP at 127.0.0.1:3000. The application does not enforce an HTTP-to-HTTPS redirect itself, so secure transport is not yet demonstrated for this local run.'
E 7 'HTTPS and Secure cookie configuration' 'Capture only after a valid TLS certificate is configured: HTTPS address, certificate details, and Secure cookie attribute. Local HTTP is not HTTPS evidence.'
RHead '7. Security testing and auditing',2
P 'Evidence available: JavaScript syntax checks passed for server.js and public/app.js. The developer-provided console output shows /api/health returned HTTP 200 with ok=true. The PowerShell parsing warning was emitted by Invoke-WebRequest; it was followed by a successful 200 response. These checks do not verify login, authorization, injection handling, CSRF, rate limiting, or HTTPS.'
P 'No OWASP ZAP scan or full penetration test is claimed. Complete Section G with actual results. GDPR, FERPA, and HIPAA compliance is not claimed; the institution must determine applicable rules and operational controls.'
E 8 'Health endpoint response' 'Insert a screenshot of the PowerShell output showing HTTP 200 and the JSON health response.' 'User-provided console result: HTTP 200; not a security test.'
E 9 'Security test results and fixes' 'Capture actual manual or OWASP ZAP results, date, finding, remediation, and retest.' 'Not yet completed; do not present this slot as passing evidence.'
$script:parts.Add('\page')

RHead 'C. Component Breakdown'
TableRows @(
  ,@('Authentication','Register/login/logout; bcrypt cost 12, rate limit, generic error, session rotation. Code: server.js auth routes.'),
  ,@('Authorization','Session checks, student/admin RBAC, own-record scope. Code: auth/role middleware.'),
  ,@('Student workspace','Club browse/apply/status with escaped output. Code: public/app.js and /api routes.'),
  ,@('Club management','Admin-only create/edit, capacity, validation and audit. Code: /api/admin/clubs.'),
  ,@('Membership workflow','Unique application, pending-only decisions, reviewer/time audit, capacity check.'),
  ,@('Data protection','AES-GCM for selected PII; keyed HMAC email lookup; bcrypt password hash.'),
  ,@('Validation and output','Zod, request size limit, parameterized SQL, HTML escaping, CSP.'),
  ,@('Session and CSRF','SQLite session store, 30-minute rolling expiry, cookie flags, CSRF, logout invalidation.'),
  ,@('Logging/errors','Generic responses and Winston structured event logging.'),
  ,@('Transport/audit','Optional TLS, health endpoint, manual verification plan; local run remains HTTP.')
)
$script:parts.Add('\page')

RHead 'D. Challenges and Solutions'
TableRows @(
  ,@('Server startup failed because SESSION_SECRET was missing/short.','The server showed a configuration validation error. A long secret was added to the project .env file.'),
  ,@('DATA_ENCRYPTION_KEY was still the example placeholder and had invalid length.','The server rejected it at startup. A fresh 32-byte random key was generated and saved privately in .env.'),
  ,@('TLS path contained a value that was not a certificate file.','Invalid TLS paths were cleared for local HTTP; HTTPS needs actual key and certificate files.'),
  ,@('The login page was reported unavailable although the service started.','The health endpoint later returned 200, proving only API reachability. Browser login flow remains to be verified on your local browser.'),
  ,@('PowerShell showed a script parsing warning on the health check.','The request still returned 200. -UseBasicParsing suppresses this legacy PowerShell warning.')
)
RHead 'E. Security Summary'
P 'Confidentiality: bcrypt password hashes, AES-GCM selected identity fields, keyed HMAC lookup, and RBAC restrict access. HTTPS is required in deployment but is not active in the local run.'
P 'Integrity: server validation, prepared SQL, CSRF tokens, role authorization, unique application constraint, pending-only decisions, capacity checks, and audit logs protect records and decisions.'
P 'Availability: request-size limits, login rate limits, persistent SQLite storage, and safe error handling support reliable operation. Backups, monitoring, multi-instance storage, and recovery plans are not configured.'
RHead 'F. Repository and Submission Link'
P 'Submission platform: VLE Moodle. GitLab URL or Google Drive ZIP link: not supplied. Add the actual repository or viewable Drive URL before submission; do not add an invented link.'
P 'Required naming pattern: ELE201_Dawa_12240028.zip and ELE201_Dawa_12240028.pdf. Exclude .env, database contents, sessions, and logs from a shared ZIP unless your instructor explicitly requests controlled demo data.'
$script:parts.Add('\page')

RHead 'G. Security Verification Checklist'
P 'Record the actual outcome after each check. Only the health endpoint and JavaScript syntax checks have evidence in this report.'
TableRows @(
  ,@('Health endpoint','HTTP 200, ok=true — confirmed from supplied PowerShell output.'),
  ,@('Student calls admin API','Expected 403 — not run.'),
  ,@('Signed-out application request','Expected 401 — not run.'),
  ,@('Invalid registration/password','Expected 400 safe validation response — not run.'),
  ,@('Duplicate club application','Expected 409 and one row — not run.'),
  ,@('SQLi-like input','Expected to be treated as data — not run.'),
  ,@('XSS-like text','Expected to render as encoded text — not run.'),
  ,@('Missing/wrong CSRF token','Expected 403 — not run.'),
  ,@('Logout then reuse session','Expected 401 — not run.'),
  ,@('Repeated failed logins','Expected rate limit — not run.'),
  ,@('HTTPS deployment','Not configured; local run uses HTTP.'),
  ,@('Node syntax checks','Passed for server.js and public/app.js.')
)
RHead 'Required Screenshot Captions',2
TableRows @(
  ,@('Figure 1','Secure student registration and login pages.'),
  ,@('Figure 2','bcrypt password hashing and server-side role-based access control.'),
  ,@('Figure 3','AES-GCM encrypted student information at rest; encryption key hidden.'),
  ,@('Figure 4','Server-side validation, prepared SQL, CSP, and output encoding.'),
  ,@('Figure 5','Session expiry, cookie flags, CSRF token, and logout invalidation.'),
  ,@('Figure 6','Safe error response and structured Winston log.'),
  ,@('Figure 7','HTTPS connection and Secure cookie, after TLS setup.'),
  ,@('Figure 8','PowerShell health endpoint response with HTTP 200.'),
  ,@('Figure 9','Security scan/manual test results and remediation notes.')
)
P 'For every figure, capture the real app or source in your environment, add an annotation, and explain what it demonstrates. Do not expose secrets or real student data. The figure boxes/captions in this report identify required evidence; they are not substitute screenshots.'
RHead 'Viva Preparation',2
P 'Why bcrypt? It makes password guessing expensive and stores no plaintext password. Why AES-GCM? It encrypts selected PII and authenticates ciphertext against tampering. Why enforce roles on the API? Client controls can be bypassed, so each protected request must check the session role. What does CSRF protection do? It requires a session-bound unpredictable token for state-changing requests. Is local transport HTTPS? No; the local project uses HTTP. What tests are complete? Syntax checks and the reported health check only; the remaining matrix still needs to be run.'
P 'Final submission reminder: add real screenshots, actual security test results, and the repository/Drive link. Confirm your full name spelling in the filename before uploading to Moodle.'
$script:parts.Add('}')

$rtfPath=Join-Path (Get-Location) '.tmp-doc\ELE201_Dawa_12240028.rtf'
[IO.File]::WriteAllText($rtfPath,($script:parts -join "`r`n"),[Text.Encoding]::ASCII)
$word=New-Object -ComObject Word.Application; $word.Visible=$false; $word.DisplayAlerts=0
$doc=$word.Documents.Open($rtfPath,$false,$true)
$doc.SaveAs2((Join-Path (Get-Location) 'ELE201_Dawa_12240028.docx'),16)
$doc.ExportAsFixedFormat((Join-Path (Get-Location) 'ELE201_Dawa_12240028.pdf'),17)
$pages=$doc.ComputeStatistics(2); $doc.Close(0); $word.Quit()
[Runtime.InteropServices.Marshal]::ReleaseComObject($doc)|Out-Null; [Runtime.InteropServices.Marshal]::ReleaseComObject($word)|Out-Null
"Created ELE201_Dawa_12240028.docx and ELE201_Dawa_12240028.pdf ($pages pages)."

