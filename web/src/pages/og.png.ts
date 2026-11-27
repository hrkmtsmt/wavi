import type { APIRoute } from "astro";
import { ogPng } from "../images";

export const GET: APIRoute = async () => new Response(new Uint8Array(await ogPng()));
