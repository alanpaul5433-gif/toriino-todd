'use client';

export interface AdminUser {
  sub: string;
  email: string;
  name: string;
  groups: string[];
}

export function getAdminUser(): AdminUser | null {
  if (typeof window === 'undefined') return null;
  const raw = localStorage.getItem('admin_user');
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export function setAdminSession(token: string, user: AdminUser) {
  localStorage.setItem('admin_token', token);
  localStorage.setItem('admin_user', JSON.stringify(user));
}

export function clearAdminSession() {
  localStorage.removeItem('admin_token');
  localStorage.removeItem('admin_user');
}

export function isLoggedIn(): boolean {
  return !!getAdminUser() && !!localStorage.getItem('admin_token');
}

// Parse Cognito JWT to extract user info (client-side only, not for auth verification)
export function parseJwt(token: string): Record<string, unknown> {
  try {
    const base64 = token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
    return JSON.parse(atob(base64));
  } catch {
    return {};
  }
}

// Login via Cognito USER_PASSWORD_AUTH flow
export async function loginWithCognito(email: string, password: string): Promise<void> {
  const clientId = process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID;
  const region = process.env.NEXT_PUBLIC_COGNITO_REGION || 'us-east-1';

  const endpoint = `https://cognito-idp.${region}.amazonaws.com/`;
  const r = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-amz-json-1.1',
      'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
    },
    body: JSON.stringify({
      AuthFlow: 'USER_PASSWORD_AUTH',
      ClientId: clientId,
      AuthParameters: { USERNAME: email, PASSWORD: password },
    }),
  });

  if (!r.ok) {
    const err = await r.json();
    throw new Error(err.message || err.__type || 'Login failed');
  }

  const data = await r.json();
  const idToken = data.AuthenticationResult?.IdToken;
  if (!idToken) throw new Error('No token received');

  const payload = parseJwt(idToken);
  const groups = (payload['cognito:groups'] as string[]) || [];

  if (!groups.includes('Admins')) {
    throw new Error('Access denied: admin privileges required');
  }

  setAdminSession(idToken, {
    sub: payload.sub as string,
    email: payload.email as string,
    name: (payload.name as string) || (payload.email as string),
    groups,
  });
}
