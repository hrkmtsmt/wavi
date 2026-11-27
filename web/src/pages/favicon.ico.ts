import type { APIRoute } from "astro";
import { faviconIco } from "../images";

export const GET: APIRoute = async () => new Response(new Uint8Array(await faviconIco()));
