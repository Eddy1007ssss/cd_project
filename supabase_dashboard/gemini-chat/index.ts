const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function getGeminiError(data: unknown, fallback: string) {
  if (!isRecord(data)) {
    return typeof data === "string" && data.trim().length > 0
      ? data
      : fallback;
  }

  const nestedError = data["error"];

  if (isRecord(nestedError)) {
    const nestedMessage = nestedError["message"];
    if (typeof nestedMessage === "string" && nestedMessage.trim().length > 0) {
      return nestedMessage;
    }
  }

  const topLevelMessage = data["message"];
  if (
    typeof topLevelMessage === "string" &&
    topLevelMessage.trim().length > 0
  ) {
    return topLevelMessage;
  }

  return fallback;
}

function getGeminiReply(data: unknown) {
  if (!isRecord(data)) return "";

  const candidates = data["candidates"];
  if (!Array.isArray(candidates)) return "";

  const textParts: string[] = [];

  for (const candidate of candidates) {
    if (!isRecord(candidate)) continue;

    const content = candidate["content"];
    if (!isRecord(content)) continue;

    const parts = content["parts"];
    if (!Array.isArray(parts)) continue;

    for (const part of parts) {
      if (!isRecord(part)) continue;

      const text = part["text"];
      if (typeof text === "string" && text.trim().length > 0) {
        textParts.push(text.trim());
      }
    }
  }

  return textParts.join("\n").trim();
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY")?.trim();

    if (!geminiApiKey) {
      return jsonResponse(
        { error: "GEMINI_API_KEY is not configured in Supabase Secrets" },
        500,
      );
    }

    let body: unknown;

    try {
      body = await request.json();
    } catch {
      return jsonResponse({ error: "Request body must be valid JSON" }, 400);
    }

    if (!isRecord(body)) {
      return jsonResponse({ error: "Request body must be a JSON object" }, 400);
    }

    const messageValue = body["message"];
    const languageValue = body["language"];

    const message =
      typeof messageValue === "string" ? messageValue.trim() : "";
    const language =
      typeof languageValue === "string" && languageValue.trim().length > 0
        ? languageValue.trim()
        : "English";

    if (message.length === 0) {
      return jsonResponse({ error: "Message is required" }, 400);
    }

    if (message.length > 2000) {
      return jsonResponse(
        { error: "Message must not exceed 2,000 characters" },
        400,
      );
    }

    const systemPrompt = `You are the TourFlow tourist assistant.

Help tourists with attractions, opening hours, facilities, transportation,
bookings, available time slots, visitor guidelines, live crowd information,
enquiries, and complaints.

Reply in ${language}. Keep answers friendly, concise, and easy to understand.

Never invent live crowd levels, booking availability, ticket prices, or
personal booking information. If current system information is not provided,
say that it cannot be verified and direct the tourist to the relevant TourFlow
page or support ticket.`;

    const geminiResponse = await fetch(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": geminiApiKey,
        },
        body: JSON.stringify({
          systemInstruction: {
            parts: [{ text: systemPrompt }],
          },
          contents: [
            {
              role: "user",
              parts: [{ text: message }],
            },
          ],
          generationConfig: {
            maxOutputTokens: 600,
          },
        }),
      },
    );

    const rawResponse = await geminiResponse.text();
    let responseData: unknown = rawResponse;

    if (rawResponse.trim().length > 0) {
      try {
        responseData = JSON.parse(rawResponse);
      } catch {
        // Keep the original text so the response still contains useful details.
      }
    }

    if (!geminiResponse.ok) {
      console.error("Gemini API error", geminiResponse.status, responseData);

      return jsonResponse(
        {
          error: getGeminiError(responseData, "Gemini request failed"),
          geminiStatus: geminiResponse.status,
          details: responseData,
        },
        geminiResponse.status,
      );
    }

    const reply = getGeminiReply(responseData);

    if (reply.length === 0) {
      return jsonResponse(
        {
          error: "Gemini returned an empty response",
          geminiStatus: geminiResponse.status,
          details: responseData,
        },
        502,
      );
    }

    return jsonResponse({
      reply,
      interactionId: null,
    });
  } catch (error: unknown) {
    console.error("Edge Function error", error);

    return jsonResponse(
      {
        error: error instanceof Error ? error.message : "Unexpected server error",
      },
      500,
    );
  }
});
