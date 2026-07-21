import sgMail from '@sendgrid/mail';
import config from '../config/env.js';

sgMail.setApiKey(config.sendgridApiKey);

const COLORS = {
    coral: '#F0653F',
    coralLight: '#F98E6E',
    appBg: '#fff3ec',
    panel: '#fff8f3',
    card: '#ffffff',
    text: '#4a352d',
    secondary: '#a56a58',
    muted: '#b98a7a',
    border: '#f2e5db',
};

const HEADING_STACK =
    "'Fredoka', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif";
const BODY_STACK =
    "'Hanken Grotesk', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif";

function escapeHtml(value: string): string {
    return value
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

interface EmailContent {
    preheader: string;
    greeting: string;
    heading: string;
    bodyParagraphs: string[];
    ctaLabel: string;
    ctaUrl: string;
    footerReason: string;
}

export function renderEmail(content: EmailContent): string {
    const { preheader, greeting, heading, bodyParagraphs, ctaLabel, ctaUrl, footerReason } =
        content;

    const paragraphs = bodyParagraphs
        .map(
            (p) =>
                `<p style="margin:0 0 16px;font-family:${BODY_STACK};font-size:16px;line-height:1.6;color:${COLORS.text};">${p}</p>`,
        )
        .join('');

    const safeUrl = escapeHtml(ctaUrl);

    return `<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="x-apple-disable-message-reformatting">
<meta name="color-scheme" content="light">
<meta name="supported-color-schemes" content="light">
<title>${escapeHtml(heading)}</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Fredoka:wght@500;600;700&family=Hanken+Grotesk:wght@400;500;600&display=swap');
body { margin:0; padding:0; width:100%; background-color:${COLORS.appBg}; }
a { text-decoration:none; }
</style>
</head>
<body style="margin:0;padding:0;background-color:${COLORS.appBg};">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;mso-hide:all;font-size:1px;line-height:1px;color:${COLORS.appBg};">${escapeHtml(preheader)}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:${COLORS.appBg};">
<tr>
<td align="center" style="padding:32px 16px;">
<table role="presentation" width="560" cellpadding="0" cellspacing="0" border="0" style="width:560px;max-width:560px;background-color:${COLORS.card};border-radius:22px;overflow:hidden;border:1px solid ${COLORS.border};">
<tr>
<td style="background:linear-gradient(135deg, ${COLORS.coralLight} 0%, ${COLORS.coral} 100%);background-color:${COLORS.coral};padding:36px 40px;text-align:center;">
<span style="font-family:${HEADING_STACK};font-size:30px;font-weight:700;letter-spacing:0.5px;color:#ffffff;">crumb</span>
<div style="font-family:${BODY_STACK};font-size:13px;font-weight:500;color:#ffffff;opacity:0.9;margin-top:4px;">Free food, before it&#39;s gone.</div>
</td>
</tr>
<tr>
<td style="padding:40px;">
<p style="margin:0 0 8px;font-family:${BODY_STACK};font-size:16px;font-weight:500;color:${COLORS.secondary};">${escapeHtml(greeting)}</p>
<h1 style="margin:0 0 20px;font-family:${HEADING_STACK};font-size:26px;font-weight:600;line-height:1.25;color:${COLORS.text};">${escapeHtml(heading)}</h1>
${paragraphs}
<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:28px 0 24px;">
<tr>
<td align="center" bgcolor="${COLORS.coral}" style="background-color:${COLORS.coral};border-radius:14px;">
<a href="${safeUrl}" target="_blank" style="display:inline-block;padding:15px 34px;font-family:${HEADING_STACK};font-size:16px;font-weight:600;color:#ffffff;background-color:${COLORS.coral};border-radius:14px;">${escapeHtml(ctaLabel)}</a>
</td>
</tr>
</table>
<p style="margin:0 0 6px;font-family:${BODY_STACK};font-size:13px;color:${COLORS.secondary};">Button not working? Paste this link into your browser:</p>
<p style="margin:0;font-family:${BODY_STACK};font-size:12px;line-height:1.5;color:${COLORS.muted};word-break:break-all;">${safeUrl}</p>
<div style="height:1px;background-color:${COLORS.border};margin:32px 0 24px;line-height:1px;font-size:1px;">&nbsp;</div>
<p style="margin:0 0 6px;font-family:${BODY_STACK};font-size:13px;font-weight:500;color:${COLORS.secondary};">Built for UCF &middot; Free food, before it&#39;s gone.</p>
<p style="margin:0;font-family:${BODY_STACK};font-size:12px;line-height:1.5;color:${COLORS.muted};">${escapeHtml(footerReason)}</p>
</td>
</tr>
</table>
</td>
</tr>
</table>
</body>
</html>`;
}

export async function sendVerificationEmail(
    to: string,
    rawToken: string,
    displayName?: string,
): Promise<void> {
    const link = `${config.appUrl}/api/auth/verify?token=${rawToken}`;
    const greeting = displayName ? `Hey ${displayName},` : 'Hey there,';

    const html = renderEmail({
        preheader: 'Confirm your @ucf.edu to start finding free food on campus.',
        greeting,
        heading: 'Verify your @ucf.edu',
        bodyParagraphs: [
            'Welcome to Crumb! Confirm your UCF email to keep the map students-only and see what&#39;s fresh near you.',
            'This link expires in 24 hours.',
        ],
        ctaLabel: 'Verify my email',
        ctaUrl: link,
        footerReason:
            "You got this email because someone signed up for Crumb with this address. If that wasn't you, you can safely ignore it.",
    });

    const text = [
        greeting,
        '',
        'Welcome to Crumb! Confirm your UCF email to keep the map students-only.',
        '',
        `Verify your email: ${link}`,
        '',
        'This link expires in 24 hours.',
        '',
        'Built for UCF - Free food, before it\'s gone.',
    ].join('\n');

    await sgMail.send({
        to,
        from: config.sendgridFromEmail,
        subject: 'Verify your @ucf.edu for Crumb',
        text,
        html,
    });
}

export async function sendPasswordResetEmail(
    to: string,
    rawToken: string,
    displayName?: string,
): Promise<void> {
    const link = `${config.appUrl}/reset-password?token=${rawToken}`;
    const greeting = displayName ? `Hey ${displayName},` : 'Hey there,';

    const html = renderEmail({
        preheader: 'Reset your Crumb password with the link inside.',
        greeting,
        heading: 'Reset your password',
        bodyParagraphs: [
            'We got a request to reset your Crumb password. Tap the button below to set a new one.',
            'This link expires in 1 hour. If this wasn&#39;t you, you can safely ignore this email and your password will stay the same.',
        ],
        ctaLabel: 'Set a new password',
        ctaUrl: link,
        footerReason: 'You got this email because a password reset was requested for this address.',
    });

    const text = [
        greeting,
        '',
        'We got a request to reset your Crumb password.',
        '',
        `Set a new password: ${link}`,
        '',
        'This link expires in 1 hour. If this wasn\'t you, you can safely ignore this email.',
        '',
        'Built for UCF - Free food, before it\'s gone.',
    ].join('\n');

    await sgMail.send({
        to,
        from: config.sendgridFromEmail,
        subject: 'Reset your Crumb password',
        text,
        html,
    });
}
