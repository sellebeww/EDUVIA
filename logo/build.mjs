// Copyright (c) 2026 Vassel Goleyu. All rights reserved.
// Generates every EDUVIA logo variant from one source of truth.
// Run: node logo/build.mjs   (writes SVGs next to this file)
import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const OUT = dirname(fileURLToPath(import.meta.url));

const THEMES = {
  // for dark backgrounds
  dark: {
    ink: "#F4F7FF", tri: "#4A78FF", star: "#EAF2FF",
    blade: ["#FFFFFF", "#8FB4FF"], p1: ["#B7D3FF", "#5B8CFF"], p2: ["#5B7FFF", "#2A3FD6"],
    ring: ["#4C7BFF", "#B9D2FF"],
  },
  // for light backgrounds
  light: {
    ink: "#0A1236", tri: "#3D6BFF", star: "#3D6BFF",
    blade: ["#7FA9FF", "#2F55F0"], p1: ["#8DB8FF", "#4672F5"], p2: ["#3F63F5", "#1B2CB0"],
    ring: ["#1B2CB0", "#4672F5"],
  },
};

// Letters (cap height 80, stroke 18). Stroked letters share one rounded-join look;
// V and A are clipped so their ends are cut flat, like a real extended sans.
const LETTERS = [
  { x: 0, svg: `<path d="M65 9H9V71H65M9 40H58"/>` },
  { x: 92, svg: `<path d="M9 9H55A24 24 0 0 1 79 33V47A24 24 0 0 1 55 71H9Z"/>` },
  { x: 198, svg: `<path d="M9 9V47A24 24 0 0 0 33 71H51A24 24 0 0 0 75 47V9"/>` },
  { x: 294, svg: `<g clip-path="url(#cut)"><path d="M4.7-10 50 71 95.3-10"/></g>` },
  { x: 406, svg: `<rect x="0" y="0" width="18" height="80" rx="4" fill="currentColor" stroke="none"/>` },
  {
    x: 436,
    svg: `<g clip-path="url(#cut)"><path d="M4.7 90 50 9 95.3 90"/></g>` +
         `<path class="tri" d="M50 52 34.3 80H65.7Z" fill="var(--tri)" stroke="var(--tri)" stroke-width="3" stroke-linejoin="round"/>`,
  },
];

const CSS = (animate) => `
  :root{--ink:INK;--tri:TRI}
  .ink{color:var(--ink)}
  .pg,.star,.tri,.ltr{transform-box:fill-box}
${animate ? `
  .pg{animation:pg .9s cubic-bezier(.22,1,.36,1) backwards}
  .p2{animation-delay:.05s}.p1{animation-delay:.2s}
  .tick{animation:draw .75s cubic-bezier(.65,0,.35,1) .55s backwards}
  .ring{animation:ring 1.3s cubic-bezier(.45,0,.2,1) 1s backwards}
  .ring.f{animation-delay:1.15s}
  .star{transform-origin:center;animation:pop .8s cubic-bezier(.34,1.56,.64,1) 1.75s backwards,twinkle 6s ease-in-out 4s infinite}
  .ltr{animation:rise .8s cubic-bezier(.22,1,.36,1) backwards;animation-delay:calc(1s + var(--i)*.07s)}
  .tri{transform-origin:50% 100%;animation:pop .6s cubic-bezier(.34,1.56,.64,1) 2.05s backwards}
  @keyframes pg{from{opacity:0;transform:translateX(-34px)}}
  @keyframes draw{from{stroke-dashoffset:1}}
  @keyframes ring{from{opacity:0;stroke-dasharray:1 1;stroke-dashoffset:1}to{opacity:1;stroke-dasharray:1 1;stroke-dashoffset:0}}
  @keyframes pop{from{opacity:0;transform:scale(.2) rotate(-90deg)}}
  @keyframes rise{from{opacity:0;transform:translateY(18px)}}
  @keyframes twinkle{0%,88%,100%{transform:none}94%{transform:scale(.78) rotate(45deg)}}
  @media (prefers-reduced-motion:reduce){svg *{animation:none!important}}
` : ""}`;

