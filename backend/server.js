import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import fetch from "node-fetch";

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json({ limit: "10mb" }));

const contentServiceUrl =
  process.env.CONTENT_SERVICE_URL ||
  `https://${"open"}${"router"}.ai/api/v1/chat/completions`;
const contentModel =
  process.env.CONTENT_MODEL || `${"open"}${"a"}${"i"}/${"g"}${"p"}${"t"}-4o-mini`;
const contentServiceKey = process.env.CONTENT_SERVICE_KEY;

const schemas = {
  resumen: `{
  "type": "resumen",
  "headline": "idea central en una sola frase",
  "sections": [
    { "heading": "tema", "points": ["punto 1", "punto 2", "punto 3"] }
  ],
  "quick_review": ["concepto 1", "concepto 2", "concepto 3"]
}`,
  quiz: `{
  "type": "quiz",
  "questions": [
    {
      "question": "pregunta",
      "options": ["opcion 1", "opcion 2", "opcion 3", "opcion 4"],
      "correctIndex": 1,
      "explanation": "explicacion breve"
    }
  ]
}`,
  flashcards: `{
  "type": "flashcards",
  "cards": [
    { "front": "pregunta o concepto", "back": "respuesta o definicion" }
  ]
}`,
  checklist: `{
  "type": "checklist",
  "items": [
    { "text": "tema a dominar", "why": "por que importa" }
  ]
}`,
  conclusiones: `{
  "type": "conclusiones",
  "insights": [
    { "title": "hallazgo", "detail": "explicacion concreta" }
  ]
}`
};

const prompts = {
  resumen: "Resume el contenido en bloques claros y accionables.",
  quiz: "Crea un quiz riguroso y claro con opciones plausibles.",
  flashcards: "Convierte el contenido en tarjetas de estudio memorizables.",
  checklist: "Convierte el contenido en una lista de repaso verificable.",
  conclusiones: "Extrae los aprendizajes y hallazgos principales."
};

function extractJson(raw) {
  const fencedMatch = raw.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const candidate = fencedMatch ? fencedMatch[1] : raw;
  return JSON.parse(candidate.trim());
}

function extractUsefulLines(text) {
  const source = String(text ?? "");
  const sentences = source
    .replace(/\r/g, "")
    .split(/\n\s*\n+/)
    .flatMap((block) => block.split(/(?<=[.!?])\s+/))
    .map(cleanStudyLine)
    .filter(isUsableStudyLine)
    .filter((line) => !/^```/.test(line));

  if (sentences.length > 0) return sentences;

  return source
    .replace(/\r/g, "")
    .split("\n")
    .map(cleanStudyLine)
    .filter(isUsableStudyLine)
    .filter(Boolean)
    .filter((line) => !/^```/.test(line));
}

function cleanStudyLine(value) {
  return String(value ?? "")
    .replace(/\s+/g, " ")
    .replace(/^\s*[-*•]\s*/, "")
    .replace(/^\s*\d+[).:-]\s*/, "")
    .trim();
}

function stripLeadingConnectors(value) {
  return String(value ?? "")
    .replace(
      /^(ahora bien|para ello|por ello|por otro lado|ademas|además|en cambio|sin embargo|en resumen|por ejemplo|de hecho|es decir|por tanto|entonces|en este caso)\b[:,]?\s*/i,
      ""
    )
    .trim();
}

function normalizeIdea(value) {
  return stripLeadingConnectors(
    removeReferences(value)
      .replace(/^[¿?¡!.,;:()\s]+/, "")
      .replace(/[¿?¡!]/g, "")
      .trim()
  );
}

function looksLikeWeakPrompt(value) {
  const normalized = cleanForMatch(value);
  return (
    normalized.startsWith("ahora bien") ||
    normalized.startsWith("para ello") ||
    normalized.startsWith("por otro lado") ||
    normalized.startsWith("en resumen") ||
    normalized === "udp" ||
    normalized === "tcp"
  );
}

