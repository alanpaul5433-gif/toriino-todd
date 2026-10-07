/**
 * Seeds DynamoDB with demo data and creates demo Cognito accounts.
 *
 * Usage: node infrastructure/seed-demo-data.js
 *
 * Demo accounts created:
 *   Student : demo.student@toriino.com  / Demo@1234
 *   Mentor  : demo.mentor@toriino.com   / Demo@1234
 */

const { DynamoDBClient, PutItemCommand, CreateTableCommand, DescribeTableCommand } = require("@aws-sdk/client-dynamodb");
const { marshall } = require("@aws-sdk/util-dynamodb");
const {
  CognitoIdentityProviderClient,
  AdminCreateUserCommand,
  AdminSetUserPasswordCommand,
  AdminAddUserToGroupCommand,
  AdminGetUserCommand,
} = require("@aws-sdk/client-cognito-identity-provider");

const db = new DynamoDBClient({ region: "us-east-1" });
const cognito = new CognitoIdentityProviderClient({ region: "us-east-1" });

const USER_POOL_ID = "us-east-1_CAiea51iC";

// ─── helpers ──────────────────────────────────────────────────────────────────

function uid(prefix) {
  return `${prefix}_${Math.random().toString(36).slice(2, 10)}`;
}

function daysAgo(n) {
  return new Date(Date.now() - n * 86400000).toISOString();
}

