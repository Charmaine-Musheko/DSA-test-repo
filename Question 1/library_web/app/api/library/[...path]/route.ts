const DEFAULT_API = "http://127.0.0.1:8080/library";

async function forward(request: Request, context: { params: Promise<{ path: string[] }> }) {
  const { path } = await context.params;
  const baseUrl = (process.env.LIBRARY_API_URL || DEFAULT_API).replace(/\/$/, "");
  const target = `${baseUrl}/${path.map(encodeURIComponent).join("/")}`;
  try {
    const response = await fetch(target, {
      method: request.method,
      headers: request.headers.get("content-type") ? { "Content-Type": request.headers.get("content-type") as string } : undefined,
      body: request.method === "GET" || request.method === "HEAD" ? undefined : await request.text(),
    });
    return new Response(await response.arrayBuffer(), { status: response.status, headers: { "Content-Type": response.headers.get("content-type") || "application/json" } });
  } catch {
    return Response.json({ message: "The Ballerina service is not running. Start library_service on port 8080." }, { status: 503 });
  }
}

export const GET = forward;
export const POST = forward;
export const PUT = forward;
export const DELETE = forward;
