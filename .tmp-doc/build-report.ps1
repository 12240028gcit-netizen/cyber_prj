$ErrorActionPreference = 'Stop'
$outDoc = Join-Path (Get-Location) 'ELE201_Dawa_12240028.docx'
$outPdf = Join-Path (Get-Location) 'ELE201_Dawa_12240028.pdf'
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $word.Documents.Add()
$sel = $word.Selection
$doc.PageSetup.TopMargin = 54
$doc.PageSetup.BottomMargin = 54
$doc.PageSetup.LeftMargin = 62
$doc.PageSetup.RightMargin = 62
$bodyFont = 'Aptos'

function Add-Para([string]$Text, [string]$Style = 'Normal') {
  $styleId = switch ($Style) { 'Normal' {-1} 'Heading 1' {-2} 'Heading 2' {-3} 'Heading 3' {-4} 'Title' {-63} 'Subtitle' {-75} 'List Bullet' {-49} default {-1} }
  $script:sel.Style = $styleId
  $script:sel.Font.Name = $script:bodyFont
  $script:sel.Font.Size = 10
  $script:sel.Font.Color = 0x26374A
  $script:sel.TypeText($Text)
  $script:sel.TypeParagraph()
}
function Add-Heading([string]$Text, [int]$Level = 1) { Add-Para $Text "Heading $Level" }
function Add-Bullet([string]$Text) {
  $script:sel.Style = -49
  $script:sel.Font.Name = $script:bodyFont; $script:sel.Font.Size = 10
  $script:sel.TypeText($Text); $script:sel.TypeParagraph()
}
function Add-Table([object[]]$Headers, [object[]]$Rows) {
  $rng = $script:sel.Range
  $t = $script:doc.Tables.Add($rng, $Rows.Count + 1, $Headers.Count)
  $t.Style = 'Table Grid'; $t.AllowAutoFit = $true; $t.AutoFitBehavior(2)
  $t.Range.Font.Name = $script:bodyFont; $t.Range.Font.Size = 8.5; $t.Range.Font.Color = 0x26374A
  for ($c=0; $c -lt $Headers.Count; $c++) { $t.Cell(1,$c+1).Range.Text = [string]$Headers[$c]; $t.Cell(1,$c+1).Range.Font.Bold = $true; $t.Cell(1,$c+1).Shading.BackgroundPatternColor = 0xE8F0F8 }
  for ($r=0; $r -lt $Rows.Count; $r++) { for ($c=0; $c -lt $Headers.Count; $c++) { $t.Cell($r+2,$c+1).Range.Text = [string]$Rows[$r][$c] } }
  $script:sel.SetRange($t.Range.End, $t.Range.End); $script:sel.TypeParagraph()
}
function Add-Evidence([int]$N, [string]$Title, [string]$What, [string]$Status = 'Capture from the running application before final submission.') {
  $txt = "FIGURE $N  |  $Title`r`n$What`r`nEvidence status: $Status"
  $rng = $script:sel.Range
  $t = $script:doc.Tables.Add($rng,1,1); $t.Style = 'Table Grid'; $t.AllowAutoFit = $true; $t.AutoFitBehavior(2)
  $t.Cell(1,1).Range.Text = $txt; $t.Cell(1,1).Shading.BackgroundPatternColor = 0xFDF3D7
  $t.Cell(1,1).Range.Font.Name = $script:bodyFont; $t.Cell(1,1).Range.Font.Size=9
  $t.Cell(1,1).Range.Font.Color=0x55420F
  $script:sel.SetRange($t.Range.End,$t.Range.End); $script:sel.TypeParagraph()
}

# Cover
$sel.Style = -63; $sel.Font.Name=$bodyFont; $sel.Font.Size=27; $sel.Font.Bold=$true; $sel.Font.Color=0x102A43
$sel.TypeText('Secure Student Club Registration'); $sel.TypeParagraph()
$sel.Style = -75; $sel.Font.Name=$bodyFont; $sel.Font.Size=16; $sel.Font.Color=0x4774AA
$sel.TypeText('ELE201 Secure Coding Project Documentation'); $sel.TypeParagraph(); $sel.TypeParagraph()
Add-Para 'Individual Project and Security Implementation Report' 'Subtitle'
$sel.TypeParagraph(); $sel.TypeParagraph()
Add-Table @('Submission detail','Value') @(
  ,@('Student','Dawa'),
  ,@('Student ID','12240028'),
  ,@('Course','ELE201 Secure Coding'),
  ,@('Project','Secure Student Club Registration and Membership Management System'),
  ,@('Documentation date','12 November 2026'),
  ,@('Application address for local demo','http://127.0.0.1:3000')
)
Add-Para 'Purpose of this report' 'Heading 2'
Add-Para 'This report explains the application, the security controls implemented in the source code, and the evidence available so far. The interface and health endpoint have been started locally; the health check returned HTTP 200 in the developer-provided PowerShell output. The login workflow and full security test matrix still require verification on the submission computer. Screenshot slots below identify the exact evidence to capture; they are not presented as completed test results.'
$sel.InsertBreak(7)

