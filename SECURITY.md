# ELE201 Security Documentation and Verification Guide

Use this as the technical documentation source for the assignment PDF. Replace the screenshot placeholders with your own annotated screenshots from the running app and source code. Record real verification outcomes; this file deliberately does not claim tests that have not been performed.

## A. Application overview

The Secure Student Club Registration and Membership Management System provides a student club directory and membership workflow. Students create accounts, browse clubs, submit membership applications, and see their status. Club administrators review and decide applications, manage club descriptions and capacity, and view approved members.

**Roles:** Student (own application and club browsing) and Club Administrator (application review and club/member administration).

**Technology:** Node.js, Express, SQLite, bcryptjs, express-session with SQLite store, AES-256-GCM from Node's crypto library, Zod, Helmet CSP, express-rate-limit, and Winston. The UI is HTML, CSS, and browser JavaScript.

## B. Security implementation details

### 1. Authentication and authorization

Student passwords are hashed with bcrypt at cost 12; plaintext passwords are neither stored nor logged. Login uses a generic invalid-credentials response and a rate limiter. Successful login regenerates the session identifier to reduce session fixation risk. Role checks run in Express middleware for every restricted endpoint. Students only read their own applications; administrator routes require the `admin` role.

**Evidence to capture:** registration form; login form; bcrypt hash call in `server.js`; `auth` and `role` middleware plus a restricted route; unauthorized student request returning 403; administrator dashboard.

### 2. Data encryption and protection

Name, email, and student ID are encrypted with AES-256-GCM using a fresh random IV and authentication tag per value. The 256-bit key is read from `DATA_ENCRYPTION_KEY`; it is not stored in the database. A keyed HMAC of the normalized email is used to find accounts without a plaintext email index. Password hashes use bcrypt. Database operations bind user-controlled values rather than interpolating SQL.

**Evidence to capture:** encryption/decryption functions; environment variable configuration with secret value obscured; a database view showing encrypted fields and password hashes; authorized admin view of decrypted record.

### 3. Input validation and output sanitization

Zod schemas enforce types, maximum lengths, allowed statuses, email format, password rules, and numeric ranges on the server. SQL uses placeholders. Browser output passes through `esc()` to encode HTML-significant characters; Helmet supplies a Content Security Policy without inline scripts. JSON request bodies are size-limited.

**Evidence to capture:** schema definitions; a rejected invalid form with a safe message; parameterized SQL; escaping helper; response showing text such as `<script>` is rendered as text if you include a safe test string in an allowed field.

### 4. Session management

Session records are stored in SQLite, use a 30-minute rolling maximum age, and are regenerated at login and registration. Cookies are `HttpOnly`, `SameSite=Strict`, and set `Secure` when production mode or direct TLS is enabled. CSRF tokens are generated server-side and required for state-changing requests. Logout destroys the server session and clears its cookie.

**Evidence to capture:** browser cookie attributes while using HTTPS; session store and cookie configuration; CSRF token request and state-changing request header; logout followed by an authenticated API request returning 401.

### 5. Error handling and logging

A central error handler returns a generic message and logs a structured event without exposing stack traces or database internals. Winston writes JSON security events to `logs/security.log` and the console. Events include registration, successful/failed login, logout, application submission/review, and club changes. Passwords, CSRF tokens, and session identifiers are not logged.

**Evidence to capture:** error handler; log configuration; a sample log entry with personal values minimized; safe error message in the browser.

### 6. Secure communication

The app can serve HTTPS directly when TLS key and certificate paths are configured. Production can instead terminate TLS at a trusted reverse proxy. The local default is HTTP and is only suitable for local development. In deployment, redirect HTTP to HTTPS, configure trusted proxy handling narrowly, use a trusted certificate, and verify cookies carry the Secure attribute.

**Evidence to capture:** HTTPS browser address and certificate details; TLS configuration; `Secure` cookie attribute. Do not use a screenshot from local HTTP as HTTPS evidence.

### 7. Security testing and auditing

Perform and document these checks in your own environment. Include tool/version, date, expected result, actual result, and a screenshot or response capture. OWASP ZAP passive scan is appropriate for the local test instance; avoid running intrusive scans against systems you do not own or have permission to test.

| Check | Expected result | Your result / evidence |
| --- | --- | --- |
| Student calls admin application endpoint | HTTP 403 | Fill after running |
| Signed-out user calls application endpoint | HTTP 401 | Fill after running |
| Invalid email / weak password registration | HTTP 400 with safe field error | Fill after running |
| Duplicate club application | HTTP 409; no duplicate row | Fill after running |
| SQLi-style input in a text field | Stored/treated as data; no query alteration | Fill after running |
| XSS-like text in a club/message field | Encoded as text; no script execution | Fill after running |
| Missing or wrong CSRF token on a state-changing request | HTTP 403 | Fill after running |
| Expired or logged-out session | HTTP 401; session cookie no longer authorizes | Fill after running |
| Repeated failed login | Rate limited after configured threshold | Fill after running |
| Production HTTPS deployment | HTTPS connection; Secure cookie; no mixed-content requests | Fill after running |