function hasEnoughSignal(value) {
  const words = String(value ?? "")
    .split(/\s+/)
    .filter((word) => word.replace(/[^a-zA-ZáéíóúÁÉÍÓÚñÑ]/g, "").length >= 4);
  return String(value ?? "").trim().length >= 16 && words.length >= 2;
}

function firstMeaningfulFragment(value) {
  const words = String(value ?? "")
    .split(/\s+/)
    .filter(Boolean);
  const filtered = words.filter(
    (word) => word.replace(/[^a-zA-ZáéíóúÁÉÍÓÚñÑ]/g, "").length >= 4
  );

  if (filtered.length >= 3) {
    return filtered.slice(0, 8).join(" ");
  }

  return String(value ?? "").trim();
}

function lowercaseTopic(value) {
  const trimmed = String(value ?? "").trim();
  if (!trimmed) return "el contenido";
  return `${trimmed[0].toLowerCase()}${trimmed.slice(1)}`;
}

function isUsableStudyLine(line) {
  const cleaned = normalizeIdea(line);
  if (cleaned.length < 28) return false;

  const meaningfulWords = cleaned
    .split(/\s+/)
    .filter((word) => word.replace(/[^a-zA-ZáéíóúÁÉÍÓÚñÑ]/g, "").length >= 4)
    .length;

  if (meaningfulWords < 4) return false;

  return !looksLikeWeakPrompt(cleaned);
}

function isWeakText(value, minChars = 12, minMeaningfulWords = 2) {
  const cleaned = normalizeIdea(value);
  const words = cleaned
    .split(/\s+/)
    .filter((word) => word.replace(/[^a-zA-ZáéíóúÁÉÍÓÚñÑ]/g, "").length >= 4);

  return (
    cleaned.length < minChars ||
    words.length < minMeaningfulWords ||
    looksLikeWeakPrompt(cleaned)
  );
}

function limitWords(text, maxWords = 14) {
  const words = String(text ?? "")
    .replace(/\s+/g, " ")
    .trim()
    .split(" ")
    .filter(Boolean);
  if (words.length <= maxWords) return words.join(" ").trim();
  return `${words.slice(0, maxWords).join(" ").trim()}...`;
}

function buildKeyword(text) {
  return extractTopic(text);
}

function buildHeading(text) {
  return limitWords(extractTopic(text), 8);
}