# Contents and overview
Add-Heading 'A. Application Overview'
Add-Para 'The Secure Student Club Registration and Membership Management System replaces informal club sign-up with a web workflow. Students register, sign in, browse clubs, submit membership applications, and view pending, approved, or rejected decisions. Club administrators review applications, approve or reject pending requests, create and edit club listings, set member capacity, and view approved members.'
Add-Para 'The application has two roles. A student can read the public club list and can only view or submit their own membership applications. A club administrator can review applications and manage club records. Authorization is enforced on Express API routes, not only by hiding controls in the browser.'
Add-Para 'The frontend uses HTML, CSS, and browser JavaScript. The backend uses Node.js and Express. SQLite stores users, clubs, applications, and server-side sessions. bcryptjs hashes passwords. Node crypto provides AES-256-GCM encryption and keyed HMAC lookup. Zod validates inputs, Helmet configures security headers and CSP, express-rate-limit limits repeated sign-in attempts, and Winston writes structured security logs.'
Add-Heading 'Main Features',2
Add-Bullet 'Student account registration, login, logout, club browsing, membership applications, and status tracking.'
Add-Bullet 'Administrator application review, club creation and editing, capacity settings, and approved-member listing.'
Add-Bullet 'SQLite persistence, encrypted student identity fields, session expiry, CSRF protection, validation, output encoding, logging, and optional direct TLS support.'
Add-Para 'Scope note: profile editing, password reset, email verification, multi-administrator assignment to individual clubs, automated backups, and production deployment are not implemented in this version.'
Add-Heading 'System and Cyber Flow',2
Add-Para 'Browser → Helmet and Express middleware → session and CSRF checks → input schema validation → role authorization → parameterized SQLite operation → AES-GCM decryption only for an authorized administrator response → safe JSON response → HTML escaping in the browser. Security events are recorded by Winston. Registration hashes the password with bcrypt and encrypts student PII before saving it. Login verifies the bcrypt hash and regenerates the session identifier.'
Add-Heading 'Local Run Configuration',2
Add-Para 'Run `npm install` once, keep the project `.env` file private, and start the service with `npm start`. In development, open `http://127.0.0.1:3000` on the same computer. The health endpoint is `http://127.0.0.1:3000/api/health`. Local development uses HTTP; it must not be described as HTTPS.'
$sel.InsertBreak(7)

