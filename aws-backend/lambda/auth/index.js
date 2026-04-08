const {
  CognitoIdentityProviderClient,
  SignUpCommand,
  InitiateAuthCommand,
  ConfirmSignUpCommand,
  ForgotPasswordCommand,
  ConfirmForgotPasswordCommand,
  GlobalSignOutCommand,
  AdminUpdateUserAttributesCommand,
} = require("@aws-sdk/client-cognito-identity-provider");

const REGION = process.env.AWS_REGION || "us-east-2";
const USER_POOL_ID = process.env.COGNITO_USER_POOL_ID;
const CLIENT_ID = process.env.COGNITO_CLIENT_ID;

const cognito = new CognitoIdentityProviderClient({ region: REGION });

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
};

function response(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

exports.handler = async (event) => {
  const path = event.path;
  const method = event.httpMethod;
  const body = event.body ? JSON.parse(event.body) : {};

  if (method === "OPTIONS") {
    return response(200, {});
  }

  try {
    switch (path) {
      case "/auth/register":
        return await register(body);
      case "/auth/login":
        return await login(body);
      case "/auth/verify":
        return await verifyEmail(body);
      case "/auth/refresh":
        return await refreshToken(body);
      case "/auth/forgot-password":
        return await forgotPassword(body);
      case "/auth/reset-password":
        return await resetPassword(body);
      case "/auth/set-role":
        return await setRole(body, event);
      case "/auth/logout":
        return await logout(event);
      default:
        return response(404, { error: "Route not found" });
    }
  } catch (error) {
    console.error("Auth error:", error);
    return response(error.$metadata?.httpStatusCode || 500, {
      error: error.message || "Internal server error",
    });
  }
};

// ── Register ───────────────────────────────────────────────
async function register({ email, password, name, phone }) {
  if (!email || !password || !name) {
    return response(400, { error: "email, password, and name are required" });
  }

  const userAttributes = [
    { Name: "email", Value: email },
    { Name: "name", Value: name },
  ];
  if (phone) {
    userAttributes.push({ Name: "phone_number", Value: phone });
  }

  const result = await cognito.send(
    new SignUpCommand({
      ClientId: CLIENT_ID,
      Username: email,
      Password: password,
      UserAttributes: userAttributes,
    })
  );

  return response(201, {
    message: "User registered. Please verify your email.",
    userId: result.UserSub,
    codeDeliveryDetails: result.CodeDeliveryDetails,
  });
}

// ── Verify Email ───────────────────────────────────────────
async function verifyEmail({ email, code }) {
  if (!email || !code) {
    return response(400, { error: "email and code are required" });
  }

  await cognito.send(
    new ConfirmSignUpCommand({
      ClientId: CLIENT_ID,
      Username: email,
      ConfirmationCode: code,
    })
  );

  return response(200, { message: "Email verified successfully" });
}

// ── Login ──────────────────────────────────────────────────
async function login({ email, password }) {
  if (!email || !password) {
    return response(400, { error: "email and password are required" });
  }

  const result = await cognito.send(
    new InitiateAuthCommand({
      AuthFlow: "USER_PASSWORD_AUTH",
      ClientId: CLIENT_ID,
      AuthParameters: {
        USERNAME: email,
        PASSWORD: password,
      },
    })
  );

  const auth = result.AuthenticationResult;
  return response(200, {
    accessToken: auth.AccessToken,
    idToken: auth.IdToken,
    refreshToken: auth.RefreshToken,
    expiresIn: auth.ExpiresIn,
    tokenType: auth.TokenType,
  });
}

// ── Refresh Token ──────────────────────────────────────────
async function refreshToken({ refreshToken: token }) {
  if (!token) {
    return response(400, { error: "refreshToken is required" });
  }

  const result = await cognito.send(
    new InitiateAuthCommand({
      AuthFlow: "REFRESH_TOKEN_AUTH",
      ClientId: CLIENT_ID,
      AuthParameters: {
        REFRESH_TOKEN: token,
      },
    })
  );

  const auth = result.AuthenticationResult;
  return response(200, {
    accessToken: auth.AccessToken,
    idToken: auth.IdToken,
    expiresIn: auth.ExpiresIn,
  });
}

// ── Forgot Password ────────────────────────────────────────
async function forgotPassword({ email }) {
  if (!email) {
    return response(400, { error: "email is required" });
  }

  const result = await cognito.send(
    new ForgotPasswordCommand({
      ClientId: CLIENT_ID,
      Username: email,
    })
  );

  return response(200, {
    message: "Password reset code sent",
    codeDeliveryDetails: result.CodeDeliveryDetails,
  });
}

// ── Reset Password ─────────────────────────────────────────
async function resetPassword({ email, code, newPassword }) {
  if (!email || !code || !newPassword) {
    return response(400, {
      error: "email, code, and newPassword are required",
    });
  }

  await cognito.send(
    new ConfirmForgotPasswordCommand({
      ClientId: CLIENT_ID,
      Username: email,
      ConfirmationCode: code,
      Password: newPassword,
    })
  );

  return response(200, { message: "Password reset successfully" });
}

// ── Set Role ───────────────────────────────────────────────
async function setRole({ role }, event) {
  if (!role || !["Student", "Teacher", "Mentor"].includes(role)) {
    return response(400, {
      error: "role must be Student, Teacher, or Mentor",
    });
  }

  // Extract username from Cognito authorizer
  const username =
    event.requestContext?.authorizer?.claims?.["cognito:username"];
  if (!username) {
    return response(401, { error: "Unauthorized" });
  }

  await cognito.send(
    new AdminUpdateUserAttributesCommand({
      UserPoolId: USER_POOL_ID,
      Username: username,
      UserAttributes: [{ Name: "custom:role", Value: role }],
    })
  );

  return response(200, { message: "Role set successfully", role });
}

// ── Logout ─────────────────────────────────────────────────
async function logout(event) {
  const accessToken = event.headers?.Authorization?.replace("Bearer ", "");
  if (!accessToken) {
    return response(401, { error: "No access token provided" });
  }

  await cognito.send(
    new GlobalSignOutCommand({ AccessToken: accessToken })
  );

  return response(200, { message: "Logged out successfully" });
}
