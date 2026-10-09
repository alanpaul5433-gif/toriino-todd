/**
 * auth.test.js — POST /auth/set-role: once only, student/teacher/mentor, never admin.
 * Run from aws-backend/:  npx jest tests/auth.test.js
 */
'use strict';

const mockCognito = jest.fn();
const mockDdb = jest.fn();

jest.mock('@aws-sdk/client-cognito-identity-provider', () => {
  const cmd = (type) => jest.fn().mockImplementation((input) => ({ input, _type: type }));
  return {
    CognitoIdentityProviderClient: jest.fn().mockImplementation(() => ({ send: mockCognito })),
    AdminGetUserCommand: cmd('AdminGetUser'),
    AdminUpdateUserAttributesCommand: cmd('AdminUpdateUserAttributes'),
    GlobalSignOutCommand: cmd('GlobalSignOut'),
  };
});
jest.mock('@aws-sdk/client-dynamodb', () => ({ DynamoDBClient: jest.fn().mockImplementation(() => ({})) }));
jest.mock('@aws-sdk/lib-dynamodb', () => ({
  DynamoDBDocumentClient: { from: jest.fn().mockReturnValue({ send: mockDdb }) },
  UpdateCommand: jest.fn().mockImplementation((input) => ({ input, _type: 'Update' })),
}));

Object.assign(process.env, { COGNITO_USER_POOL_ID: 'us-east-1_test', USERS_TABLE: 'torino-users' });
const { handler } = require('../lambda/auth/index');

const setRole = (role) => handler({
  httpMethod: 'POST', path: '/auth/set-role', body: JSON.stringify({ role }),
  requestContext: { authorizer: { claims: { sub: 'u-1', 'cognito:username': 'u-1', email: 'a@b.test' } } },
});
const withCurrentRole = (value) => mockCognito.mockImplementation(async (c) => (c._type === 'AdminGetUser'
  ? { UserAttributes: value ? [{ Name: 'custom:role', Value: value }] : [] }
  : {}));
const wrote = () => mockCognito.mock.calls.some(([c]) => c._type === 'AdminUpdateUserAttributes');

beforeEach(() => { mockCognito.mockReset(); mockDdb.mockReset(); mockDdb.mockResolvedValue({}); });

test.each(['student', 'Teacher', 'mentor'])('sets %s when the user has no role yet', async (role) => {
  withCurrentRole(null);
  const r = await setRole(role);
  expect(r.statusCode).toBe(200);
  expect(JSON.parse(r.body).role).toBe(role.toLowerCase());
  expect(wrote()).toBe(true);
  expect(mockDdb).toHaveBeenCalledTimes(1);
});

test('rejects a second role change (409) and writes nothing', async () => {
  withCurrentRole('student');
  const r = await setRole('teacher');
  expect(r.statusCode).toBe(409);
  expect(wrote()).toBe(false);
  expect(mockDdb).not.toHaveBeenCalled();
});

test('rejects admin (403) without looking the user up', async () => {
  withCurrentRole(null);
  const r = await setRole('admin');
  expect(r.statusCode).toBe(403);
  expect(mockCognito).not.toHaveBeenCalled();
});

test('rejects unknown roles (400)', async () => {
  withCurrentRole(null);
  for (const role of ['superuser', 'Admins', '']) {
    expect((await setRole(role)).statusCode).toBe(400);
  }
  expect(mockCognito).not.toHaveBeenCalled();
});

test('an admin cannot change their role (403)', async () => {
  withCurrentRole('admin');
  const r = await setRole('student');
  expect(r.statusCode).toBe(403);
  expect(wrote()).toBe(false);
});
