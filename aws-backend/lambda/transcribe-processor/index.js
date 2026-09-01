const { TranscribeClient, StartTranscriptionJobCommand, GetTranscriptionJobCommand } = require("@aws-sdk/client-transcribe");
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand, GetCommand } = require("@aws-sdk/lib-dynamodb");

const REGION = process.env.AWS_REGION || "us-east-1";
const TRANSCRIPTS_TABLE = process.env.TRANSCRIPTS_TABLE || "toriino-transcripts";
const SUMMARIES_TABLE = process.env.SUMMARIES_TABLE || "toriino-session-summaries";
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = "gemini-1.5-flash-latest";
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

const transcribeClient = new TranscribeClient({ region: REGION });
const dynamodb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));

// This Lambda is triggered by S3 PutObject events from Agora Cloud Recording
exports.handler = async (event) => {
  console.log("Transcribe processor event:", JSON.stringify(event, null, 2));

  for (const record of event.Records || []) {
    try {
      await processS3Record(record);
    } catch (error) {
      console.error("Error processing record:", error);
    }
  }
};

async function processS3Record(record) {
  const bucketName = record.s3.bucket.name;
  const objectKey = decodeURIComponent(record.s3.object.key.replace(/\+/g, " "));

  // Only process audio/video files from recordings prefix
  if (!objectKey.startsWith("recordings/") || !objectKey.match(/\.(mp4|m4a|mp3|wav|webm)$/i)) {
    console.log("Skipping non-media file:", objectKey);
    return;
  }

  // Extract sessionId from path: recordings/{sessionId}/filename.mp4
  const sessionId = objectKey.split("/")[1];
  if (!sessionId) {
    console.log("Could not extract sessionId from key:", objectKey);
    return;
  }

  const jobName = `toriino-${sessionId}-${Date.now()}`;
  const s3Uri = `s3://${bucketName}/${objectKey}`;

  console.log(`Starting transcription for session ${sessionId}, job: ${jobName}`);

  // Start AWS Transcribe job
  await transcribeClient.send(
    new StartTranscriptionJobCommand({
      TranscriptionJobName: jobName,
      LanguageCode: "en-US",
      MediaFormat: objectKey.split(".").pop().toLowerCase(),
      Media: { MediaFileUri: s3Uri },
      Settings: {
        ShowSpeakerLabels: true,
        MaxSpeakerLabels: 10,
        ShowAlternatives: false,
      },
      OutputBucketName: bucketName,
      OutputKey: `transcripts/${sessionId}/${jobName}.json`,
    })
  );

  // Poll for completion (Lambda max 15 min, Transcribe jobs typically complete in 1-5 min)
  const transcript = await pollTranscriptionJob(jobName);
  if (!transcript) {
    console.error("Transcription job failed or timed out for session:", sessionId);
    return;
  }

  // Save structured transcript to DynamoDB
  const now = new Date().toISOString();
  const segments = buildSegments(transcript);
  const plainText = segments.map((s) => `[${s.speakerName}]: ${s.text}`).join("\n");

  const transcriptItem = {
    sessionId, source: "agora-cloud-recording", segments, plainText,
    segmentCount: segments.length, createdAt: now, updatedAt: now,
  };
  await dynamodb.send(new PutCommand({ TableName: TRANSCRIPTS_TABLE, Item: transcriptItem }));
  console.log(`Transcript saved for session ${sessionId}`);

  // Auto-generate Gemini summary
  await generateAndSaveSummary(sessionId, plainText, now);
}

async function pollTranscriptionJob(jobName, maxWaitMs = 600000) {
  const pollInterval = 15000;
  const startTime = Date.now();

  while (Date.now() - startTime < maxWaitMs) {
    const result = await transcribeClient.send(
      new GetTranscriptionJobCommand({ TranscriptionJobName: jobName })
    );
    const status = result.TranscriptionJob?.TranscriptionJobStatus;
    console.log(`Job ${jobName} status: ${status}`);

    if (status === "COMPLETED") {
      const transcriptUri = result.TranscriptionJob.Transcript.TranscriptFileUri;
      const res = await fetch(transcriptUri);
      return await res.json();
    }
    if (status === "FAILED") return null;

    await new Promise((resolve) => setTimeout(resolve, pollInterval));
  }
  return null;
}

function buildSegments(transcript) {
  const items = transcript?.results?.items || [];
  const speakerSegments = {};
  let currentSpeaker = null;
  let currentText = [];

  for (const item of items) {
    if (item.type === "pronunciation") {
      const speaker = item.speaker_label || "Speaker_0";
      if (speaker !== currentSpeaker) {
        if (currentSpeaker !== null && currentText.length > 0) {
          speakerSegments[`${currentSpeaker}_${Object.keys(speakerSegments).length}`] = {
            speakerId: currentSpeaker,
            speakerName: `Speaker ${currentSpeaker.replace("spk_", "")}`,
            text: currentText.join(" "),
            timestamp: item.start_time,
          };
        }
        currentSpeaker = speaker;
        currentText = [item.alternatives?.[0]?.content || ""];
      } else {
        currentText.push(item.alternatives?.[0]?.content || "");
      }
    } else if (item.type === "punctuation") {
      if (currentText.length > 0) {
        currentText[currentText.length - 1] += item.alternatives?.[0]?.content || "";
      }
    }
  }

  // Flush last segment
  if (currentSpeaker !== null && currentText.length > 0) {
    speakerSegments[`${currentSpeaker}_final`] = {
      speakerId: currentSpeaker,
      speakerName: `Speaker ${currentSpeaker.replace("spk_", "")}`,
      text: currentText.join(" "),
      timestamp: "0",
    };
  }

  return Object.values(speakerSegments);
}

async function generateAndSaveSummary(sessionId, plainText, now) {
  try {
    const prompt = `You are an expert educational AI. Analyze this session transcript and return JSON:
{
  "summary": "2-3 paragraph summary",
  "actionItems": ["action 1", "action 2"],
  "keyTopics": ["topic 1", "topic 2"],
  "insights": ["insight 1", "insight 2"]
}
Transcript:
${plainText.substring(0, 8000)}
Return ONLY valid JSON.`;

    const geminiResponse = await fetch(GEMINI_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
    });

    if (!geminiResponse.ok) throw new Error(`Gemini error: ${geminiResponse.status}`);
    const geminiData = await geminiResponse.json();
    const rawText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || "{}";
    const cleaned = rawText.replace(/```json\n?|\n?```/g, "").trim();
    const parsed = JSON.parse(cleaned);

    await dynamodb.send(
      new PutCommand({
        TableName: SUMMARIES_TABLE,
        Item: {
          sessionId, source: "auto-transcribe",
          summary: parsed.summary || "",
          actionItems: parsed.actionItems || [],
          keyTopics: parsed.keyTopics || [],
          insights: parsed.insights || [],
          generatedAt: now, createdAt: now,
        },
      })
    );
    console.log(`Auto-summary saved for session ${sessionId}`);
  } catch (error) {
    console.error("Failed to generate auto-summary:", error);
  }
}
