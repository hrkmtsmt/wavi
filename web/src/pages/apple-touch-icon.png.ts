import type { APIRoute } from "astro";
import sharp from "sharp";
import { logoPng } from "../images";

// 180px, the size iOS uses for a home-screen icon. iOS fills transparent pixels with black, so the corners around the rounded tile are made white.
export const GET: APIRoute = async () => new Response(new Uint8Array(await sharp(await logoPng(180)).flatten({ background: "#ffffff" }).png().toBuffer()));
