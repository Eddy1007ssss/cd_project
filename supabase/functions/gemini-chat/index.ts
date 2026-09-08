import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type JsonRecord = Record<string, unknown>;
type SupabaseClient = ReturnType<typeof createClient>;

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function isRecord(value: unknown): value is JsonRecord {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function nestedRecord(value: unknown): JsonRecord | null {
  if (isRecord(value)) return value;
  return Array.isArray(value) && isRecord(value[0]) ? value[0] : null;
}

function text(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

function providerError(data: unknown, fallback: string) {
  if (!isRecord(data)) return text(data) || fallback;
  const nested = data.error;
  if (isRecord(nested) && text(nested.message)) return text(nested.message);
  return text(data.message) || fallback;
}

function providerReply(data: unknown) {
  if (!isRecord(data) || !Array.isArray(data.candidates)) return "";
  const parts: string[] = [];
  for (const candidate of data.candidates) {
    if (!isRecord(candidate)) continue;
    const content = nestedRecord(candidate.content);
    if (!content || !Array.isArray(content.parts)) continue;
    for (const part of content.parts) {
      if (isRecord(part) && text(part.text)) parts.push(text(part.text));
    }
  }
  return parts.join("\n").trim();
}

function actionReply(language: string, stage: string) {
  const english: Record<string, string> = {
    attraction: "Please choose an attraction.",
    category: "Choose a complaint category.",
    booking: "Choose the related booking, or select no booking.",
    description: "Choose the option that best describes the issue.",
    additionalDetails: "Add any extra details, if needed.",
    photoChoice: "Would you like to attach a photo?",
    slot: "Choose an available time slot.",
    visitors: "Choose the number of visitors.",
    ready: "Review the details before continuing.",
    cancelled: "The action has been cancelled.",
    complete: "The booking action has been recorded.",
  };
  const translated: Record<string, Record<string, string>> = {
    "Bahasa Malaysia": {
      attraction: "Sila pilih tarikan.", category: "Pilih kategori aduan.",
      booking: "Pilih tempahan berkaitan, atau pilih tiada tempahan.",
      description: "Pilih isu yang paling sesuai.",
      additionalDetails: "Tambah maklumat lanjut jika perlu.",
      photoChoice: "Adakah anda mahu melampirkan gambar?",
      slot: "Pilih slot masa yang tersedia.", visitors: "Pilih bilangan pelawat.",
      ready: "Semak butiran sebelum meneruskan.",
      cancelled: "Tindakan telah dibatalkan.", complete: "Tindakan tempahan telah direkodkan.",
    },
    Mandarin: {
      attraction: "请选择景点。", category: "请选择投诉类别。",
      booking: "请选择相关预订，或选择没有预订。", description: "请选择最符合的情况。",
      additionalDetails: "如有需要，请添加更多详情。", photoChoice: "您要附上照片吗？",
      slot: "请选择可用时段。", visitors: "请选择访客人数。",
      ready: "请确认详情后继续。", cancelled: "操作已取消。", complete: "预订操作已记录。",
    },
    Japanese: {
      attraction: "観光地を選択してください。", category: "苦情のカテゴリーを選択してください。",
      booking: "関連する予約を選択するか、予約なしを選んでください。",
      description: "最も近い問題を選択してください。", additionalDetails: "必要であれば詳細を追加してください。",
      photoChoice: "写真を添付しますか？", slot: "利用可能な時間枠を選択してください。",
      visitors: "人数を選択してください。", ready: "内容を確認して続行してください。",
      cancelled: "操作をキャンセルしました。", complete: "予約操作を記録しました。",
    },
    Korean: {
      attraction: "관광지를 선택해 주세요.", category: "불만 유형을 선택해 주세요.",
      booking: "관련 예약을 선택하거나 예약 없음을 선택해 주세요.",
      description: "가장 알맞은 문제를 선택해 주세요.", additionalDetails: "필요하면 세부 정보를 추가해 주세요.",
      photoChoice: "사진을 첨부하시겠습니까?", slot: "가능한 시간대를 선택해 주세요.",
      visitors: "방문객 수를 선택해 주세요.", ready: "계속하기 전에 내용을 확인해 주세요.",
      cancelled: "작업이 취소되었습니다.", complete: "예약 작업이 기록되었습니다.",
    },
  };
  return (translated[language] ?? english)[stage] ?? english[stage] ?? english.ready;
}

function complaintMissing(draft: JsonRecord) {
  if (!text(draft.attractionId)) return ["attraction"];
  if (!text(draft.category)) return ["category"];
  if (!text(draft.bookingId) && draft.bookingNotApplicable !== true) return ["booking"];
  if (!text(draft.baseDescription)) return ["description"];
  if (draft.additionalDetailsComplete !== true) return ["additionalDetails"];
  if (typeof draft.wantsPhoto !== "boolean") return ["photoChoice"];
  return [];
}

function finalizeComplaint(draft: JsonRecord) {
  const base = text(draft.baseDescription);
  const details = text(draft.additionalDetails);
  draft.description = details ? `${base}\n\nAdditional details: ${details}` : base;
  draft.missingFields = complaintMissing(draft);
  return draft;
}

async function complaintDraftFor(
  client: SupabaseClient,
  current: JsonRecord | null,
  action: JsonRecord,
) {
  const type = text(action.type);
  if (type === "cancel") return null;
  let draft: JsonRecord = type === "start" || !current
    ? {
      attractionId: null, attractionName: null, category: null,
      bookingId: null, bookingCode: null, bookingNotApplicable: false,
      baseDescription: null, additionalDetails: null,
      additionalDetailsComplete: false, description: null, wantsPhoto: null,
      bookingOptions: [],
    }
    : { ...current };
  const value = text(action.value);

  if (type === "select_attraction") {
    const { data, error } = await client.from("attractions").select("id,name")
      .eq("id", value).eq("listing_status", "approved").maybeSingle();
    if (error || !data) throw new Error("The selected attraction is unavailable.");
    draft = {
      ...draft, attractionId: data.id, attractionName: data.name,
      category: null, bookingId: null, bookingCode: null,
      bookingNotApplicable: false,
    };
  } else if (type === "select_category") {
    draft.category = value;
  } else if (type === "select_booking") {
    const { data, error } = await client.from("bookings")
      .select("id,booking_code,slot:attraction_slots!inner(attraction_id)")
      .eq("id", value).maybeSingle();
    const slot = nestedRecord(data?.slot);
    if (error || !data || !slot || slot.attraction_id !== draft.attractionId) {
      throw new Error("The selected booking does not match this attraction.");
    }
    draft.bookingId = data.id;
    draft.bookingCode = data.booking_code;
    draft.bookingNotApplicable = false;
  } else if (type === "no_booking") {
    draft.bookingId = null;
    draft.bookingCode = null;
    draft.bookingNotApplicable = true;
  } else if (type === "select_issue" || type === "set_custom_issue") {
    draft.baseDescription = value;
  } else if (type === "set_additional_details") {
    draft.additionalDetails = value;
    draft.additionalDetailsComplete = true;
  } else if (type === "skip_additional_details") {
    draft.additionalDetails = null;
    draft.additionalDetailsComplete = true;
  } else if (type === "photo_yes" || type === "photo_no") {
    draft.wantsPhoto = type === "photo_yes";
  }
  return finalizeComplaint(draft);
}

async function attractionOptions(client: SupabaseClient) {
  const { data, error } = await client.from("attractions").select("id,name")
    .eq("listing_status", "approved").order("name").limit(30);
  if (error) throw error;
  return (data ?? []).map((row) => ({ id: row.id, name: row.name }));
}

async function bookingOptions(client: SupabaseClient) {
  const { data, error } = await client.from("bookings").select(
    "id,booking_code,visitor_count,status,slot:attraction_slots!inner(id,starts_at,ends_at,attraction_id,attraction:attractions!inner(id,name))",
  ).eq("status", "confirmed").order("created_at", { ascending: false }).limit(30);
  if (error) throw error;
  return (data ?? []).map((row) => {
    const slot = nestedRecord(row.slot) ?? {};
    const attraction = nestedRecord(slot.attraction) ?? {};
    return {
      id: row.id, code: row.booking_code, attractionId: slot.attraction_id,
      attractionName: attraction.name ?? "Attraction", slotId: slot.id,
      startsAt: slot.starts_at, endsAt: slot.ends_at,
      visitorCount: row.visitor_count, status: row.status,
    };
  });
}

async function slotOptions(
  client: SupabaseClient,
  attractionId: string,
  excludedSlotId = "",
) {
  let query = client.from("attraction_slots").select(
    "id,attraction_id,starts_at,ends_at,maximum_capacity,reserved_capacity,attraction:attractions!inner(name)",
  ).eq("attraction_id", attractionId).eq("status", "open")
    .gt("starts_at", new Date().toISOString()).order("starts_at").limit(30);
  if (excludedSlotId) query = query.neq("id", excludedSlotId);
  const { data, error } = await query;
  if (error) throw error;
  return (data ?? []).map((row) => {
    const attraction = nestedRecord(row.attraction) ?? {};
    return {
      id: row.id, attractionId: row.attraction_id,
      attractionName: attraction.name ?? "Attraction",
      startsAt: row.starts_at, endsAt: row.ends_at,
      remainingCapacity: Math.max(0, Number(row.maximum_capacity) - Number(row.reserved_capacity)),
    };
  }).filter((row) => row.remainingCapacity > 0);
}

async function bookingDraftFor(
  client: SupabaseClient,
  current: JsonRecord | null,
  action: JsonRecord,
) {
  const type = text(action.type);
  if (type === "cancel" || type === "complete") return null;
  const startedOperation = type === "start_reschedule"
    ? "reschedule"
    : type === "start_cancel" ? "cancel" : "create";
  const operation = type.startsWith("start_")
    ? startedOperation
    : text(current?.operation) || "create";
  let draft: JsonRecord = type.startsWith("start_") || type === "restart" || !current
    ? {
      operation, attractionId: null, attractionName: null,
      bookingId: null, bookingCode: null, slotId: null,
      slotStartsAt: null, slotEndsAt: null, visitorCount: null,
      attractionOptions: operation === "create" ? await attractionOptions(client) : [],
      bookingOptions: operation === "create" ? [] : await bookingOptions(client),
      slotOptions: [],
    }
    : { ...current };
  const value = text(action.value);

  if (type === "select_attraction" && operation === "create") {
    const options = Array.isArray(draft.attractionOptions) ? draft.attractionOptions : [];
    const selected = options.find((item) => isRecord(item) && item.id === value);
    if (!isRecord(selected)) throw new Error("The selected attraction is unavailable.");
    draft.attractionId = value;
    draft.attractionName = selected.name;
    draft.slotOptions = await slotOptions(client, value);
    draft.slotId = null;
    draft.visitorCount = null;
  } else if (type === "select_booking" && operation !== "create") {
    const options = Array.isArray(draft.bookingOptions) ? draft.bookingOptions : [];
    const selected = options.find((item) => isRecord(item) && item.id === value);
    if (!isRecord(selected)) throw new Error("The selected booking is unavailable.");
    draft.bookingId = selected.id;
    draft.bookingCode = selected.code;
    draft.attractionId = selected.attractionId;
    draft.attractionName = selected.attractionName;
    draft.visitorCount = selected.visitorCount;
    if (operation === "reschedule") {
      draft.slotOptions = await slotOptions(
        client, text(selected.attractionId), text(selected.slotId),
      );
      draft.slotId = null;
      draft.slotStartsAt = null;
      draft.slotEndsAt = null;
    }
  } else if (type === "select_slot") {
    const options = Array.isArray(draft.slotOptions) ? draft.slotOptions : [];
    const selected = options.find((item) => isRecord(item) && item.id === value);
    if (!isRecord(selected)) throw new Error("The selected slot is unavailable.");
    draft.slotId = selected.id;
    draft.slotStartsAt = selected.startsAt;
    draft.slotEndsAt = selected.endsAt;
    } else if (type === "set_visitors") {
      const count = Number(value);
      const options = Array.isArray(draft.slotOptions) ? draft.slotOptions : [];
      const selected = options.find(
        (item) => isRecord(item) && item.id === draft.slotId,
      );
      const remaining = isRecord(selected)
        ? Number(selected.remainingCapacity)
        : 0;
      const maximum = Math.min(6, Math.max(0, remaining));
      if (!Number.isInteger(count) || count < 1 || count > maximum) {
        throw new Error(
          maximum > 0
            ? `Visitor count must be between 1 and ${maximum}.`
            : "The selected slot no longer has available capacity.",
        );
      }
    draft.visitorCount = count;
  }

  const missing: string[] = [];
  if (operation === "create" && !text(draft.attractionId)) missing.push("attraction");
  if (operation !== "create" && !text(draft.bookingId)) missing.push("booking");
  if (operation !== "cancel" && text(draft.attractionId) && !text(draft.slotId)) missing.push("slot");
  if (operation === "create" && text(draft.slotId) && !draft.visitorCount) missing.push("visitors");
  draft.missingFields = missing;
  return draft;
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return jsonResponse({ error: "Method not allowed" }, 405);
  const authorization = request.headers.get("authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) {
    return jsonResponse({ error: "Authentication required" }, 401);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim() ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")?.trim() ?? "";
    if (!supabaseUrl || !anonKey) {
      return jsonResponse({ error: "Supabase function environment is incomplete" }, 500);
    }
    const client = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
    });
    const { data: authData, error: authError } = await client.auth.getUser();
    if (authError || !authData.user) return jsonResponse({ error: "Authentication required" }, 401);

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return jsonResponse({ error: "Request body must be valid JSON" }, 400);
    }
    if (!isRecord(body)) return jsonResponse({ error: "Request body must be a JSON object" }, 400);
    const message = text(body.message);
    const language = text(body.language) || "English";
    if (!message) return jsonResponse({ error: "Message is required" }, 400);
    if (message.length > 2000) return jsonResponse({ error: "Message must not exceed 2,000 characters" }, 400);

    let conversation: JsonRecord;
    const requestedId = text(body.conversationId);
    if (requestedId) {
      const { data, error } = await client.from("chat_conversations").select("*")
        .eq("id", requestedId).eq("user_id", authData.user.id).maybeSingle();
      if (error) throw error;
      if (!data) return jsonResponse({ error: "Conversation not found" }, 404);
      conversation = data;
    } else {
      const title = message.length > 80 ? `${message.slice(0, 77)}...` : message;
      const { data, error } = await client.from("chat_conversations").insert({
        user_id: authData.user.id, title, language,
        last_message_preview: message.slice(0, 300),
      }).select("*").single();
      if (error) throw error;
      conversation = data;
    }

    let complaintDraft = isRecord(conversation.complaint_draft) ? conversation.complaint_draft : null;
    let bookingDraft = isRecord(conversation.booking_action_draft) ? conversation.booking_action_draft : null;
    let reply = "";

    if (isRecord(body.complaintAction)) {
      complaintDraft = await complaintDraftFor(client, complaintDraft, body.complaintAction);
      bookingDraft = null;
      const missing = complaintDraft && Array.isArray(complaintDraft.missingFields)
        ? text(complaintDraft.missingFields[0]) : "";
      reply = actionReply(language, complaintDraft ? missing || "ready" : "cancelled");
    } else if (isRecord(body.bookingAction)) {
      const actionType = text(body.bookingAction.type);
      bookingDraft = await bookingDraftFor(client, bookingDraft, body.bookingAction);
      complaintDraft = null;
      const missing = bookingDraft && Array.isArray(bookingDraft.missingFields)
        ? text(bookingDraft.missingFields[0]) : "";
      reply = actionReply(
        language,
        actionType === "complete" ? "complete" : bookingDraft ? missing || "ready" : "cancelled",
      );
    } else {
      const apiKey = Deno.env.get("GEMINI_API_KEY")?.trim();
      if (!apiKey) return jsonResponse({ error: "GEMINI_API_KEY is not configured in Supabase Secrets" }, 500);
      const { data: recent } = await client.from("chat_messages")
        .select("sender,content").eq("conversation_id", conversation.id)
        .order("sequence_number", { ascending: false }).limit(8);
      const history = (recent ?? []).reverse().map((entry) => ({
        role: entry.sender === "assistant" ? "model" : "user",
        parts: [{ text: entry.content }],
      }));
      const providerResponse = await fetch(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent",
        {
          method: "POST",
          headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
          body: JSON.stringify({
            systemInstruction: { parts: [{ text: `You are the TourFlow tourist assistant. Help with attractions, transport, visitor guidance, bookings and support. Reply in ${language}. Be friendly and concise. Never invent live crowd levels, availability, prices, or personal booking data. Direct users to the relevant TourFlow page when current data is unavailable.` }] },
            contents: [...history, { role: "user", parts: [{ text: message }] }],
            generationConfig: { maxOutputTokens: 600 },
          }),
        },
      );
      const raw = await providerResponse.text();
      let responseData: unknown = raw;
      try {
        responseData = raw ? JSON.parse(raw) : raw;
      } catch {
        // Preserve plain text provider errors.
      }
      if (!providerResponse.ok) {
        return jsonResponse({ error: providerError(responseData, "Gemini request failed") }, providerResponse.status);
      }
      reply = providerReply(responseData);
      if (!reply) return jsonResponse({ error: "Gemini returned an empty response" }, 502);
    }

    const { error: messageError } = await client.from("chat_messages").insert([
      { conversation_id: conversation.id, sender: "user", content: message },
      { conversation_id: conversation.id, sender: "assistant", content: reply },
    ]);
    if (messageError) throw messageError;
    const { error: updateError } = await client.from("chat_conversations").update({
      language, last_message_preview: reply.slice(0, 300),
      last_message_at: new Date().toISOString(),
      complaint_draft: complaintDraft, booking_action_draft: bookingDraft,
    }).eq("id", conversation.id).eq("user_id", authData.user.id);
    if (updateError) throw updateError;

    return jsonResponse({
      reply, conversationId: conversation.id, complaintDraft, bookingDraft,
    });
  } catch (error: unknown) {
    console.error("Edge Function error", error);
    return jsonResponse({
      error: error instanceof Error ? error.message : "Unexpected server error",
    }, 500);
  }
});