Do not submit expected outcomes as if they were measured results. Note any issue found and the code change that fixed it. Consider GDPR, FERPA, and institutional policy with the school; this application does not claim legal or regulatory compliance.

## C. Component breakdown

| Component | Purpose | Security features | Code or screenshot reference |
| --- | --- | --- | --- |
| Authentication | Register, sign in, sign out | bcrypt, rate limits, session ID rotation | `server.js`; Figure 1 |
| Authorization | Restrict endpoint access by role | Server-side role middleware, own-record scoping | `server.js`; Figure 2 |
| Student workspace | Browse clubs, apply, track status | Authenticated routes and scoped queries | `public/app.js`; Figure 3 |
| Club management | Create/edit club data | Admin-only endpoints and schema validation | `server.js`; Figure 4 |
| Membership module | Submit, review, decide requests | Duplicate constraint; pending-only decisions; audit events | `server.js`; Figure 5 |
| Data protection | Store account PII | AES-GCM at rest, keyed email lookup, env key | `server.js`; Figure 6 |
| Validation/output | Reject malformed data and encode UI output | Zod, parameter binding, HTML escaping, CSP | `server.js`, `public/app.js`; Figure 7 |
| Session and CSRF | Maintain a browser session safely | SQLite store, expiry, cookie flags, CSRF token | `server.js`; Figure 8 |
| Errors and logs | Safe failures and audit records | Generic user errors, Winston structured logs | `server.js`; Figure 9 |
| Transport | Encrypt network traffic | TLS support; reverse-proxy deployment guidance | `.env.example`, `server.js`; Figure 10 |
| Security audit | Verify controls and record findings | Checklist in this document; actual scan evidence to be added | Figure 11 |

## D. Challenges and solutions (complete from your actual development)

Use a short table in the final report. Suggested subjects from the assignment are below; describe the real issue you encountered and how you diagnosed it rather than claiming an issue that did not occur.

| Challenge | How identified | Resolution | Evidence |
| --- | --- | --- | --- |
| Example: student PII needed account lookup and confidentiality | Review of database fields and account lookup design | AES-GCM for values and HMAC email index | Add your actual details |
| Example: students must not make admin decisions | Attempted direct API request under student session | Enforced server-side role middleware | Add your actual details |
| Example: local HTTP does not prove TLS | Browser connection and cookie inspection | Configured test TLS or documented trusted TLS proxy setup | Add your actual details |

## E. Security summary: CIA

- **Confidentiality:** RBAC scopes records; passwords are bcrypt hashes; sensitive student fields are encrypted at rest; HTTPS is required for production transport.
- **Integrity:** Server validation, parameterized SQL, CSRF checks, role authorization, uniqueness constraints, pending-only review, and audit logs protect records and decisions.
- **Availability:** Safe error handling, rate limits, persistent SQLite storage, and clear service logs support reliable operation. Backups and production monitoring still need to be configured for deployment.

## F. Repository or Drive link

Add the GitLab repository URL or the Google Drive ZIP link here. Set the Drive link permission to “Anyone with the link can view.”

## Screenshot captions to use

1. **Figure 1: Secure student registration and bcrypt password hashing.** Show the registration UI and relevant hashing code; redact credentials.
2. **Figure 2: Server-side role-based access control.** Show student/admin route guards and an unauthorized request result.
3. **Figure 3: Student club discovery and application status.** Show club list and one status view using sample data.
4. **Figure 4: Administrator club management.** Show create/edit controls and role-protected endpoint.
5. **Figure 5: Application approval workflow.** Show pending request and resulting decision log/status.
6. **Figure 6: AES-GCM protected data at rest.** Show ciphertext and obscured key configuration, never reveal the key.
7. **Figure 7: Server validation, SQL parameterization, CSP, and output encoding.** Annotate the relevant code.
8. **Figure 8: Session expiry, cookie flags, CSRF token, and logout.** Capture cookie flags on HTTPS.
9. **Figure 9: Safe error response and structured security log.** Use non-sensitive sample data.
10. **Figure 10: HTTPS connection and secure cookie.** Capture only a correctly configured HTTPS environment.
11. **Figure 11: Security verification results.** Include real manual checks and/or OWASP ZAP findings with date and remediation notes.

## Submission filenames

- ZIP: `ELE201_[YourFullName]_[StudentID].zip`
- PDF: `ELE201_[YourFullName]_[StudentID].pdf`