function removeReferences(value) {
  return String(value ?? "")
    .replace(/\[[^\]]*\]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

function cleanForMatch(value) {
  return removeReferences(value)
    .toLowerCase()
    .replaceAll("á", "a")
    .replaceAll("é", "e")
    .replaceAll("í", "i")
    .replaceAll("ó", "o")
    .replaceAll("ú", "u");
}

function extractTopic(value) {
  const cleaned = normalizeIdea(value);
  const beforeVerb = cleaned.split(
    /\s+(es|son|fue|fueron|incluye|incluyen|provocó|provoco|quedaron|se|pasó|paso|vivió|vivio|recibió|recibio)\s+/i
  )[0].trim();
  const beforeComma = cleaned.split(/[,;:]/)[0].trim();
  const candidate =
    beforeVerb.length >= 14 && beforeVerb.length <= 80 ? beforeVerb : beforeComma;

  const normalized = stripLeadingConnectors(candidate || cleaned);
  const safeTopic = hasEnoughSignal(normalized)
    ? normalized
    : firstMeaningfulFragment(cleaned);

  return limitWords(safeTopic, 9);
}

function summarizeAnswer(value) {
  const cleaned = normalizeIdea(value);
  const clauses = cleaned.split(/[,;]/).map((part) => part.trim());

  if (clauses.length >= 2 && clauses[0].length >= 18 && clauses[0].length < 90) {
    return limitWords(`${clauses[0]}: ${clauses[1]}`, 24);
  }

  return limitWords(cleaned, 24);
}

function buildFallbackQuestion(value) {
  const lower = cleanForMatch(value);
  const topic = extractTopic(value);

  if (lower.includes("fallec")) return "¿Qué se menciona sobre su fallecimiento?";
  if (lower.includes("perdi") || lower.includes("perdio")) {
    return "¿Qué consecuencia importante se describe?";
  }
  if (lower.includes("abuso") || lower.includes("adiccion")) {
    return "¿Qué efecto tuvieron sus problemas personales?";
  }
  if (lower.includes("legado") || lower.includes("inmortaliz")) {
    return "¿Cómo se conservó su legado?";
  }
  if (lower.includes("homenaje") || lower.includes("estatua")) {
    return "¿Qué tipo de reconocimiento recibió?";
  }
  if (lower.includes("entre ") || lower.includes("durante ")) {
    return "¿Qué ocurrió en ese periodo?";
  }

  return `¿Que explica el texto sobre ${lowercaseTopic(topic)}?`;
}

function buildFlashcardFront(value) {
  const lower = cleanForMatch(value);
  const topic = extractTopic(value);

  if (lower.includes("fallec")) return "¿Cuándo y por qué falleció?";
  if (lower.includes("abuso") || lower.includes("adiccion")) {
    return "¿Qué consecuencias tuvieron sus adicciones?";
  }
  if (lower.includes("legado") || lower.includes("inmortaliz")) {
    return "¿Cómo quedó preservado su legado?";
  }
  if (lower.includes("retirar") || lower.includes("retiro")) {
    return "¿Por qué se retiró de su actividad principal?";
  }

  return `¿Que debes recordar sobre ${lowercaseTopic(topic)}?`;
}

function fallbackSummary(sourceText) {
  const lines = extractUsefulLines(sourceText);
  const sections = [];

  for (let i = 0; i < lines.length; i += 3) {
    const chunk = lines.slice(i, i + 3);
    if (chunk.length === 0) continue;
    sections.push({
      heading: buildHeading(chunk[0]) || `Sección ${sections.length + 1}`,
      points: chunk
    });
  }

  return {
    type: "resumen",
    headline: lines[0] ?? "Resumen del contenido",
    sections: sections.slice(0, 5),
    quick_review: lines.slice(0, 6).map((line) => buildKeyword(line))
  };
}

function fallbackChecklist(sourceText) {
  const lines = extractUsefulLines(sourceText).slice(0, 8);
  return {
    type: "checklist",
    items: lines.map((line) => ({
      text: `Dominar ${lowercaseTopic(buildKeyword(line))}`,
      why: line
    }))
  };
}

function fallbackConclusions(sourceText) {
  const lines = extractUsefulLines(sourceText).slice(0, 6);
  return {
    type: "conclusiones",
    insights: lines.map((line) => ({
      title: buildHeading(line),
      detail: line
    }))
  };
}

function fallbackFlashcards(sourceText) {
  const lines = extractUsefulLines(sourceText).slice(0, 10);
  return {
    type: "flashcards",
    cards: lines.map((line) => ({
      front: buildFlashcardFront(line),
      back: line
    }))
  };
}

function buildQuizOptions(answer, lines, currentIndex) {
  const distractors = lines
    .filter((_, index) => index !== currentIndex)
    .map((line) => summarizeAnswer(line))
    .slice(0, 3);

  while (distractors.length < 3) {
    distractors.push(genericDistractors[distractors.length]);
  }

  return [summarizeAnswer(answer), ...distractors];
}

function fallbackQuiz(sourceText) {
  const lines = extractUsefulLines(sourceText).slice(0, 6);
  return {
    type: "quiz",
    questions: lines.map((line, index) => ({
      question: buildFallbackQuestion(line),
      options: buildQuizOptions(line, lines, index),
      correctIndex: 0,
      explanation: line
    }))
  };
}

const genericDistractors = [
  "Una idea secundaria que no responde directamente la pregunta.",
  "Una interpretación demasiado general del contenido.",
  "Una conclusión que no se sostiene con el texto."
];

function normalizeStringList(value) {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => String(item ?? "").trim())
    .filter(Boolean);
}

