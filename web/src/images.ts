/** Builds the favicons and the social preview image from the Logo component at build time, so they never drift from the header icon. The endpoints in src/pages call these. */
import { readFile } from "node:fs/promises";
import { createRequire } from "node:module";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import satori from "satori";
import sharp from "sharp";
import { Logo } from "./components/Logo";

export function logoSvg(size: number): string {
  return renderToStaticMarkup(createElement(Logo, { size }));
}

export async function logoPng(size: number): Promise<Buffer> {
  return sharp(Buffer.from(logoSvg(size))).png().toBuffer();
}

/** A 32px favicon.ico for browsers that ask for /favicon.ico before reading the page: an ICO file holding one PNG image. */
export async function faviconIco(): Promise<Buffer> {
  const png = await logoPng(32);
  const header = Buffer.alloc(6 + 16);
  header.writeUInt16LE(0, 0); // reserved
  header.writeUInt16LE(1, 2); // type: icon
  header.writeUInt16LE(1, 4); // one image
  header.writeUInt8(32, 6); // width
  header.writeUInt8(32, 7); // height
  header.writeUInt8(0, 8); // no palette
  header.writeUInt8(0, 9); // reserved
  header.writeUInt16LE(1, 10); // color planes
  header.writeUInt16LE(32, 12); // bits per pixel
  header.writeUInt32LE(png.length, 14); // image size
  header.writeUInt32LE(6 + 16, 18); // image offset
  return Buffer.concat([header, png]);
}

/** 1200×630, the size Open Graph and X's large summary card both crop well: the icon and "Wavi" on the left, on the light page color. It has no other words, so one image serves every language. */
export async function ogPng(): Promise<Buffer> {
  const require = createRequire(import.meta.url);
  const font = await readFile(require.resolve("@fontsource/jetbrains-mono/files/jetbrains-mono-latin-700-normal.woff"));
  const icon = `data:image/png;base64,${(await logoPng(160)).toString("base64")}`;
  const svg = await satori(
    createElement(
      "div",
      {
        style: {
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          gap: 40,
          padding: "0 120px",
          background: "#f6f6f7",
          color: "#1c1c1e",
          fontFamily: "JetBrains Mono",
          fontSize: 120,
          fontWeight: 700,
        },
      },
      createElement("img", { src: icon, width: 160, height: 160 }),
      "Wavi",
    ),
    { width: 1200, height: 630, fonts: [{ name: "JetBrains Mono", data: font, weight: 700, style: "normal" }] },
  );
  return sharp(Buffer.from(svg)).png().toBuffer();
}
