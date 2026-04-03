require('dotenv').config();

const express = require('express');
const cors = require('cors');
const multer = require('multer');
const fs = require('fs/promises');

const app = express();
const upload = multer({ dest: 'uploads/' });

app.use(cors());
app.use(express.json({ limit: '25mb' }));

const PORT = process.env.PORT || 8787;
const ASSEMBLYAI_KEY = process.env.ASSEMBLYAI_KEY;
const ANTHROPIC_KEY = process.env.ANTHROPIC_KEY;

const SYSTEM_PROMPT = `
You are Scrib, an expert academic note-taker and educator. Your job is to turn raw lecture transcripts into beautiful, student-friendly study materials.

Given a lecture transcript, return ONLY a valid JSON object (no markdown code fences, no preamble) matching this schema:

{
  "summary": "A 3-5 sentence executive summary of the entire lecture.",
  "topics": ["Topic 1", "Topic 2", "Topic 3"],
  "fullNotes": "Full Markdown-formatted notes. Use ## for major topics, ### for subtopics, **bold** for key terms, bullet lists for details, > blockquotes for important quotes or definitions, and tables where comparisons are useful. Make this genuinely useful for studying.",
  "keyPoints": [
    "Concise key takeaway 1",
    "Concise key takeaway 2"
  ],
  "flashcards": [
    { "question": "What is X?", "answer": "X is..." },
    { "question": "What is Y?", "answer": "Y is..." }
  ]
}

Rules:
- Aim for 8-15 flashcards covering the most important concepts.
- Key points should be self-contained (understandable without reading the notes).
- The fullNotes should be comprehensive.
- If the transcript mentions formulas, render them in LaTeX-style (e.g. $E = mc^2$).
- Do NOT include anything outside the JSON object.
`;

function requireEnv() {
  const missing = [];
  if (!ASSEMBLYAI_KEY) missing.push('ASSEMBLYAI_KEY');
  if (!ANTHROPIC_KEY) missing.push('ANTHROPIC_KEY');
  return missing;
}

app.get('/health', (req, res) => {
  const missing = requireEnv();
  res.json({ ok: true, missingEnv: missing });
});

app.post('/api/transcribe', upload.single('audio'), async (req, res) => {
  const missing = requireEnv();
  if (missing.length > 0) {
    return res.status(500).json({ error: `Missing env: ${missing.join(', ')}` });
  }

  if (!req.file) {
    return res.status(400).json({ error: 'No audio file uploaded. Use form field name: audio.' });
  }

  try {
    const fileBuffer = await fs.readFile(req.file.path);

    const uploadResp = await fetch('https://api.assemblyai.com/v2/upload', {
      method: 'POST',
      headers: {
        authorization: ASSEMBLYAI_KEY,
        'content-type': 'application/octet-stream'
      },
      body: fileBuffer
    });

    const uploadJson = await uploadResp.json();
    if (!uploadResp.ok || !uploadJson.upload_url) {
      return res.status(502).json({ error: 'Assembly upload failed', details: uploadJson });
    }

    const transcriptResp = await fetch('https://api.assemblyai.com/v2/transcript', {
      method: 'POST',
      headers: {
        authorization: ASSEMBLYAI_KEY,
        'content-type': 'application/json'
      },
      body: JSON.stringify({
        audio_url: uploadJson.upload_url,
        speaker_labels: true,
        auto_chapters: true,
        punctuate: true,
        format_text: true
      })
    });

    const transcriptReqJson = await transcriptResp.json();
    if (!transcriptResp.ok || !transcriptReqJson.id) {
      return res.status(502).json({ error: 'Assembly transcript request failed', details: transcriptReqJson });
    }

    const transcriptId = transcriptReqJson.id;
    for (let i = 0; i < 180; i++) {
      await new Promise((resolve) => setTimeout(resolve, 4000));

      const pollResp = await fetch(`https://api.assemblyai.com/v2/transcript/${transcriptId}`, {
        headers: { authorization: ASSEMBLYAI_KEY }
      });
      const pollJson = await pollResp.json();

      if (!pollResp.ok) {
        return res.status(502).json({ error: 'Assembly polling failed', details: pollJson });
      }

      if (pollJson.status === 'completed') {
        return res.json({ transcript: pollJson.text || '' });
      }

      if (pollJson.status === 'error') {
        return res.status(502).json({ error: pollJson.error || 'Transcription failed' });
      }
    }

    return res.status(504).json({ error: 'Transcription timed out' });
  } catch (error) {
    return res.status(500).json({ error: 'Server transcription error', details: String(error) });
  } finally {
    if (req.file?.path) {
      fs.unlink(req.file.path).catch(() => {});
    }
  }
});

app.post('/api/notes', async (req, res) => {
  const missing = requireEnv();
  if (missing.length > 0) {
    return res.status(500).json({ error: `Missing env: ${missing.join(', ')}` });
  }

  const transcript = req.body?.transcript;
  if (!transcript || typeof transcript !== 'string') {
    return res.status(400).json({ error: 'Body must include a transcript string.' });
  }

  try {
    const notesResp = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': ANTHROPIC_KEY,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: 'claude-opus-4-5',
        max_tokens: 8192,
        system: SYSTEM_PROMPT,
        messages: [
          {
            role: 'user',
            content: `Here is the lecture transcript. Generate the notes now:\n\n${transcript}`
          }
        ]
      })
    });

    const notesJson = await notesResp.json();
    if (!notesResp.ok) {
      return res.status(502).json({ error: 'Anthropic request failed', details: notesJson });
    }

    const rawText = (notesJson.content || [])
      .filter((block) => block.type === 'text')
      .map((block) => block.text)
      .join('');

    const cleanJson = rawText
      .replace(/^```json\s*/gm, '')
      .replace(/^```\s*/gm, '')
      .trim();

    const parsed = JSON.parse(cleanJson);
    return res.json(parsed);
  } catch (error) {
    return res.status(500).json({ error: 'Server notes error', details: String(error) });
  }
});

app.listen(PORT, () => {
  console.log(`Scrib backend running on http://localhost:${PORT}`);
});