# B
Add-Heading 'B. Security Implementation Details'
Add-Heading '1. User Authentication and Authorization',2
Add-Para 'Passwords are hashed with bcryptjs using a cost factor of 12. Registration and login validate the email and password on the server. Login uses a generic error for unknown email or incorrect password and is rate-limited. Successful login and registration regenerate the session ID. The auth middleware requires a session, while the role middleware separately limits admin endpoints to the admin role. Students only query their own application records.'
Add-Para 'Code references: `server.js` password schema, registration route, `bcrypt.hash`, login route, `bcrypt.compare`, `auth` and `role` middleware, and `/api/admin/*` routes. No plaintext password is stored or logged.'
Add-Evidence 1 'Registration and sign-in interface' 'Capture the browser page with the sign-in form and the registration form. Include the browser URL and use only test data.'
Add-Evidence 2 'bcrypt password hashing and role checks' 'Capture the bcrypt hash/compare code and the server-side auth/role middleware. Include a student attempt to access an admin API returning 403.'
Add-Heading '2. Data Encryption and Protection',2
Add-Para 'The project encrypts names, emails, and student IDs with AES-256-GCM. Each value uses a random 12-byte IV and stores the authentication tag with ciphertext. The 32-byte key comes from `DATA_ENCRYPTION_KEY` and is kept in the ignored `.env` file. A keyed HMAC of normalized email is used as the lookup index. Passwords use bcrypt hashes. SQL statements bind values with placeholders.'
Add-Para 'Limitations: encryption protects selected identity values at rest, but SQLite files, backups, logs, and the host filesystem still require access controls. Key loss makes PII unrecoverable; key rotation needs a migration. The environment key must never appear in screenshots or be committed.'
Add-Evidence 3 'AES-GCM encryption and protected database fields' 'Capture the encrypt/decrypt code and a database row showing ciphertext and a bcrypt hash. Redact the encryption key and all real personal data.'
Add-Heading '3. Input Validation and Output Sanitization',2
Add-Para 'The server validates registration, login, application, membership decision, and club-management payloads with Zod schemas. Names, emails, IDs, messages, descriptions, categories, capacities, and decision statuses have type, length, and value rules. Express JSON request bodies are limited to 20 KB. SQLite queries use bound parameters. Browser code applies an HTML escaping function before inserting dynamic text. Helmet CSP restricts scripts and styles to the local origin and blocks object embedding.'
Add-Para 'Client-side HTML constraints improve usability, but the server schemas are the security boundary. No separate DOMPurify dependency is used; output is encoded at the point where text is inserted into HTML.'
Add-Evidence 4 'Validation, parameterized SQL, CSP, and output encoding' 'Capture representative Zod schemas, a prepared SQL statement, the HTML escaping helper, and a safe invalid-input response.'
Add-Heading '4. Session Management',2
Add-Para 'Sessions are stored in SQLite and have a 30-minute rolling maximum age. The session ID is regenerated after successful login and registration. Cookies set HttpOnly and SameSite=Strict. The Secure flag is enabled when direct TLS is configured or NODE_ENV is production. State-changing requests require a random session-bound CSRF token, and logout destroys the server-side session and clears the cookie.'
Add-Para 'Because this project is currently running locally over HTTP, the browser cookie is not Secure in the local development configuration. HTTPS behavior must be evidenced in an HTTPS deployment.'
Add-Evidence 5 'Session expiry, cookie flags, CSRF, and logout' 'Capture session and cookie configuration, the CSRF request header, and a logged-out request returning 401. Redact cookie values.'
Add-Heading '5. Error Handling and Logging',2
Add-Para 'Asynchronous routes pass errors to a central handler. Users receive a safe generic message rather than a stack trace or raw database error. Winston writes timestamped JSON records to `logs/security.log` and the console. Events include registration, login success/failure, logout, application submission/review, and club changes. The application avoids logging passwords, CSRF tokens, and session IDs.'
Add-Evidence 6 'Safe error handling and security audit log' 'Capture the error handler and Winston configuration, plus a sample log entry with personal information minimized.'
Add-Heading '6. Secure Communication',2
Add-Para 'The application supports direct HTTPS when TLS key and certificate file paths are configured. A production reverse proxy can terminate TLS; `TRUST_PROXY=1` is only appropriate behind a trusted proxy. The current local setup uses HTTP at `127.0.0.1:3000`, and the application does not enforce an HTTP-to-HTTPS redirect itself. Therefore HTTPS is not yet demonstrated in the current local run.'
Add-Evidence 7 'HTTPS connection and Secure cookie' 'Capture this only after configuring a valid local or hosted TLS certificate. Show the HTTPS browser address, certificate details, and Secure cookie attribute. Do not use the local HTTP page as HTTPS evidence.'
Add-Heading '7. Security Testing and Auditing',2
Add-Para 'Verification completed so far: Node syntax checks passed for `server.js` and `public/app.js`. The developer-provided PowerShell output shows `/api/health` returned HTTP 200 and `{"ok":true,"service":"secure-student-club-system"}`. The PowerShell parsing warning was generated by Invoke-WebRequest and was not an application failure. These checks confirm syntax and server health only; they do not prove login, authorization, XSS, SQL injection, CSRF, rate limiting, or HTTPS behavior.'
Add-Para 'No OWASP ZAP scan, penetration test, or full manual security test was run for this report. Complete the table in Section G with actual results. GDPR, FERPA, and HIPAA compliance is not claimed; the institution must determine applicable obligations, retention, access, and privacy practices.'
Add-Evidence 8 'Application health response' 'Insert a screenshot of the PowerShell health check with HTTP 200 and the JSON response. The output provided during preparation reports this check succeeded.' 'User-provided console result: HTTP 200; not an independent security test.'
Add-Evidence 9 'Security test results and fixes' 'Capture real manual or OWASP ZAP results for the checks in Section G. Include date, expected and actual result, finding, and fix.' 'Not yet completed; do not submit this slot as passing evidence.'
$sel.InsertBreak(7)