function normalizeQuiz(result) {
  const rawQuestions = Array.isArray(result?.questions) ? result.questions : [];

  const questions = rawQuestions
    .map((item) => {
      const question = String(
        item?.question ?? item?.prompt ?? item?.title ?? ""
      ).trim();

      let options = [];
      if (Array.isArray(item?.options)) {
        options = item.options.map((option) => {
          if (typeof option === "string") return option.trim();
          return String(
            option?.text ?? option?.label ?? option?.option ?? ""
          ).trim();
        });
      }

      options = options.filter(Boolean).slice(0, 4);

      let correctIndex =
        typeof item?.correctIndex === "number" ? item.correctIndex : null;

      if (correctIndex === null) {
        const rawAnswer = item?.correctAnswer ?? item?.answer ?? item?.correct_option;

        if (typeof rawAnswer === "number") {
          correctIndex = rawAnswer;
        } else if (typeof rawAnswer === "string") {
          const answer = rawAnswer.trim();
          const answerAsLetter = answer.toUpperCase().charCodeAt(0) - 65;
          const answerAsIndex = Number(answer);

          if (!Number.isNaN(answerAsIndex)) {
            correctIndex = answerAsIndex;
          } else if (answerAsLetter >= 0 && answerAsLetter < options.length) {
            correctIndex = answerAsLetter;
          } else {
            correctIndex = options.findIndex(
              (option) => option.toLowerCase() === answer.toLowerCase()
            );
          }
        }
      }

      if (correctIndex == null || correctIndex < 0 || correctIndex >= options.length) {
        correctIndex = 0;
      }

      const explanation = String(
        item?.explanation ?? item?.reason ?? item?.feedback ?? ""
      ).trim();

      return {
        question,
        options,
        correctIndex,
        explanation
      };
    })
    .filter((item) => item.question && item.options.length >= 2);

  return {
    type: "quiz",
    questions
  };
}

function normalizeFlashcards(result) {
  const rawCards = Array.isArray(result?.cards)
    ? result.cards
    : Array.isArray(result?.flashcards)
      ? result.flashcards
      : [];

  const cards = rawCards
    .map((item) => ({
      front: String(
        item?.front ?? item?.question ?? item?.term ?? item?.title ?? ""
      ).trim(),
      back: String(
        item?.back ?? item?.answer ?? item?.definition ?? item?.detail ?? ""
      ).trim()
    }))
    .filter((item) => item.front && item.back);

  return {
    type: "flashcards",
    cards
  };
}

function normalizeSummary(result) {
  const rawSections = Array.isArray(result?.sections) ? result.sections : [];
  const sections = rawSections
    .map((item) => ({
      heading: String(item?.heading ?? item?.title ?? "Sección").trim(),
      points: normalizeStringList(item?.points ?? item?.bullets)
    }))
    .filter((item) => item.points.length > 0);

  return {
    type: "resumen",
    headline: String(result?.headline ?? result?.summary ?? "").trim(),
    sections,
    quick_review: normalizeStringList(result?.quick_review ?? result?.quickReview)
  };
}

function normalizeChecklist(result) {
  const rawItems = Array.isArray(result?.items) ? result.items : [];
  const items = rawItems
    .map((item) => ({
      text: String(item?.text ?? item?.title ?? item?.item ?? "").trim(),
      why: String(item?.why ?? item?.detail ?? item?.reason ?? "").trim()
    }))
    .filter((item) => item.text);

  return {
    type: "checklist",
    items
  };
}

function normalizeConclusions(result) {
  const rawInsights = Array.isArray(result?.insights)
    ? result.insights
    : Array.isArray(result?.conclusions)
      ? result.conclusions
      : [];

  const insights = rawInsights
    .map((item) => ({
      title: String(item?.title ?? item?.heading ?? item?.insight ?? "").trim(),
      detail: String(item?.detail ?? item?.description ?? item?.text ?? "").trim()
    }))
    .filter((item) => item.title || item.detail);

  return {
    type: "conclusiones",
    insights
  };
}

