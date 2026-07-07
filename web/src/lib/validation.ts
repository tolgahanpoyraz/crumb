// The browser's type="email" is lenient (accepts "me@ucf" with no TLD); the API's
// validator is stricter and 400s on those. Match the stricter rule client-side so
// we catch it before submitting.
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function isValidEmail(email: string): boolean {
  return EMAIL_RE.test(email.trim());
}