# C
Add-Heading 'C. Component Breakdown'
Add-Table @('Component','Purpose','Security controls','Code or evidence') @(
  ,@('Authentication','Register, sign in, sign out','bcrypt cost 12; generic login error; request limits; session ID rotation','server.js auth routes; Figures 1–2'),
  ,@('Authorization','Protect route and record access','Session authentication; student/admin RBAC; own-record query scope','server.js auth/role middleware; Figure 2'),
  ,@('Student workspace','Browse clubs and manage applications','Authenticated actions; student-scoped queries; safe output','public/app.js; browser evidence'),
  ,@('Club management','Create and edit clubs, set capacity','Admin-only API; Zod schema; bound SQL; audit events','server.js admin club routes'),
  ,@('Membership workflow','Submit and decide applications','Unique student/club pair; pending-only review; capacity check; reviewer and timestamp','server.js application routes; Figure 2'),
  ,@('Data protection','Persist identity and membership data','AES-256-GCM for identity fields; keyed HMAC lookup; bcrypt passwords','server.js crypto helpers; Figure 3'),
  ,@('Validation and output','Constrain requests and render data safely','Zod; size limits; parameterized SQL; HTML escaping; CSP','server.js and public/app.js; Figure 4'),
  ,@('Sessions and CSRF','Maintain safe browser authentication','SQLite session store; 30-minute rolling timeout; cookie flags; CSRF token; invalidating logout','server.js session middleware; Figure 5'),
  ,@('Errors and audit log','Handle errors and record security events','Generic user errors; Winston JSON; sensitive tokens excluded','server.js error middleware and logger; Figure 6'),
  ,@('Transport and verification','Protect network traffic and verify controls','TLS support; health endpoint; testing checklist; local HTTP disclosed','server.js TLS startup; Figures 7–9')
)
$sel.InsertBreak(7)

# D/E/F
Add-Heading 'D. Challenges and Solutions'
Add-Table @('Challenge encountered','How it was identified','Solution or current status') @(
  ,@('The server refused to start because SESSION_SECRET and DATA_ENCRYPTION_KEY were still placeholders.','Node printed explicit configuration validation errors.','A fresh session secret and encryption key were configured in the project .env file. The values remain private.'),
  ,@('TLS_KEY_PATH contained a value that was not a certificate file path.','The app would try to read the TLS files if both paths were set.','Invalid TLS paths were cleared for local HTTP. TLS must be configured separately for HTTPS.'),
  ,@('The sign-in page was not opening even though the service had started.','The health endpoint returned HTTP 200, but that checks only server reachability.','The browser issue is not yet confirmed resolved. Open the app in a normal browser on the same computer at http://127.0.0.1:3000, then inspect browser developer tools if needed.'),
  ,@('PowerShell displayed a script parsing warning during the health request.','Invoke-WebRequest showed a warning before returning 200 OK.','The warning is PowerShell behavior and not an application error. Use -UseBasicParsing for the check.')
)
Add-Heading 'E. Security Summary',1
Add-Para 'Confidentiality: bcrypt protects stored passwords, AES-GCM encrypts selected identity fields, keyed HMAC supports account lookup, and role checks restrict student and administrator data. HTTPS remains a deployment requirement and is not active in the local HTTP run.'
Add-Para 'Integrity: server-side schemas, parameterized queries, CSRF validation, role authorization, a unique student/club application constraint, pending-only decisions, capacity checks, and audit records help prevent unauthorized changes.'
Add-Para 'Availability: bounded request sizes, login rate limits, persistent SQLite records, and safe error handling support reliable operation. Backups, monitoring, multi-instance storage, and recovery plans are not configured in this teaching prototype.'
Add-Heading 'F. Repository and Submission Link',1
Add-Para 'Submission platform: VLE Moodle, according to the assignment brief. GitLab repository URL or Google Drive ZIP link: not supplied. Add the actual URL before submission and verify that the instructor can open it. Do not invent a repository or Drive link.'
Add-Para 'Required filenames: ELE201_Dawa_12240028.zip and ELE201_Dawa_12240028.pdf. The source project folder should be zipped without `.env`, database contents, session data, or logs. Use a separate secure process for any required live demonstration credentials.'
$sel.InsertBreak(7)