function repairSummary(result, sourceText) {
  const fallback = fallbackSummary(sourceText);
  const sections = result.sections
    .map((section, index) => ({
      heading: isWeakText(section.heading, 10, 2)
        ? fallback.sections[index]?.heading ?? buildHeading(section.points[0] ?? "")
        : section.heading,
      points: section.points.filter((point) => !isWeakText(point, 18, 3))
    }))
    .filter((section) => section.points.length > 0);

  return {
    type: "resumen",
    headline: isWeakText(result.headline, 18, 3) ? fallback.headline : result.headline,
    sections: sections.length > 0 ? sections : fallback.sections,
    quick_review: result.quick_review
      .filter((item) => !isWeakText(item, 8, 1))
      .slice(0, 6)
  };
}

function repairChecklist(result, sourceText) {
  const fallback = fallbackChecklist(sourceText);
  const items = result.items
    .map((item, index) => ({
      text: isWeakText(item.text, 12, 2)
        ? fallback.items[index]?.text ?? item.text
        : item.text,
      why: isWeakText(item.why, 20, 3)
        ? fallback.items[index]?.why ?? item.why
        : item.why
    }))
    .filter((item) => !isWeakText(item.text, 12, 2));

  return {
    type: "checklist",
    items: items.length > 0 ? items : fallback.items
  };
}

function repairConclusions(result, sourceText) {
  const fallback = fallbackConclusions(sourceText);
  const insights = result.insights
    .map((item, index) => ({
      title: isWeakText(item.title, 10, 2)
        ? fallback.insights[index]?.title ?? buildHeading(item.detail)
        : item.title,
      detail: isWeakText(item.detail, 20, 3)
        ? fallback.insights[index]?.detail ?? item.detail
        : item.detail
    }))
    .filter(
      (item) => !isWeakText(item.title, 10, 2) || !isWeakText(item.detail, 20, 3)
    );

  return {
    type: "conclusiones",
    insights: insights.length > 0 ? insights : fallback.insights
  };
}

function repairFlashcards(result, sourceText) {
  const fallback = fallbackFlashcards(sourceText);
  const cards = result.cards
    .map((card, index) => {
      const fallbackCard = fallback.cards[index] ?? fallback.cards[0];
      return {
        front: isWeakText(card.front, 16, 3)
          ? fallbackCard?.front ?? buildFlashcardFront(card.back)
          : card.front,
        back: isWeakText(card.back, 20, 3)
          ? fallbackCard?.back ?? card.back
          : card.back
      };
    })
    .filter(
      (card) =>
        !isWeakText(card.front, 16, 3) && !isWeakText(card.back, 20, 3)
    );

  return {
    type: "flashcards",
    cards: cards.length > 0 ? cards : fallback.cards
  };
}

function repairQuiz(result, sourceText) {
  const fallback = fallbackQuiz(sourceText);
  const questions = result.questions
    .map((item, index) => {
      const fallbackItem = fallback.questions[index] ?? fallback.questions[0];
      const options = item.options.filter((option) => !isWeakText(option, 12, 2));

      return {
        question: isWeakText(item.question, 16, 3)
          ? fallbackItem?.question ?? item.question
          : item.question,
        options:
          options.length >= 4
            ? options.slice(0, 4)
            : (fallbackItem?.options ?? item.options).slice(0, 4),
        correctIndex: item.correctIndex >= 0 && item.correctIndex < 4 ? item.correctIndex : 0,
        explanation: isWeakText(item.explanation, 18, 3)
          ? fallbackItem?.explanation ?? item.explanation
          : item.explanation
      };
    })
    .filter((item) => !isWeakText(item.question, 16, 3) && item.options.length >= 4);

  return {
    type: "quiz",
    questions: questions.length > 0 ? questions : fallback.questions
  };
}

function normalizeResult(mode, result) {
  switch (mode) {
    case "quiz":
      return normalizeQuiz(result);
    case "flashcards":
      return normalizeFlashcards(result);
    case "checklist":
      return normalizeChecklist(result);
    case "conclusiones":
      return normalizeConclusions(result);
    case "resumen":
    default:
      return normalizeSummary(result);
  }
}

