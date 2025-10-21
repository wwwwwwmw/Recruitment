import sgMail from '@sendgrid/mail';

export function initEmail() {
  const key = process.env.SENDGRID_API_KEY;
  if (key) {
    sgMail.setApiKey(key);
  }
}

export async function sendEmail({ to, subject, html, text }) {
  const from = process.env.EMAIL_FROM || 'no-reply@example.com';
  const key = process.env.SENDGRID_API_KEY;
  if (!key) {
    console.warn('SENDGRID_API_KEY not set; email not sent.');
    return { skipped: true };
  }
  await sgMail.send({ to, from, subject, html, text });
  return { sent: true };
}