function monthKey(offsetMonths = 0) {
  const d = new Date();
  d.setMonth(d.getMonth() - offsetMonths);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

async function put(TableName, item) {
  await db.send(new PutItemCommand({ TableName, Item: marshall(item, { removeUndefinedValues: true }) }));
  process.stdout.write(".");
}

async function ensureTable(name) {
  try {
    await db.send(new DescribeTableCommand({ TableName: name }));
  } catch {
    console.log(`\n  [warn] Table ${name} not found — skipping (run npm run deploy:backend first)`);
    return false;
  }
  return true;
}

// ─── Cognito demo accounts ────────────────────────────────────────────────────

async function createCognitoUser(email, password, name) {
  try {
    await cognito.send(new AdminGetUserCommand({ UserPoolId: USER_POOL_ID, Username: email }));
    console.log(`  [found] Cognito user already exists: ${email}`);
    return email;
  } catch {
    // doesn't exist — create
  }
  await cognito.send(new AdminCreateUserCommand({
    UserPoolId: USER_POOL_ID,
    Username: email,
    TemporaryPassword: "Temp@9999",
    MessageAction: "SUPPRESS",
    UserAttributes: [
      { Name: "email", Value: email },
      { Name: "email_verified", Value: "true" },
      { Name: "name", Value: name },
    ],
  }));
  await cognito.send(new AdminSetUserPasswordCommand({
    UserPoolId: USER_POOL_ID,
    Username: email,
    Password: password,
    Permanent: true,
  }));
  console.log(`  [created] ${email}`);
  return email;
}

// ─── seed data ────────────────────────────────────────────────────────────────

const USERS = [
  { userId: "user_demo_student1", name: "Alex Rivera",     email: "demo.student@toriino.com", role: "Student", status: "active",   phone: "+14155550101", createdAt: daysAgo(30), avatarUrl: "https://i.pravatar.cc/150?u=student1" },
  { userId: "user_demo_student2", name: "Priya Sharma",    email: "priya.sharma@example.com", role: "Student", status: "active",   phone: "+14155550102", createdAt: daysAgo(22), avatarUrl: "https://i.pravatar.cc/150?u=student2" },
  { userId: "user_demo_student3", name: "James Okafor",    email: "james.okafor@example.com", role: "Student", status: "active",   phone: "+14155550103", createdAt: daysAgo(15), avatarUrl: "https://i.pravatar.cc/150?u=student3" },
  { userId: "user_demo_student4", name: "Mei Lin",         email: "mei.lin@example.com",      role: "Student", status: "active",   phone: "+14155550104", createdAt: daysAgo(8),  avatarUrl: "https://i.pravatar.cc/150?u=student4" },
  { userId: "user_demo_student5", name: "Carlos Mendez",   email: "c.mendez@example.com",     role: "Student", status: "disabled", phone: "+14155550105", createdAt: daysAgo(45), avatarUrl: "https://i.pravatar.cc/150?u=student5" },
  { userId: "user_demo_mentor1",  name: "Dr. Sarah Chen",  email: "demo.mentor@toriino.com",  role: "Mentor",  status: "active",   phone: "+14155550201", createdAt: daysAgo(60), avatarUrl: "https://i.pravatar.cc/150?u=mentor1" },
  { userId: "user_demo_mentor2",  name: "Prof. David Kim", email: "d.kim@example.com",        role: "Mentor",  status: "active",   phone: "+14155550202", createdAt: daysAgo(55), avatarUrl: "https://i.pravatar.cc/150?u=mentor2" },
  { userId: "user_demo_mentor3",  name: "Emma Johansson",  email: "emma.j@example.com",       role: "Mentor",  status: "active",   phone: "+14155550203", createdAt: daysAgo(40), avatarUrl: "https://i.pravatar.cc/150?u=mentor3" },
  { userId: "user_demo_teacher1", name: "Mark Thompson",   email: "m.thompson@example.com",   role: "Teacher", status: "active",   phone: "+14155550301", createdAt: daysAgo(50), avatarUrl: "https://i.pravatar.cc/150?u=teacher1" },
  { userId: "user_demo_teacher2", name: "Aisha Patel",     email: "a.patel@example.com",      role: "Teacher", status: "active",   phone: "+14155550302", createdAt: daysAgo(35), avatarUrl: "https://i.pravatar.cc/150?u=teacher2" },
];

const COURSES = [
  { courseId: "course_001", title: "Python for Beginners",         description: "Learn Python from scratch with hands-on projects.", category: "Programming", price: 49.99,  status: "published", mentorId: "user_demo_mentor1", enrollments: 34, rating: 4.8, createdAt: daysAgo(50), thumbnail: "https://picsum.photos/seed/py/300/200" },
  { courseId: "course_002", title: "Advanced Machine Learning",    description: "Deep dive into ML algorithms and real-world datasets.", category: "AI/ML",       price: 129.99, status: "published", mentorId: "user_demo_mentor2", enrollments: 18, rating: 4.6, createdAt: daysAgo(40), thumbnail: "https://picsum.photos/seed/ml/300/200" },
  { courseId: "course_003", title: "Public Speaking Mastery",      description: "Build confidence and communication skills.",           category: "Soft Skills",  price: 39.99,  status: "published", mentorId: "user_demo_mentor3", enrollments: 52, rating: 4.9, createdAt: daysAgo(35), thumbnail: "https://picsum.photos/seed/ps/300/200" },
  { courseId: "course_004", title: "Data Structures & Algorithms", description: "Crack coding interviews with DSA fundamentals.",       category: "Programming", price: 79.99,  status: "published", mentorId: "user_demo_mentor1", enrollments: 29, rating: 4.7, createdAt: daysAgo(25), thumbnail: "https://picsum.photos/seed/dsa/300/200" },
  { courseId: "course_005", title: "UX Design Fundamentals",       description: "Design user-friendly interfaces from the ground up.", category: "Design",       price: 59.99,  status: "draft",     mentorId: "user_demo_mentor2", enrollments: 0,  rating: 0,   createdAt: daysAgo(5),  thumbnail: "https://picsum.photos/seed/ux/300/200" },
];

const SESSIONS = [
  { sessionId: "sess_001", title: "Python Intro Session",       mentorId: "user_demo_mentor1", studentId: "user_demo_student1", courseId: "course_001", status: "completed",   dateTime: daysAgo(20), duration: 60, price: 49.99,  createdAt: daysAgo(25) },
  { sessionId: "sess_002", title: "ML Concepts Review",         mentorId: "user_demo_mentor2", studentId: "user_demo_student2", courseId: "course_002", status: "completed",   dateTime: daysAgo(15), duration: 90, price: 99.99,  createdAt: daysAgo(18) },
  { sessionId: "sess_003", title: "Public Speaking Practice",   mentorId: "user_demo_mentor3", studentId: "user_demo_student3", courseId: "course_003", status: "completed",   dateTime: daysAgo(10), duration: 45, price: 39.99,  createdAt: daysAgo(12) },
  { sessionId: "sess_004", title: "DSA Problem Solving",        mentorId: "user_demo_mentor1", studentId: "user_demo_student4", courseId: "course_004", status: "completed",   dateTime: daysAgo(7),  duration: 60, price: 69.99,  createdAt: daysAgo(9) },
  { sessionId: "sess_005", title: "Python Advanced Topics",     mentorId: "user_demo_mentor1", studentId: "user_demo_student2", courseId: "course_001", status: "scheduled",   dateTime: daysAgo(-2), duration: 60, price: 49.99,  createdAt: daysAgo(3) },
  { sessionId: "sess_006", title: "ML Project Review",          mentorId: "user_demo_mentor2", studentId: "user_demo_student1", courseId: "course_002", status: "scheduled",   dateTime: daysAgo(-3), duration: 90, price: 99.99,  createdAt: daysAgo(2) },
  { sessionId: "sess_007", title: "Live Coding Session",        mentorId: "user_demo_mentor1", studentId: "user_demo_student3", courseId: "course_004", status: "in_progress", dateTime: daysAgo(0),  duration: 60, price: 69.99,  createdAt: daysAgo(1) },
  { sessionId: "sess_008", title: "Presentation Skills",        mentorId: "user_demo_mentor3", studentId: "user_demo_student4", courseId: "course_003", status: "completed",   dateTime: daysAgo(30), duration: 45, price: 39.99,  createdAt: daysAgo(32) },
  { sessionId: "sess_009", title: "Interview Prep: Arrays",     mentorId: "user_demo_mentor2", studentId: "user_demo_student3", courseId: "course_004", status: "cancelled",   dateTime: daysAgo(12), duration: 60, price: 69.99,  createdAt: daysAgo(14) },
  { sessionId: "sess_010", title: "Intro to Neural Networks",   mentorId: "user_demo_mentor2", studentId: "user_demo_student4", courseId: "course_002", status: "completed",   dateTime: daysAgo(5),  duration: 90, price: 99.99,  createdAt: daysAgo(7) },
];

const MENTORS = [
  { mentorId: "user_demo_mentor1", bio: "PhD in Computer Science, 10+ years teaching Python and ML. Former Google engineer.", specialties: ["Python", "Machine Learning", "Algorithms"], hourlyRate: 80, approved: true, totalSessions: 142, createdAt: daysAgo(60) },
  { mentorId: "user_demo_mentor2", bio: "Associate Professor at MIT. Expert in AI/ML and data science. Published researcher.", specialties: ["Machine Learning", "Data Science", "Statistics"], hourlyRate: 120, approved: true, totalSessions: 98, createdAt: daysAgo(55) },
  { mentorId: "user_demo_mentor3", bio: "TEDx speaker and communication coach. Helped 500+ professionals improve their presence.", specialties: ["Public Speaking", "Leadership", "Communication"], hourlyRate: 60, approved: true, totalSessions: 210, createdAt: daysAgo(40) },
];

const ENROLLMENTS = [
  { enrollmentId: "enrl_001", userId: "user_demo_student1", courseId: "course_001", status: "active",    enrolledAt: daysAgo(25), progress: 65 },
  { enrollmentId: "enrl_002", userId: "user_demo_student1", courseId: "course_002", status: "active",    enrolledAt: daysAgo(10), progress: 20 },
  { enrollmentId: "enrl_003", userId: "user_demo_student2", courseId: "course_002", status: "active",    enrolledAt: daysAgo(18), progress: 40 },
  { enrollmentId: "enrl_004", userId: "user_demo_student2", courseId: "course_001", status: "completed", enrolledAt: daysAgo(30), progress: 100 },
  { enrollmentId: "enrl_005", userId: "user_demo_student3", courseId: "course_003", status: "active",    enrolledAt: daysAgo(12), progress: 55 },
  { enrollmentId: "enrl_006", userId: "user_demo_student3", courseId: "course_004", status: "active",    enrolledAt: daysAgo(9),  progress: 30 },
  { enrollmentId: "enrl_007", userId: "user_demo_student4", courseId: "course_004", status: "active",    enrolledAt: daysAgo(7),  progress: 15 },
  { enrollmentId: "enrl_008", userId: "user_demo_student4", courseId: "course_003", status: "active",    enrolledAt: daysAgo(5),  progress: 10 },
];

const REVIEWS = [
  { targetId: "user_demo_mentor1", reviewId: "rev_001", reviewerId: "user_demo_student1", targetType: "mentor", rating: 5, comment: "Absolutely amazing mentor! Explains concepts clearly and is very patient.", createdAt: daysAgo(18) },
  { targetId: "user_demo_mentor1", reviewId: "rev_002", reviewerId: "user_demo_student4", targetType: "mentor", rating: 5, comment: "Best Python teacher I've had. Really helped me crack my interview.", createdAt: daysAgo(5) },
  { targetId: "user_demo_mentor2", reviewId: "rev_003", reviewerId: "user_demo_student2", targetType: "mentor", rating: 4, comment: "Very knowledgeable but sessions can be a bit fast-paced.", createdAt: daysAgo(12) },
  { targetId: "user_demo_mentor2", reviewId: "rev_004", reviewerId: "user_demo_student4", targetType: "mentor", rating: 5, comment: "Incredible depth of knowledge in ML. Worth every penny.", createdAt: daysAgo(4) },
  { targetId: "user_demo_mentor3", reviewId: "rev_005", reviewerId: "user_demo_student3", targetType: "mentor", rating: 5, comment: "Transformed my public speaking skills in just 3 sessions!", createdAt: daysAgo(8) },
  { targetId: "course_001",        reviewId: "rev_006", reviewerId: "user_demo_student2", targetType: "course", rating: 5, comment: "Perfect for beginners. Very well structured course.", createdAt: daysAgo(25) },
  { targetId: "course_002",        reviewId: "rev_007", reviewerId: "user_demo_student2", targetType: "course", rating: 4, comment: "Great content, some prerequisites needed.", createdAt: daysAgo(15) },
  { targetId: "course_003",        reviewId: "rev_008", reviewerId: "user_demo_student3", targetType: "course", rating: 5, comment: "Life-changing course. Highly recommend to everyone.", createdAt: daysAgo(7) },
];

// Earnings: last 6 months per mentor
function buildEarnings() {
  const records = [];
  const mentors = ["user_demo_mentor1", "user_demo_mentor2", "user_demo_mentor3"];
  const amounts = [[1240, 980, 1560, 2100, 1890, 2340], [1800, 2100, 1650, 2400, 2800, 3100], [780, 960, 1120, 1340, 1050, 1480]];
  const sessions = [[12, 10, 15, 20, 18, 22], [15, 18, 14, 20, 24, 26], [9, 11, 13, 15, 12, 17]];

  mentors.forEach((mentorId, mi) => {
    for (let mo = 5; mo >= 0; mo--) {
      records.push({
        earningId: `earn_${mentorId}_${monthKey(mo)}`,
        userId: mentorId,
        periodKey: monthKey(mo),
        totalAmount: amounts[mi][5 - mo],
        sessionCount: sessions[mi][5 - mo],
        createdAt: daysAgo(mo * 30),
      });
    }
  });
  return records;
}

const AI_CHAT = Array.from({ length: 15 }, (_, i) => ({
  messageId: `msg_${i + 1}`,
  chatId: `chat_${i + 1}`,
  userId: USERS[i % 5].userId,
  role: i % 2 === 0 ? "user" : "assistant",
  content: i % 2 === 0 ? "Help me understand recursion." : "Recursion is a function that calls itself with a simpler input until it reaches a base case.",
  createdAt: daysAgo(i * 2),
}));

const SESSION_SUMMARIES = [
  { sessionId: "sess_001", summary: "Covered Python basics: variables, loops, and functions. Student showed strong progress.", keyPoints: ["variables", "for loops", "def functions"], createdAt: daysAgo(19) },
  { sessionId: "sess_002", summary: "Reviewed linear regression and gradient descent. Student struggled with math notation but understood concepts.", keyPoints: ["linear regression", "gradient descent", "cost function"], createdAt: daysAgo(14) },
  { sessionId: "sess_003", summary: "Practiced presentation openers and managing stage fright. Great improvement noted.", keyPoints: ["opening hooks", "body language", "eye contact"], createdAt: daysAgo(9) },
  { sessionId: "sess_004", summary: "Solved 5 array problems. Covered two-pointer and sliding window techniques.", keyPoints: ["two-pointer", "sliding window", "time complexity"], createdAt: daysAgo(6) },
];

// ─── main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log("\n================================================");
  console.log("  TORIINO — Seed Demo Data");
  console.log("================================================\n");

  // 1. Cognito demo users
  console.log("  Creating Cognito demo accounts...");
  await createCognitoUser("demo.student@toriino.com", "Demo@1234", "Alex Rivera");
  await createCognitoUser("demo.mentor@toriino.com",  "Demo@1234", "Dr. Sarah Chen");

  // 2. DynamoDB
  const tables = {
    "torino-users":              USERS,
    "torino-courses":            COURSES,
    "torino-sessions":           SESSIONS,
    "torino-mentors":            MENTORS,
    "toriino-enrollments":       ENROLLMENTS,
    "toriino-reviews":           REVIEWS,
    "torino-earnings":           buildEarnings(),
    "toriino-ai-chat":           AI_CHAT,
    "toriino-session-summaries": SESSION_SUMMARIES,
  };

  for (const [table, rows] of Object.entries(tables)) {
    const ok = await ensureTable(table);
    if (!ok) continue;
    process.stdout.write(`\n  Seeding ${table} (${rows.length} rows) `);
    for (const row of rows) {
      const key = Object.keys(row)[0];
      await put(table, row);
    }
  }

  console.log("\n\n================================================");
  console.log("  DONE");
  console.log("================================================");
  console.log("\n  Demo accounts (mobile app login):");
  console.log("    Student  : demo.student@toriino.com  / Demo@1234");
  console.log("    Mentor   : demo.mentor@toriino.com   / Demo@1234");
  console.log("\n  Admin panel login:");
  console.log("    oriarte88@gmail.com / Todd@#$13");
  console.log("\n  Admin panel URL:");
  console.log("    https://d3gfpgvykn0mv4.cloudfront.net\n");
}

main().catch(e => { console.error(`\n  [error] ${e.message}\n`); process.exit(1); });