# G
Add-Heading 'G. Security Verification Checklist'
Add-Para 'Record actual outcomes before submission. The health endpoint result is the only runtime check evidenced in the materials provided for this report. Mark each other item after testing it on your computer.'
Add-Table @('Check','Expected result','Recorded result') @(
  ,@('Health endpoint','HTTP 200 and ok=true','Confirmed from supplied PowerShell output.'),
  ,@('Student calls administrator API','403 Forbidden','Not run'),
  ,@('Signed-out user requests applications','401 Unauthorized','Not run'),
  ,@('Weak password or malformed registration input','400 safe validation error','Not run'),
  ,@('Duplicate application for same club','409 conflict and no duplicate row','Not run'),
  ,@('SQL injection-style string','Treated as data; no query alteration','Not run'),
  ,@('XSS-style text','Displayed as encoded text; no script executes','Not run'),
  ,@('Missing/wrong CSRF token','403 Forbidden','Not run'),
  ,@('Logout then reuse session','401 Unauthorized','Not run'),
  ,@('Repeated failed login','Rate limit response after configured threshold','Not run'),
  ,@('HTTPS deployment','Valid HTTPS; Secure cookie; no mixed content','Not configured; local run uses HTTP'),
  ,@('Code syntax checks','No JavaScript parse errors','Passed for server.js and public/app.js')
)
Add-Heading 'Evidence Capture Plan',2
Add-Para 'For each numbered figure, capture the actual screen with a test account. Include the browser address bar or relevant code context, add a visible annotation, and redact secrets and personal information. The report identifies required evidence but does not fabricate screenshots or test outcomes.'
Add-Table @('Figure','Caption to use','Capture') @(
  ,@('1','Secure student registration and login pages','Browser sign-in and registration forms.'),
  ,@('2','Server-side RBAC and membership review','Admin page plus a student 403 response.'),
  ,@('3','AES-GCM encryption of student data at rest','Crypto code and ciphertext in database; key redacted.'),
  ,@('4','Server validation, SQL parameterization, and safe output','Zod, prepared SQL, escaping helper, and a safe rejection.'),
  ,@('5','Session expiry, cookie attributes, CSRF, and logout','Cookie flags on HTTPS and a logged-out 401.'),
  ,@('6','Safe error response and structured Winston log','Browser error and minimized log event.'),
  ,@('7','HTTPS transport and secure cookie','Only after TLS is actually configured.'),
  ,@('8','Application health endpoint','PowerShell output showing HTTP 200 and ok=true.'),
  ,@('9','Security audit results and remediation','Actual OWASP ZAP or manual checks with date and fixes.')
)
Add-Heading 'Viva Preparation',2
Add-Para 'Why bcrypt? It is a password-hashing algorithm designed to make guessing expensive; the application stores its hash, not the submitted password. Why AES-GCM? It encrypts selected personal fields and authenticates ciphertext so tampering is detectable. Why keep authorization on the server? Browser controls can be bypassed; every restricted API must check the session role. What does CSRF protection do? It requires a session-bound unpredictable token on state-changing requests. Is the local app using HTTPS? No. Local development uses HTTP; TLS requires certificate configuration or a trusted HTTPS reverse proxy. What security testing has been completed? Only syntax checks and the reported HTTP 200 health check; the security matrix must still be run.'

# Footer and export
foreach ($section in $doc.Sections) {
  $footer = $section.Footers.Item(1).Range
  $footer.Text = 'ELE201 Secure Coding  |  Dawa  |  Student ID 12240028    •    Page '
  $footer.Font.Name = $bodyFont; $footer.Font.Size = 8; $footer.Font.Color = 0x6B7C93
  $null = $footer.Fields.Add($footer, 33)
}
$doc.SaveAs2($outDoc,16)
$doc.ExportAsFixedFormat($outPdf,17)
$pages = $doc.ComputeStatistics(2)
$doc.Close(0); $word.Quit()
[Runtime.InteropServices.Marshal]::ReleaseComObject($sel) | Out-Null
[Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
[Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
"Created $outDoc"
"Created $outPdf"
"Pages: $pages"
