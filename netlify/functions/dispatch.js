// netlify/functions/dispatch.js
// Recibe el despacho desde el navegador (mismo origen que el sitio,
// así que no hay bloqueo CORS) y lo reenvía al servidor real de
// FlightHub 2.

const ALLOWED_REGIONS = new Set(["us", "eu"]);

exports.handler = async (event) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, X-User-Token, x-project-uuid",
  };

  if (event.httpMethod === "OPTIONS") {
    return { statusCode: 204, headers: corsHeaders, body: "" };
  }

  if (event.httpMethod !== "POST") {
    return {
      statusCode: 404,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      body: JSON.stringify({ error: "usar POST /dispatch" }),
    };
  }

  const params = event.queryStringParameters || {};
  let region = (params.region || "us").toLowerCase();
  if (!ALLOWED_REGIONS.has(region)) region = "us";

  const target = `https://es-flight-api-${region}.djigate.com/openapi/v0.1/workflow`;
  const token = event.headers["x-user-token"] || event.headers["X-User-Token"] || "";
  const projectUuid = event.headers["x-project-uuid"] || "";

  try {
    const resp = await fetch(target, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-User-Token": token,
        "x-project-uuid": projectUuid,
      },
      body: event.body,
    });
    const text = await resp.text();
    return {
      statusCode: resp.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      body: text,
    };
  } catch (e) {
    return {
      statusCode: 502,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      body: JSON.stringify({ error: `No se pudo contactar a FlightHub 2: ${e.message}` }),
    };
  }
};