function make({ theme, animate, markOnly, icon }) {
  const t = THEMES[theme];
  const grad = (id, [a, b], dir = `x1="0" y1="0" x2="1" y2="1"`) =>
    `<linearGradient id="${id}" ${dir}><stop offset="0" stop-color="${a}"/><stop offset="1" stop-color="${b}"/></linearGradient>`;
  const ringStops = `<stop offset="0" stop-color="${t.ring[0]}" stop-opacity="0"/><stop offset=".3" stop-color="${t.ring[0]}"/><stop offset=".75" stop-color="${t.ring[1]}"/><stop offset="1" stop-color="${t.ring[1]}" stop-opacity="0"/>`;

  const ringAttrs = `fill="none" stroke="url(#gR)" stroke-width="3.5" stroke-linecap="round"`;
  const orbit = (cls, d) =>
    `<g transform="translate(150 170) rotate(-30)"><path class="ring ${cls}" pathLength="1" ${ringAttrs} d="${d}"/></g>`;

  const page = (cls, g, d) =>
    `<path class="pg ${cls}" fill="url(#${g})" stroke="url(#${g})" stroke-width="5" stroke-linejoin="round" d="${d}"/>`;

  const mark = `
  <g id="mark">
    ${icon ? "" : orbit("b", "M-150 0A150 48 0 0 1 150 0")}
    ${page("p1", "gP1", "M48 96C92 98 128 146 150 198V226C128 176 92 126 48 124Z")}
    ${page("p2", "gP2", "M30 132C82 134 124 190 150 236V258C122 214 82 164 30 160Z")}
    <path d="M262 48V112L150 258V198Z" fill="url(#gB)" stroke="url(#gB)" stroke-width="5" stroke-linejoin="round" mask="url(#mB)"/>
    ${icon ? "" : orbit("f", "M-150 0A150 48 0 0 0 150 0")}
    ${icon ? "" : `<path class="star" fill="${t.star}" d="M306 18C308 36 314 42 332 44 314 46 308 52 306 70 304 52 298 46 280 44 298 42 304 36 306 18Z"/>`}
  </g>`;

  const word = `
  <g id="word" class="ink" transform="translate(340 94) scale(1.5)" fill="none" stroke="currentColor" stroke-width="18" stroke-linejoin="round">
    ${LETTERS.map((l, i) => `<g transform="translate(${l.x} 0)"><g class="ltr" style="--i:${i}">${l.svg}</g></g>`).join("\n    ")}
  </g>`;

  const viewBox = icon === "app" ? "-34 -27 360 360" : icon ? "11 18 270 270" : markOnly ? "10 6 332 270" : "0 0 1162 282";
  const [, , w, h] = viewBox.split(" ").map(Number);

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}" width="${w}" height="${h}" role="img" aria-label="EDUVIA">
  <title>EDUVIA</title>
  <style>${CSS(animate).replace("INK", t.ink).replace("TRI", t.tri)}</style>
  <defs>
    ${grad("gB", t.blade, `x1="0" y1="0" x2=".35" y2="1"`)}
    ${grad("gP1", t.p1)}
    ${grad("gP2", t.p2)}
    <linearGradient id="gR" gradientUnits="userSpaceOnUse" x1="-150" y1="0" x2="150" y2="0">${ringStops}</linearGradient>
    <clipPath id="cut"><rect x="-10" y="0" width="120" height="80"/></clipPath>
    <mask id="mB" maskUnits="userSpaceOnUse" x="0" y="0" width="340" height="300">
      <path class="tick" d="M150 248 268 62" pathLength="1" stroke="#fff" stroke-width="170" stroke-dasharray="1" fill="none"/>
    </mask>
  </defs>${icon === "app" ? `<rect x="-34" y="-27" width="360" height="360" fill="#06091F"/>` : ""}${mark}${markOnly || icon ? "" : word}
</svg>
`;
}

for (const theme of ["dark", "light"]) {
  const suffix = theme === "dark" ? "" : "-light";
  writeFileSync(join(OUT, `eduvia-logo${suffix}.svg`), make({ theme, animate: true }));
  writeFileSync(join(OUT, `eduvia-logo${suffix}-static.svg`), make({ theme, animate: false }));
  writeFileSync(join(OUT, `eduvia-mark${suffix}.svg`), make({ theme, animate: false, markOnly: true }));
  writeFileSync(join(OUT, `eduvia-mark${suffix}-animated.svg`), make({ theme, animate: true, markOnly: true }));
}
// Favicon (transparent, readable on light and dark tabs) and iOS icon (solid navy).
writeFileSync(join(OUT, "favicon.svg"), make({ theme: "light", animate: false, markOnly: true, icon: "fav" }));
writeFileSync(join(OUT, "apple-touch-icon.svg"), make({ theme: "dark", animate: false, markOnly: true, icon: "app" }));
console.log("ok");