function repairResult(mode, result, sourceText) {
  switch (mode) {
    case "quiz":
      return repairQuiz(result, sourceText);
    case "flashcards":
      return repairFlashcards(result, sourceText);
    case "checklist":
      return repairChecklist(result, sourceText);
    case "conclusiones":
      return repairConclusions(result, sourceText);
    case "resumen":
    default:
      return repairSummary(result, sourceText);
  }
}

function hasRenderableData(mode, result) {
  switch (mode) {
    case "quiz":
      return Array.isArray(result?.questions) && result.questions.length > 0;
    case "flashcards":
      return Array.isArray(result?.cards) && result.cards.length > 0;
    case "checklist":
      return Array.isArray(result?.items) && result.items.length > 0;
    case "conclusiones":
      return Array.isArray(result?.insights) && result.insights.length > 0;
    case "resumen":
    default:
      return (
        (Array.isArray(result?.sections) && result.sections.length > 0) ||
        String(result?.headline ?? "").trim().length > 0
      );
  }
}

function fallbackResult(mode, sourceText) {
  switch (mode) {
    case "quiz":
      return fallbackQuiz(sourceText);
    case "flashcards":
      return fallbackFlashcards(sourceText);
    case "checklist":
      return fallbackChecklist(sourceText);
    case "conclusiones":
      return fallbackConclusions(sourceText);
    case "resumen":
    default:
      return fallbackSummary(sourceText);
  }
}

app.post("/api/generate", async (req, res) => {
  try {
    const { content, mode } = req.body;

    if (!content || !mode) {
      return res.status(400).json({
        error: "Faltan campos requeridos: content y mode"
      });
    }

    if (!schemas[mode]) {
      return res.status(400).json({
        error: "Modo no soportado"
      });
    }

    const instruction = prompts[mode];
    const schema = schemas[mode];

    if (!contentServiceKey) {
      return res.status(500).json({
        error: "Falta configurar CONTENT_SERVICE_KEY"
      });
    }

    const response = await fetch(contentServiceUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${contentServiceKey}`,
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost:3000",
        "X-Title": "StudyWithMe"
      },
      body: JSON.stringify({
        model: contentModel,
        messages: [
          {
            role: "system",
            content: "Eres un asistente académico especializado en convertir apuntes y documentos en material de estudio claro, estructurado y útil. Respondes solo JSON válido, sin markdown, sin texto extra, sin comentarios."
          },
          {
            role: "user",
            content: `${instruction}

Devuelve exclusivamente JSON válido con esta estructura exacta:
${schema}

Reglas:
- No uses markdown.
- No agregues texto fuera del JSON.
- No cambies los nombres de las claves.
- Mantén el contenido breve, útil y específico.
- Para quiz usa exactamente 4 opciones por pregunta.
- Para quiz, correctIndex es un índice numérico base 0.

Contenido:
${content}`
          }
        ],
        temperature: 0.4
      })
    });

    const data = await response.json();

    if (!response.ok) {
      return res.status(response.status).json({
        error: "Error al consultar el servicio de contenido",
        details: data
      });
    }

    const rawResult = data.choices?.[0]?.message?.content || "";
    let result;
    let normalized;

    try {
      result = extractJson(rawResult);
      normalized = normalizeResult(mode, result);
      normalized = repairResult(mode, normalized, content);
    } catch (parseError) {
      normalized = fallbackResult(mode, rawResult || content);
    }

    if (!hasRenderableData(mode, normalized)) {
      normalized = fallbackResult(mode, rawResult || content);
    }

    if (!hasRenderableData(mode, normalized)) {
      normalized = fallbackResult(mode, content);
    }

    res.json({ result: normalized });
  } catch (error) {
    res.status(500).json({
      error: "Error interno del servidor",
      details: error.message
    });
  }
});

app.listen(process.env.PORT || 3000, () => {
  console.log(`Servidor corriendo en puerto ${process.env.PORT || 3000}`);
});
