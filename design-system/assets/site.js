/* Meridian design system: data and behaviour. Plain JS, no dependencies.
   Every app value below comes from the app's source at commit 7a4ec07. */
(function () {
  'use strict';
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
  const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const slug = (s) => String(s).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');

  /* ================================================================ logo */
  let uid = 0;
  const MERIDIANS = [22.28, 28.79, 38.52, 61.48, 71.21, 77.72];
  function logoInner(ink, star, id, faint = 0.32) {
    return `<defs><clipPath id="${id}"><circle cx="50" cy="56" r="30"/></clipPath></defs>` +
      `<g clip-path="url(#${id})" stroke="${ink}" stroke-opacity="${faint}" stroke-width="2.5" stroke-linecap="round" fill="none">` +
      MERIDIANS.map((x) => `<path d="M ${x} 20 V 92"/>`).join('') + '</g>' +
      `<path d="M 50 86 V 20" stroke="${ink}" stroke-width="3.5" stroke-linecap="round" fill="none"/>` +
      `<circle cx="50" cy="12" r="3.5" fill="${star || ink}"/>`;
  }
  function logoSVG({ size = 32, ink = 'currentColor', star = null, label = 'Meridian logo' } = {}) {
    const id = 'mlg' + (++uid);
    const a11y = label ? `role="img" aria-label="${esc(label)}"` : 'aria-hidden="true" focusable="false"';
    return `<svg viewBox="0 0 100 100" width="${size}" height="${size}" ${a11y}>${logoInner(ink, star, id)}</svg>`;
  }
  const GOLD = '#E9C46A';
  const ICONS = {
    dark: { bg: ['#1C1C1C', '#0D0D0E'], ink: '#F4EFE4', star: GOLD, label: 'default, gold star' },
    light: { bg: ['#FFFFFF', '#E6E6EA'], ink: '#1C1C1C', star: null, label: 'light' },
    mono: { bg: ['#1A1A1A', '#000000'], ink: '#FFFFFF', star: null, label: 'tinted, the mono source' },
    tinted: { bg: ['#1A1A1A', '#000000'], ink: '#A9C1EA', star: null, label: 'tinted, with an example tint' },
    indigo: { bg: ['#1D2547', '#0C0F1D'], ink: '#F4EFE4', star: null, label: 'night indigo, not chosen' },
  };
  function iconSVG(kind) {
    const k = ICONS[kind] || ICONS.dark; const g = 'mig' + (++uid); const c = 'mic' + (++uid);
    return `<svg viewBox="0 0 1024 1024" role="img" aria-label="Meridian app icon, ${esc(k.label)}">` +
      `<defs><radialGradient id="${g}" cx="0.5" cy="0.35" r="0.75"><stop offset="0" stop-color="${k.bg[0]}"/><stop offset="1" stop-color="${k.bg[1]}"/></radialGradient></defs>` +
      `<rect width="1024" height="1024" fill="url(#${g})"/>` +
      `<g transform="translate(202 219) scale(6.2)">${logoInner(k.ink, k.star, c)}</g></svg>`;
  }
  function construction() {
    const ink = '#F4EFE4';
    let s = '<svg viewBox="-14 -4 128 112" role="img" aria-label="How the Longitudes mark is built on a 100-unit grid">';
    for (let i = 0; i <= 100; i += 5) {
      const major = i % 10 === 0;
      s += `<path d="M ${i} 0 V 100 M 0 ${i} H 100" stroke="${ink}" stroke-opacity="${major ? 0.12 : 0.05}" stroke-width="${major ? 0.25 : 0.15}"/>`;
    }
    s += `<rect x="0" y="0" width="100" height="100" fill="none" stroke="${ink}" stroke-opacity=".3" stroke-width=".3"/>`;
    s += `<circle cx="50" cy="56" r="30" fill="none" stroke="${ink}" stroke-opacity=".5" stroke-width=".35" stroke-dasharray="1.2 1"/>`;
    s += `<path d="M 0 12 H 100 M 0 20 H 100 M 0 86 H 100 M 0 56 H 100" stroke="${ink}" stroke-opacity=".22" stroke-width=".25" stroke-dasharray=".8 .8"/>`;
    s += `<g font-family="ui-monospace, Menlo, monospace" font-size="2.8" fill="${ink}" fill-opacity=".7">`;
    [-3, -2, -1, 0, 1, 2, 3].forEach((k) => {
      const x = (50 + 30 * Math.sin((k * 22.5 * Math.PI) / 180)).toFixed(2);
      s += `<text x="${x}" y="${k % 2 ? 103.5 : 107.5}" text-anchor="middle">${x}</text>`;
    });
    s += '<text x="-1.5" y="13" text-anchor="end">12</text><text x="-1.5" y="21" text-anchor="end">20</text><text x="-1.5" y="57" text-anchor="end">56</text><text x="-1.5" y="87" text-anchor="end">86</text></g>';
    s += `<g color="${ink}">${logoInner('currentColor', null, 'mcs' + (++uid))}</g>`;
    s += `<g font-family="-apple-system, system-ui, sans-serif" font-size="3" fill="${ink}">` +
      '<text x="56" y="10">star r 3.5 at (50, 12)</text>' +
      '<text x="81" y="31">globe r 30</text><text x="81" y="34.5">at (50, 56)</text>' +
      '<text x="53" y="94">your meridian: stroke 3.5</text>' +
      '<text x="2" y="97.5">others: stroke 2.5, 32%</text></g></svg>';
    return s;
  }
  function renderLogos() {
    $$('[data-logo]').forEach((el) => {
      // The star is gold on night; on paper it stays ink, since gold on white is under 2:1.
      const star = el.closest('.paper') ? null : GOLD;
      el.innerHTML = logoSVG({ size: Number(el.dataset.size || 32), star, label: el.dataset.label === undefined ? 'Meridian logo' : el.dataset.label });
    });
    $$('[data-icon]').forEach((el) => { el.innerHTML = iconSVG(el.dataset.icon); });
    const c = $('#construction'); if (c) c.innerHTML = construction();
  }

  /* ================================================================ colour tokens */
  // [group id (keeps old anchors), key, label, css, hex, cssVar, swift (copyable), use, base]
  const TOKENS = {
    text: [
      ['night-ink', 'Primary', 'Primary, app', '#FFFFFF', '#FFFFFF', '--night-ink-primary', 'NightInk.primary', 'Out line on the hero, Show detail and the show page', '#1C1C1C'],
      ['widget-ink', 'Primary', 'Primary, widgets', '#FFFFFF', '#FFFFFF', '--widget-primary', 'WidgetInk.primary', 'Titles, countdowns, tags, the empty headline', '#1C1C1C'],
      ['brand-gold', 'Gold', 'Meridian Gold', '#E9C46A', '#E9C46A', '--gold', 'Tokens.gold', 'Only the logo’s star and “Out now”, on night', '#1C1C1C'],
      ['la-ink', 'Primary', 'Primary, Live Activity', '#FFFFFF', '#FFFFFF', '--la-primary', 'LiveActivityInk.primary', 'Titles, the countdown, the monogram', '#0D0D0E'],
      ['night-ink', 'Secondary', 'Secondary, app', 'rgba(255,255,255,.75)', '#FFFFFFBF', '--night-ink-secondary', 'NightInk.secondary', 'Row out line, Show detail source sentence, Welcome zone line, “Not now”', '#1C1C1C'],
      ['widget-ink', 'Secondary', 'Secondary, widgets', 'rgba(255,255,255,.75)', '#FFFFFFBF', '--widget-secondary', 'WidgetInk.secondary', 'Out lines, empty detail, quiet row name, compact-row countdown', '#1C1C1C'],
      ['la-ink', 'Secondary', 'Secondary, Live Activity', 'rgba(255,255,255,.75)', '#FFFFFFBF', '--la-secondary', 'LiveActivityInk.secondary', 'The label “Expected in”, the time line, “+ 1 more”', '#0D0D0E'],
      ['night-ink', 'Muted', 'Muted, app', 'rgba(235,235,245,.6)', '#EBEBF599', '--night-ink-muted', 'NightInk.muted', 'Meta lines, section headers, labels, search messages. The system secondary label', '#1C1C1C'],
      ['widget-ink', 'Muted', 'Muted, widgets', 'rgba(255,255,255,.55)', '#FFFFFF8C', '--widget-muted', 'WidgetInk.muted', 'Compact row “when”, quiet row reason and “Nothing scheduled”', '#1C1C1C'],
      ['la-ink', 'Muted', 'Muted, Live Activity', 'rgba(255,255,255,.55)', '#FFFFFF8C', '--la-muted', 'LiveActivityInk.muted', 'Details “S2E5 · Apple TV”, the struck-through old time', '#0D0D0E'],
      ['widget-ink', 'Always-On dim', 'Always-On dim, widgets', 'rgba(255,255,255,.525)', '× 0.7', '--widget-always-on-factor', 'WidgetInk.dimmed', 'Always-On multiplies every ink except the countdown by 0.7. Secondary is shown', '#1C1C1C'],
    ],
    bases: [
      ['night-bases', 'Neutral night', 'Neutral night', '#1C1C1C', '#1C1C1C', '--night-neutral', 'ArtworkPalette.neutral.night', 'Before art loads, or with none; Search and Welcome'],
      ['widget-ink', 'Base', 'Widget base', '#1C1C1C', '#1C1C1C', '--widget-base', 'WidgetInk.base', 'The widget backdrop and its art fade'],
      ['la-ink', 'Base', 'Live Activity base', '#0D0D0E', '#0D0D0E', '--la-base', 'LiveActivityInk.base', 'Background tint and art edge. This site’s page colour'],
      ['night-bases', 'Palette base (neutral)', 'Art placeholder', '#525252', '#525252', '--art-base-neutral', 'ArtworkPalette.neutral.base', 'Row art before it loads'],
    ],
    art: [
      ['night-bases', 'Warm: red art', 'Red art, 0°', '#1C1A1A', '#1C1A1A', '--night-sample-red', '', 'Warm'],
      ['night-bases', 'Warm: orange art', 'Orange art, 30°', '#1C1B1A', '#1C1B1A', '--night-sample-orange', '', 'Warm'],
      ['night-bases', 'Warm: yellow art', 'Yellow art, 60°', '#1C1C1A', '#1C1C1A', '--night-sample-yellow', '', 'Warm'],
      ['night-bases', 'Cool: green art', 'Green art, 120°', '#182418', '#182418', '--night-sample-green', '', 'Cool'],
      ['night-bases', 'Cool: teal art', 'Teal art, 160°', '#182420', '#182420', '--night-sample-teal', '', 'Cool'],
      ['night-bases', 'Cool: blue art', 'Blue art, 210°', '#181E24', '#181E24', '--night-sample-blue', '', 'Cool'],
      ['night-bases', 'Cool: indigo art', 'Indigo art, 240°', '#181824', '#181824', '--night-sample-indigo', '', 'Cool'],
      ['night-bases', 'Cool: purple art', 'Purple art, 280°', '#201824', '#201824', '--night-sample-purple', '', 'Cool'],
    ],
    controls: [
      ['control-colours', 'Control fill', 'Control fill', 'rgba(0,0,0,.55)', '#0000008C', '--control-fill', 'Color.black.opacity(0.55)', 'Unpicked filter chip, the Follow (+) button', '#1C1C1C'],
      ['control-colours', 'Hairline', 'Hairline', 'rgba(255,255,255,.35)', '#FFFFFF59', '--control-hairline', 'Color.white.opacity(0.35)', 'Strokes on the unpicked chip, (+) and “Following”', '#1C1C1C'],
      ['control-colours', 'Following fill', 'Following fill', 'rgba(255,255,255,.12)', '#FFFFFF1F', '--following-fill', 'Color.white.opacity(0.12)', 'The “Following” capsule; the episode divider', '#1C1C1C'],
      ['control-colours', 'Episode ink', 'Episode ink', 'rgba(255,255,255,.6)', '#FFFFFF99', '--episode-ink', 'Color.white.opacity(0.6)', 'Episode label and date; the Live Activity toggle tint', '#1C1C1C'],
      ['control-colours', 'Tag fill', 'Widget tag fill', 'rgba(0,0,0,.45)', '#00000073', '--widget-tag-fill', 'Color.black.opacity(0.45)', 'The widget tag capsule over art', '#8C8C8C'],
      ['control-colours', 'Art scrim', 'Art scrim', 'rgba(0,0,0,.4)', '#00000066', '--art-scrim', 'Color.black.opacity(0.4)', 'Top of the art header, clear by 25%', '#8C8C8C'],
      ['control-colours', 'Picked / primary', 'Picked and primary', '#FFFFFF', '#FFFFFF', '--control-picked', 'Color.white', 'Picked chip, Following (+), Follow and Find a show, the tab tint. Text on it is black'],
    ],
    la: [
      ['la-ink', 'Fill', 'Fill', '#FFFFFF', '#FFFFFF', '--la-fill', 'LiveActivityInk.fill', 'Ring and bar fill', '#0D0D0E'],
      ['la-ink', 'Track', 'Track', 'rgba(255,255,255,.18)', '#FFFFFF2E', '--la-track', 'LiveActivityInk.track', 'Ring and bar track', '#0D0D0E'],
      ['la-ink', 'Disc', 'Disc', 'rgba(255,255,255,.16)', '#FFFFFF29', '--la-disc', 'LiveActivityInk.disc', 'The disc behind the monogram', '#0D0D0E'],
      ['la-ink', 'Keyline', 'Keyline', 'rgba(255,255,255,.35)', '#FFFFFF59', '--la-keyline', 'LiveActivityInk.keyline', 'The Dynamic Island outline', '#000000'],
      ['la-ink', 'Monogram ghost', 'Monogram ghost', 'rgba(255,255,255,.07)', '#FFFFFF12', '--la-monogram', 'LiveActivityInk.primary.opacity(0.07)', 'The faint large initial when there is no art', '#0D0D0E'],
    ],
    legacy: [
      ['legacy-status', 'Exact', 'Exact', '#5BE38A', '#17692A / #5BE38A', '--legacy-exact', 'Tokens.Ink.exact', 'Archived source chip'],
      ['legacy-status', 'Estimated', 'Estimated', '#8AB0FF', '#1F5FCC / #8AB0FF', '--legacy-estimated', 'Tokens.Ink.estimated', 'Archived source chip'],
      ['legacy-status', 'Adjusted', 'Adjusted', '#C9A6FF', '#7B3FC4 / #C9A6FF', '--legacy-adjusted', 'Tokens.Ink.adjusted', 'Archived source chip'],
      ['legacy-status', 'Date only', 'Date only', '#A8A8B0', '#5E5E66 / #A8A8B0', '--legacy-date-only', 'Tokens.Ink.dateOnly', 'Archived source chip'],
      ['legacy-status', 'Delayed', 'Delayed', '#FDBA74', '#96440A / #FDBA74', '--legacy-delayed', 'Tokens.Ink.delayed', 'Archived card row, “Delayed”'],
      ['legacy-status', 'No stream', 'No stream', '#FF8A80', '#B01F1F / #FF8A80', '--legacy-no-stream', 'Tokens.Ink.noStream', 'Archived service label'],
      ['night-bases', 'Palette accent', 'Palette accent', '#FFFFFF', '#FFFFFF', '--art-accent', 'ArtworkPalette.accent', 'Computed from the art, but read by no view'],
    ],
  };
  const copyBtn = (val, what, shown) => `<button class="copy-val" type="button" data-copy="${esc(val)}" aria-label="Copy ${what} ${esc(val)}">${esc(shown || val)}</button>`;
  function tokenRow([gid, key, label, css, hex, cssVar, swift, use, base]) {
    const id = 'color-' + slug(gid + '-' + key);
    const alpha = /rgba/.test(css);
    const chip = `<span class="chip${alpha && !base ? ' alpha' : ''}" style="${alpha && base ? 'background:' + base : ''}" aria-hidden="true"><i style="background:${css}"></i></span>`;
    const copyHex = hex.startsWith('#') && !hex.includes('/') ? hex : (hex.includes('/') ? hex.split(' / ')[1] : null);
    const btn = copyBtn;
    const vals = [copyHex ? btn(copyHex, 'hex', hex) : `<span class="copy-val">${esc(hex)}</span>`];
    if (swift) vals.push(btn(swift, 'Swift name'));
    vals.push(btn(`var(${cssVar})`, 'CSS variable', cssVar));
    const on = alpha && base ? ` Shown on ${base}.` : '';
    return `<li class="tok" id="${id}" data-search="${esc([label, key, swift, hex, cssVar, use, 'colour color'].join(' '))}" data-title="${esc(swift || label)}" data-kind="Colour" data-sub="${esc(hex)}">
      ${chip}<div><div class="name">${esc(label)}<button class="anchor-btn" type="button" data-link="${id}" aria-label="Copy a link to ${esc(label)}">#</button></div><div class="use">${esc(use)}.${on}</div></div>
      <div class="vals">${vals.join('')}</div></li>`;
  }
  // Text inks as a role × surface matrix: one row per strength, one column per surface.
  function renderInkMatrix() {
    const host = $('#tok-text'); if (!host) return;
    const surfaces = [['night-ink', 'App'], ['widget-ink', 'Widgets'], ['la-ink', 'Live Activity']];
    const roles = ['Primary', 'Secondary', 'Muted', 'Always-On dim'];
    const btn = copyBtn;
    let h = '<table class="inks"><thead><tr><th scope="col">Strength</th>' + surfaces.map(([, n]) => `<th scope="col">${n}</th>`).join('') + '</tr></thead><tbody>';
    roles.forEach((role) => {
      const rows = surfaces.map(([g]) => TOKENS.text.find((r) => r[0] === g && r[1] === role));
      const use = rows.filter(Boolean).map((r) => r[7]);
      h += `<tr><th scope="row">${esc(role)}<span class="role-use">${esc(use[0])}</span></th>`;
      rows.forEach((r, ri) => {
        if (!r) { h += '<td class="none">—</td>'; return; }
        const [gid, key, label, css, hex, cssVar, swift, , base] = r;
        const id = 'color-' + slug(gid + '-' + key);
        const copyHex = hex.startsWith('#') ? hex : null;
        h += `<td data-surface="${surfaces[ri][1]}"><div class="ink-cell" id="${id}" data-search="${esc([label, swift, hex, cssVar, r[7], 'colour color text ink'].join(' '))}" data-title="${esc(swift)}" data-kind="Colour" data-sub="${esc(hex)}">` +
          `<span class="chip" style="background:${base}" aria-hidden="true"><b style="color:${css}">Silo  2:10:07</b></span>` +
          `<div class="vals">${copyHex ? btn(copyHex, 'hex') : `<span class="copy-val">${esc(hex)}</span>`}${btn(swift, 'Swift name')}${btn('var(' + cssVar + ')', 'CSS variable', cssVar)}</div></div></td>`;
      });
      h += '</tr>';
    });
    host.outerHTML = `<div class="table-wrap" id="tok-text">${h}</tbody></table></div>`;
  }
  function renderTokens() {
    const put = (sel, rows, strip) => { const el = $(sel); if (!el) return; el.innerHTML = rows.map(tokenRow).join(''); if (strip) el.classList.add('strip'); };
    renderInkMatrix(); put('#tok-bases', TOKENS.bases); put('#tok-art', TOKENS.art, true);
    put('#tok-controls', TOKENS.controls); put('#tok-la', TOKENS.la); put('#tok-legacy', TOKENS.legacy);
  }

  /* ================================================================ contrast */
  function parseColor(c) {
    c = c.trim();
    if (c[0] === '#') { const h = c.slice(1); const n = (i) => parseInt(h.slice(i, i + 2), 16) / 255; return [n(0), n(2), n(4), h.length === 8 ? n(6) : 1]; }
    const p = c.match(/rgba?\(([^)]+)\)/)[1].split(',').map((x) => parseFloat(x));
    return [p[0] / 255, p[1] / 255, p[2] / 255, p[3] === undefined ? 1 : p[3]];
  }
  const over = (fg, bg) => [0, 1, 2].map((i) => fg[i] * fg[3] + bg[i] * (1 - fg[3])).concat(1);
  const lin = (c) => (c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4));
  const lum = (c) => 0.2126 * lin(c[0]) + 0.7152 * lin(c[1]) + 0.0722 * lin(c[2]);
  const ratio = (a, b) => { const la = lum(a), lb = lum(b); return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05); };
  const layered = (layers) => layers.reduce((acc, l) => (acc ? over(parseColor(l), acc) : parseColor(l)), null);
  const ROLES = [
    ['Primary', '#FFFFFF', 'app, widgets, Live Activity'],
    ['Secondary', 'rgba(255,255,255,.75)', 'app, widgets, Live Activity'],
    ['Muted (app)', 'rgba(235,235,245,.6)', 'the system secondary label'],
    ['Muted (widgets, Live Activity)', 'rgba(255,255,255,.55)', 'white at 55%'],
    ['Episode ink', 'rgba(255,255,255,.6)', 'episode label and date'],
    ['Always-On secondary', 'rgba(255,255,255,.525)', 'secondary × 0.7'],
    ['Always-On muted', 'rgba(255,255,255,.385)', 'muted × 0.7'],
  ];
  const BASES = [
    ['Neutral night', ['#1C1C1C']], ['Live Activity', ['#0D0D0E']], ['Blue night', ['#181E24']], ['Green night', ['#182418']],
    ['Purple night', ['#201824']], ['Warm night', ['#1C1A1A']], ['Settings cell', ['#1C1C1E']],
    ['Chip on night', ['#1C1C1C', 'rgba(0,0,0,.55)']], ['Tag on grey art', ['#8C8C8C', 'rgba(0,0,0,.45)']], ['Widget fade at 70% on light art', ['#CCCCCC', 'rgba(28,28,28,.7)']],
  ];
  // Which bases each role is actually drawn on. Only these count for the summary.
  const REAL = {
    'Primary': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 'Secondary': [0, 1, 2, 3, 4, 5, 9], 'Muted (app)': [0, 2, 3, 4, 5, 6],
    'Muted (widgets, Live Activity)': [0, 1, 9], 'Episode ink': [0, 2, 3, 4, 5], 'Always-On secondary': [0, 1], 'Always-On muted': [0, 1],
  };
  const grade = (r) => (r >= 7 ? 'AAA' : r >= 4.5 ? 'AA' : r >= 3 ? 'AA large only' : 'Fails');
  function renderContrast() {
    const host = $('#contrast-table'); if (!host) return;
    const real = []; let total = 0, pass = 0, aaa = 0;
    let h = '<table class="contrast"><caption class="sr-only">Contrast of each text role on each base</caption><thead><tr><th scope="col">Text role</th>' +
      BASES.map(([n]) => `<th scope="col">${esc(n)}</th>`).join('') + '</tr></thead><tbody>';
    ROLES.forEach(([name, css, src]) => {
      h += `<tr><th scope="row">${esc(name)}<span class="role-src">${esc(src)}</span></th>`;
      BASES.forEach(([bn, layers], bi) => {
        const b = layered(layers); const r = ratio(over(parseColor(css), b), b);
        const isReal = (REAL[name] || []).includes(bi);
        if (isReal) { total++; if (r >= 7) aaa++; if (r >= 4.5) pass++; else real.push({ r, role: name, base: bn }); }
        const bgCss = `rgb(${b.slice(0, 3).map((x) => Math.round(x * 255)).join(',')})`;
        h += `<td class="cell${isReal ? '' : ' unused'}"><span class="sample" aria-hidden="true" style="background:${bgCss};color:${css}">Aa 2:10</span><br><span class="ratio">${r.toFixed(2)}:1</span> <span class="grade">${isReal ? grade(r) : 'not used'}</span></td>`;
      });
      h += '</tr>';
    });
    host.innerHTML = h + '</tbody></table>';
    real.sort((a, b) => a.r - b.r);
    const list = real.map((p) => `${p.role} on ${p.base}, ${p.r.toFixed(2)}:1`).join('; ');
    const sum = $('#contrast-summary');
    if (sum) sum.textContent = real.length
      ? `${pass} of ${total} pairs the app draws pass AA. Below 4.5:1: ${list}. Always-On is the dimmed screen iOS shows when the phone is idle; the widget fade case is muted text where the fade is still only 70% opaque over very light art.`
      : `All ${total} pairs the app draws pass AA.`;
    const a = $('#a11y-contrast'), s = $('#a11y-contrast-status');
    if (a) a.innerHTML = `${pass} of ${total} text pairs the app draws pass AA, and ${aaa} of them pass AAA. The ${real.length} below 4.5:1 are listed under <a href="#contrast">Contrast</a>.`;
    if (s) s.textContent = real.length ? 'Mostly done' : 'Done';
    const pairs = [
      ['Picked chip, Follow, Find a show', '#000000', ['#FFFFFF']],
      ['Letter on the logo tile', '#1C1C1C', ['#FFFFFF']],
      ['Starlight on night', '#F4EFE4', ['#1C1C1C']],
      ['Gold on the widget night', '#E9C46A', ['#1C1C1C']],
      ['Gold on the Live Activity night', '#E9C46A', ['#0D0D0E']],
      ['System link blue on a Settings cell', '#0A84FF', ['#1C1C1E']],
    ];
    $('#contrast-pairs').innerHTML = '<table><thead><tr><th scope="col">Pair</th><th scope="col">Sample</th><th scope="col">Ratio</th><th scope="col">Grade</th></tr></thead><tbody>' + pairs.map(([n, fg, layers]) => {
      const r = ratio(parseColor(fg), layered(layers));
      return `<tr><td>${esc(n)}</td><td><span class="pair-sample" aria-hidden="true" style="background:${layers[0]};color:${fg}">Out now</span></td><td class="num">${r.toFixed(2)}:1</td><td>${grade(r)}</td></tr>`;
    }).join('') + '</tbody></table>';
  }

  /* ================================================================ type */
  // [role, surface, family, size, weight, numerals, where]
  const TYPE = [
    ['Hero countdown', 'App', 'serif', 88, 300, true, 'Upcoming hero, Show detail, the show page'],
    ['Welcome headline', 'App', 'serif', 34, 400, false, 'Welcome'],
    ['Hero title', 'App', 'serif', 32, 400, false, 'Headline title, spotlight, the show page'],
    ['Empty headline', 'App', 'serif', 28, 400, false, '“Follow a show…”, “Nothing scheduled…”'],
    ['Row countdown', 'App', 'serif', 24, 300, true, 'Upcoming row'],
    ['Grid section header', 'App', 'serif', 22, 400, false, '“Airing in the next few days”, “Results”'],
    ['Row title', 'App', 'serif', 20, 400, false, 'Upcoming row'],
    ['Out line (hero)', 'App', 'sans', 17, 500, false, 'Body medium: “Expected Wed at 23:00 Lagos time”'],
    ['Follow button', 'App', 'sans', 17, 600, false, 'Headline'],
    ['Episode title', 'App', 'sans', 17, 500, false, 'Body medium'],
    ['Out line (row)', 'App', 'sans', 15, 400, false, 'Subheadline, secondary'],
    ['List section header', 'App', 'sans', 15, 500, false, 'Subheadline medium, muted'],
    ['Filter chip', 'App', 'sans', 15, 500, false, 'Subheadline medium'],
    ['Meta / footnote', 'App', 'sans', 13, 400, false, 'Footnote, muted: “S4E1 · Apple TV”'],
    ['Grid cell title', 'App', 'sans', 13, 500, false, 'Footnote medium'],
    ['Episode label', 'App', 'sans', 13, 600, true, 'Footnote, tabular, semibold'],
    ['Grid cell meta', 'App', 'sans', 12, 400, false, 'Caption, muted'],
    ['Widget large countdown', 'Widget', 'serif', 46, 300, true, 'Large widget hero'],
    ['Small widget countdown', 'Widget', 'serif', 36, 300, true, 'Small widget'],
    ['Medium widget countdown', 'Widget', 'serif', 32, 300, true, 'Medium widget hero'],
    ['Large widget title', 'Widget', 'serif', 24, 400, false, 'Large widget hero'],
    ['Widget empty headline', 'Widget', 'serif', 22, 300, false, '“Follow a show”, “Nothing scheduled”'],
    ['Large row countdown', 'Widget', 'serif', 22, 300, true, 'Large-widget row'],
    ['Medium widget title', 'Widget', 'serif', 19, 400, false, 'Medium widget hero'],
    ['Small widget title', 'Widget', 'serif', 16, 400, false, 'Small widget'],
    ['Large / quiet row title', 'Widget', 'serif', 15, 400, false, 'Large-widget row, quiet row'],
    ['Compact row title', 'Widget', 'serif', 14, 400, false, 'Medium-widget row'],
    ['Large widget out line', 'Widget', 'sans', 13, 500, false, 'Large widget'],
    ['Widget out line', 'Widget', 'sans', 12, 500, false, 'Small and medium; empty detail'],
    ['Widget row “when” / reason', 'Widget', 'sans', 11, 500, false, 'Medium-widget row, quiet row'],
    ['Widget tag', 'Widget', 'sans', 11, 600, false, '“HBO · US”, “+3 more this week”'],
    ['Rectangular countdown', 'Lock Screen', 'serif', 26, 300, true, 'Rectangular'],
    ['Circular date-only day', 'Lock Screen', 'serif', 22, 400, true, 'Circular'],
    ['Rectangular title', 'Lock Screen', 'serif', 15, 600, false, 'Rectangular'],
    ['Circular value number', 'Lock Screen', 'serif', 14, 400, true, '“2” in “2d”'],
    ['Rectangular meta / provider', 'Lock Screen', 'sans', 12, 500, false, '“Expected Wed 23:00”'],
    ['Circular unit', 'Lock Screen', 'serif', 10, 400, true, '“d” in “2d”, secondary'],
    ['LA countdown (default)', 'Live Activity', 'serif', 44, 300, true, 'The countdown’s default size'],
    ['Lock banner countdown', 'Live Activity', 'serif', 36, 300, true, 'Lock Screen banner'],
    ['Expanded countdown / Out now', 'Live Activity', 'serif', 34, 300, true, 'Expanded island, bottom'],
    ['Small LA countdown', 'Live Activity', 'serif', 24, 300, true, 'Small family'],
    ['Lock banner title', 'Live Activity', 'serif', 19, 500, false, 'Lock Screen banner'],
    ['Expanded title', 'Live Activity', 'serif', 18, 500, false, 'Expanded island, leading'],
    ['Compact island timer', 'Live Activity', 'serif', 15, 500, true, 'Compact, trailing'],
    ['Expanded label', 'Live Activity', 'sans', 14, 600, false, '“Expected in”'],
    ['Lock label / details / time', 'Live Activity', 'sans', 13, 600, false, '“Expected in” semibold; details and time medium'],
    ['Small LA label / time', 'Live Activity', 'sans', 11, 600, false, 'Small family'],
  ];
  const W = { 300: 'Light', 400: 'Regular', 500: 'Medium', 600: 'Semibold' };
  const sampleFor = (r) => {
    if (/countdown|timer|Out now/i.test(r)) return '2:10:07';
    if (/value number|date-only day/.test(r)) return '11';
    if (/unit/.test(r)) return 'd';
    if (/Episode label/.test(r)) return 'S3E10';
    if (/when/.test(r)) return 'Expected Wed 23:00';
    if (/tag/i.test(r)) return 'HBO · US';
    if (/out line/i.test(r)) return 'Expected Wed at 23:00';
    if (/Welcome/.test(r)) return 'How long until your next episode';
    if (/empty/i.test(r)) return 'Follow a show';
    if (/meta|footnote/i.test(r)) return 'S4E1 · Apple TV';
    if (/chip/.test(r)) return 'Exact time';
    if (/label/i.test(r)) return 'Expected in';
    if (/Follow/.test(r)) return 'Follow';
    if (/Grid section/.test(r)) return 'Airing in the next few days';
    if (/section header/i.test(r)) return 'Next 24 hours';
    return 'House of the Dragon';
  };
  let customText = '';
  function renderTypePanel(surface) {
    const host = $('#type-panel'); if (!host) return;
    host.innerHTML = TYPE.filter((t) => t[1] === surface).map((t) => {
      const id = 'type-' + slug(t[0] + '-' + t[1]);
      const fam = t[2] === 'serif' ? 'New York' : 'SF Pro';
      return `<div class="type-row" id="${id}" data-search="${esc(t.join(' ') + ' type font size')}" data-title="${esc(t[0])}" data-kind="Type" data-sub="${esc(fam + ' ' + t[3])}">
        <div class="sample${t[2] === 'serif' ? ' serif' : ''}" style="font-size:${t[3]}px;font-weight:${t[4]}${t[5] ? ';font-variant-numeric:tabular-nums' : ''}" data-sample>${esc(customText || sampleFor(t[0]))}</div>
        <div class="meta-col"><b>${esc(t[0])}</b>${fam} ${W[t[4]]} ${t[3]}${t[5] ? ', tabular' : ''}<br>${esc(t[6])}</div></div>`;
    }).join('');
  }
  function bindCustomType() {
    const input = $('#custom-text'); if (!input) return;
    input.addEventListener('input', () => { customText = input.value.trim(); const sel = $('#type-tabs [aria-selected="true"]'); renderTypePanel(sel.dataset.tab); });
    $('#custom-reset').addEventListener('click', () => { input.value = ''; customText = ''; renderTypePanel($('#type-tabs [aria-selected="true"]').dataset.tab); input.focus(); });
  }
  // The search index needs every type row, so the rows of hidden surfaces are indexed from the data.
  const typeIndex = () => TYPE.map((t) => ({ id: 'type-' + slug(t[0] + '-' + t[1]), title: t[0], kind: 'Type', sub: 'Foundations', text: t.join(' '), tab: t[1] }));

  /* ================================================================ zone and out lines */
  const ZONE = (() => {
    let tz = ''; try { tz = Intl.DateTimeFormat().resolvedOptions().timeZone || ''; } catch (e) { tz = ''; }
    const parts = tz.split('/');
    const city = parts.length > 1 && parts[0] !== 'Etc' ? parts[parts.length - 1].replace(/_/g, ' ') : '';
    const off = -new Date().getTimezoneOffset();
    const utc = off === 0 ? 'UTC' : `UTC${off > 0 ? '+' : '−'}${Math.floor(Math.abs(off) / 60)}${Math.abs(off) % 60 ? ':' + String(Math.abs(off) % 60).padStart(2, '0') : ''}`;
    return { city: city || 'local', utc };
  })();
  const p2 = (n) => String(n).padStart(2, '0');
  const WD = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const MO = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  function outLine(verb, target, naming) {
    const d = new Date(target), now = new Date();
    const day0 = (x) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime();
    const diff = Math.round((day0(d) - day0(now)) / 86400000);
    const day = diff === 0 ? 'today' : diff === 1 ? 'tomorrow' : diff < 7 ? WD[d.getDay()] : `${WD[d.getDay()]} ${d.getDate()} ${MO[d.getMonth()]}`;
    return `${verb} ${day} at ${p2(d.getHours())}:${p2(d.getMinutes())}${naming ? ` ${ZONE.city} time` : ''}`;
  }
  function renderOutLines(scope = document) {
    $$('[data-out]', scope).forEach((el) => {
      const box = el.closest('.phone-copy, .col, .stage, .cd-card'); const cd = box && $('[data-cd]', box);
      if (cd && cd.dataset.cdTarget) el.textContent = outLine(el.dataset.out, Number(cd.dataset.cdTarget), el.hasAttribute('data-naming'));
    });
  }
  function renderZone() {
    $$('[data-zone]').forEach((el) => { el.textContent = ZONE.city; });
    $$('[data-utc]').forEach((el) => { el.textContent = ZONE.utc; });
  }

  /* ================================================================ countdowns */
  function clock(s) {
    s = Math.max(0, Math.ceil(s));
    const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), sec = s % 60;
    return h > 0 ? `${h}:${p2(m)}:${p2(sec)}` : `${m}:${p2(sec)}`;
  }
  // CountdownFormatter.daySplit: whole days, then a timer to the next day edge.
  function split(remaining) { const s = Math.ceil(remaining); const days = Math.max(0, Math.ceil(s / 86400) - 1); return { days, edge: s - days * 86400 }; }
  function countdownHTML(remaining) {
    if (remaining <= 0) return null;
    const { days, edge } = split(remaining);
    return days > 0 ? `${days}<span class="d">d </span>${clock(edge)}` : clock(edge);
  }
  const plural = (n, w) => `${n} ${w}${n === 1 ? '' : 's'}`;
  // Over a day: CountdownFormatter.spokenText(parts(maxUnits: 2)), the largest unit and the next, rounded down,
  // zero units dropped ("4 days", never "3 days 24 hours"). Under a day the app lets VoiceOver read the timer.
  function spoken(remaining) {
    if (remaining <= 0) return 'Out now';
    const total = Math.floor(remaining);
    if (total > 86400) {
      const mins = Math.max(1, Math.floor(total / 60));
      const units = [[Math.floor(mins / 1440), 'day'], [Math.floor((mins % 1440) / 60), 'hour'], [mins % 60, 'minute']];
      const first = units.findIndex(([v]) => v > 0);
      return units.slice(first, first + 2).filter(([v]) => v > 0).map(([v, w]) => plural(v, w)).join(' ');
    }
    const s = Math.ceil(remaining);
    const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), sec = s % 60;
    if (h > 0) return `${plural(h, 'hour')} ${plural(m, 'minute')}`;
    if (m > 0) return `${plural(m, 'minute')} ${plural(sec, 'second')}`;
    return plural(sec, 'second');
  }
  function arm(el, now = Date.now()) { el.dataset.cdTarget = String(now + Number(el.dataset.cd) * 1000); el.dataset.state = ''; }
  function tick() {
    const now = Date.now();
    $$('[data-cd]', current || document).forEach((el) => {
      if (!el.dataset.cdTarget) return;
      const rem = (Number(el.dataset.cdTarget) - now) / 1000;
      const html = countdownHTML(rem);
      if (html === null) {
        // Stops at zero and never counts up: the state becomes "Out now".
        if (el.dataset.state !== 'out') { el.dataset.state = 'out'; el.innerHTML = '<span class="cd-word" style="font-size:.7em">Out now</span>'; el.setAttribute('aria-label', 'Out now'); }
      } else {
        if (el.innerHTML !== html) el.innerHTML = html;
        const label = spoken(rem); if (el.getAttribute('aria-label') !== label) el.setAttribute('aria-label', label);
        el.dataset.state = '';
      }
    });
  }
  function initCountdowns() {
    // route() has already armed the open view; every other view is armed by rearm() when it opens.
    $$('[data-cd]').forEach((el) => el.setAttribute('role', 'timer'));
    setInterval(tick, 250);
  }
  // Each time a view opens, its countdowns restart from the values they are labelled with.
  function rearm(view) {
    const now = Date.now();
    $$('[data-cd]', view).forEach((el) => { if (!el.hasAttribute('data-cd-wait')) arm(el, now); });
    renderOutLines(view); tick();
  }
  function bindDemo() {
    const el = $('#demo-cd'); if (!el) return;
    const status = $('#demo-status');
    const set = (secs, label) => { el.dataset.cd = String(secs); arm(el); if (label) status.textContent = label; tick(); };
    const startTen = () => set(10, 'Ten seconds to the drop. Watch it reach zero and turn into “Out now”, without counting up.');
    // The ten-second demo starts when it is on screen, not at page load.
    let started = false;
    const io = new IntersectionObserver((entries) => {
      entries.forEach((en) => { if (en.isIntersecting && !started) { started = true; io.disconnect(); startTen(); } });
    }, { threshold: 0.6 });
    io.observe(el);
    $$('[data-demo]').forEach((b) => b.addEventListener('click', () => {
      started = true; io.disconnect();
      const v = b.dataset.demo;
      if (v === '10') startTen();
      if (v === '3725') set(3725, 'Under 24 hours: a plain timer.');
      if (v === 'days') set(2 * 86400 + 4 * 3600 + 10 * 60 + 22, 'More than a day: whole days, a dim “d”, then the timer to the next day edge.');
      if (v === 'edge') set(4 * 86400, 'Exactly on a day edge the timer starts at 24:00:00 and ticks down, instead of sitting at 0:00.');
    }));
  }

  /* ================================================================ galleries */
  // [family, kind, width pt, height pt, frame, corner]
  const WIDGET_FAMILIES = [
    ['inline', 'accessoryInline', 234, 22, 'lock', ''], ['circular', 'accessoryCircular', 72, 72, 'lock', 'r-circle'],
    ['rectangular', 'accessoryRectangular', 160, 72, 'lock', 'r-rect'], ['small', 'systemSmall', 158, 158, '', 'r-home'],
    ['medium', 'systemMedium', 338, 158, '', 'r-home'], ['large', 'systemLarge', 338, 354, '', 'r-home'],
  ];
  const WSTATES = [
    ['countdown', 'Silo in 2 days 4 hours, with two more rows'], ['ticking', 'House of the Dragon in 3:10:00, no official stream'],
    ['outNow', 'Out 20 minutes ago'], ['dateOnly', 'Wonder Man: a date, no time'], ['nothing', 'Nothing followed yet'],
    ['returns', 'Nothing scheduled; Silo returns'], ['busy', 'Six shows: “+N more this week”'], ['quiet', 'Two scheduled, then quiet rows'],
    ['allQuiet', 'Followed, but none scheduled'], ['ticking-always-on', 'Always-On, dimmed'],
  ];
  const LA_PRES = [
    ['lock', 'Lock Screen banner', 'lock', 360, 157, 'r-home'], ['compact', 'Compact', 'island', 221, 36, 'r-capsule'],
    ['minimal', 'Minimal', 'island', 36, 36, 'r-circle'], ['expanded', 'Expanded', 'island', 371, 156, 'r-expanded'],
    ['small', 'Small family', 'lock', 170, 105, 'r-card'],
  ];
  const LSTATES = [
    ['countingDown', 'Silo, expected in 2 hours'], ['delayed', 'Moved an hour later, the old time struck through'],
    ['longName', 'Frieren, airs in Japan'], ['merged', 'Silo + 1 more'], ['outNow', 'Out 10 minutes ago'], ['stale', 'At the drop, with no app running'],
  ];
  function shot(src, cap, frame, w, h, corner) {
    return `<figure class="shot" style="width:${w + 32}px"><div class="frame ${frame}"><img src="${src}" alt="${esc(cap)}" width="${w}" height="${h}" class="${corner}" loading="lazy" decoding="async"></div><figcaption>${esc(cap)}</figcaption></figure>`;
  }
  function renderWidgets(fam) {
    const f = WIDGET_FAMILIES.find((x) => x[0] === fam);
    let h = `<p class="gallery-h">${f[1]}, ${f[2]} × ${f[3]} pt, the smallest current iPhone Pro size. Corners are clipped as iOS clips them.</p><div class="gallery">`;
    h += WSTATES.map(([s, d]) => shot(`assets/widgets/${fam}-${s}.png`, d, f[4], f[2], f[3], f[5])).join('') + '</div>';
    if (['small', 'medium', 'large'].includes(fam)) {
      h += '<p class="gallery-h">With placeholder art: square art, then wide key art</p><div class="gallery">';
      ['countdown', 'ticking', 'busy', 'quiet', 'allQuiet'].forEach((s) => {
        const d = WSTATES.find((x) => x[0] === s)[1];
        h += shot(`assets/widgets/${fam}-${s}-art.png`, `${d}, square art`, '', f[2], f[3], f[5]) + shot(`assets/widgets/${fam}-${s}-art-wide.png`, `${d}, wide art`, '', f[2], f[3], f[5]);
      });
      h += '</div>';
    }
    $('#widget-gallery').innerHTML = h;
  }
  function laSize(p, s) {
    const f = LA_PRES.find((x) => x[0] === p);
    if (p === 'compact' && /^(outNow|stale)/.test(s)) return [224, 36];
    if (p === 'minimal' && /^limited/.test(s)) return [24, 24];
    return [f[3], f[4]];
  }
  function renderLA(p) {
    const f = LA_PRES.find((x) => x[0] === p);
    const one = (s, cap) => { const [w, h] = laSize(p, s); return shot(`assets/live-activity/${p}-${s}.png`, cap, f[2], w, h, f[5]); };
    let h = `<p class="gallery-h">${f[1]}, without art and then with placeholder art</p><div class="gallery">`;
    LSTATES.forEach(([s, d]) => { h += one(s, d) + one(`${s}-art`, `${d}, with art`); });
    h += '</div>';
    if (p === 'lock') {
      h += '<p class="gallery-h">The longest name, “The Lord of the Rings: The Rings of Power, Season Two Finale” on Paramount+ · US, and Always-On</p><div class="gallery">';
      LSTATES.forEach(([s, d]) => { h += one(`${s}-longest`, `${d}, longest name`) + one(`${s}-longest-art`, `${d}, longest name, with art`); });
      h += one('delayed-always-on', 'Always-On, delayed') + '</div>';
    }
    if (p === 'minimal') {
      h += '<p class="gallery-h">When the island is limited, it must fit 28 pt</p><div class="gallery">';
      [['countingDown', 'Counting down'], ['outNow', 'Out now']].forEach(([s, d]) => { h += one(`limited-${s}`, `${d}, limited`) + one(`limited-${s}-art`, `${d}, limited, with art`); });
      h += '</div>';
    }
    $('#la-gallery').innerHTML = h;
  }

  /* ================================================================ tabs (WAI-ARIA tabs, automatic activation) */
  function initTabs(list, onSelect) {
    const tabs = $$('[role="tab"]', list);
    const shared = new Set(tabs.map((t) => t.getAttribute('aria-controls'))).size === 1;
    const select = (tab, focus) => {
      tabs.forEach((t) => {
        const on = t === tab;
        t.setAttribute('aria-selected', String(on)); t.tabIndex = on ? 0 : -1;
        if (!shared) { const p = document.getElementById(t.getAttribute('aria-controls')); if (p) p.hidden = !on; }
      });
      if (shared) { const p = document.getElementById(tab.getAttribute('aria-controls')); if (p) p.setAttribute('aria-labelledby', tab.id); }
      if (focus) tab.focus();
      if (onSelect) onSelect(tab.dataset.tab, tab);
    };
    list.addEventListener('click', (e) => { const t = e.target.closest('[role="tab"]'); if (t) select(t, false); });
    list.addEventListener('keydown', (e) => {
      const i = tabs.indexOf(document.activeElement); if (i < 0) return;
      let n = null;
      if (e.key === 'ArrowRight' || e.key === 'ArrowDown') n = (i + 1) % tabs.length;
      else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') n = (i - 1 + tabs.length) % tabs.length;
      else if (e.key === 'Home') n = 0; else if (e.key === 'End') n = tabs.length - 1;
      if (n !== null) { e.preventDefault(); select(tabs[n], true); }
    });
    select(tabs.find((t) => t.getAttribute('aria-selected') === 'true') || tabs[0], false);
    return { select: (key) => { const t = tabs.find((x) => x.dataset.tab === key); if (t) select(t, false); } };
  }
  const tabsets = {};
  function bindTabs() {
    $$('[role="tablist"]').forEach((list) => {
      let fn = null;
      if (list.id === 'widget-tabs') fn = renderWidgets;
      else if (list.id === 'la-tabs') fn = renderLA;
      else if (list.id === 'type-tabs') fn = renderTypePanel;
      const api = initTabs(list, fn); if (list.id) tabsets[list.id] = api;
    });
    // Component groups: when a new group opens while the tabs are pinned, start at its top.
    const gt = $('#group-tabs');
    if (gt) {
      const toTop = () => { const p = $('.group:not([hidden])'); const h = p && $('h2', p); if (h && h.getBoundingClientRect().top < 0) h.scrollIntoView({ block: 'start' }); markHere(); };
      gt.addEventListener('click', (e) => { if (e.target.closest('[role="tab"]')) toTop(); });
      gt.addEventListener('keydown', (e) => { if (/Arrow|Home|End/.test(e.key)) toTop(); });
      const groups = $$('.group');
      groups.forEach((g, i) => {
        const next = groups[i + 1]; if (!next) return;
        const h = $('h2', next);
        g.insertAdjacentHTML('beforeend', `<p class="next-group"><span>Next group</span><a href="#${h.id}">${esc(h.textContent)}</a></p>`);
      });
    }
  }

  /* ================================================================ copy, toast, anchors */
  const toastEl = $('#toast'); let toastTimer;
  function toast(msg) { toastEl.textContent = msg; toastEl.classList.add('show'); clearTimeout(toastTimer); toastTimer = setTimeout(() => toastEl.classList.remove('show'), 1600); }
  async function copy(text, what) {
    let ok = false;
    try { await navigator.clipboard.writeText(text); ok = true; } catch (e) {
      const ta = document.createElement('textarea'); ta.value = text; ta.setAttribute('readonly', ''); ta.style.position = 'fixed'; ta.style.opacity = '0';
      document.body.appendChild(ta); ta.select();
      try { ok = document.execCommand('copy'); } catch (_) { ok = false; }
      ta.remove();
    }
    const shown = text.length > 44 ? text.slice(0, 42) + '…' : text;
    toast(ok ? (what || `Copied ${shown}`) : 'Couldn’t copy. Select the text and copy it instead.');
  }
  function decorate() {
    // On phones, plain tables stack: each cell carries its column name.
    $$('.view table').forEach((t) => {
      if (t.classList.contains('contrast') || t.classList.contains('inks') || !t.tHead) return;
      const heads = $$('thead th', t).map((th) => th.textContent.trim());
      $$('tbody tr', t).forEach((tr) => Array.from(tr.children).forEach((td, i) => { if (heads[i]) td.dataset.label = heads[i]; }));
      t.classList.add('stack');
    });
    $$('.comp').forEach((c) => { if ($('.phone', c)) c.classList.add('side'); });
    $$('.comp').forEach((c) => {
      const row = $('.hrow', c); if (!row || $('.anchor-btn', row)) return;
      const b = document.createElement('button'); b.type = 'button'; b.className = 'anchor-btn'; b.dataset.link = c.id; b.textContent = '#';
      b.setAttribute('aria-label', 'Copy a link to ' + $('h3', row).textContent); row.appendChild(b);
    });
    $$('.codebox').forEach((box) => {
      if ($('.code-head', box)) return;
      const head = document.createElement('div'); head.className = 'code-head';
      head.innerHTML = '<span>SwiftUI</span><button type="button" class="copy-code">Copy</button>';
      const owner = box.closest('[data-title]'); const name = owner ? owner.dataset.title : 'this';
      $('.copy-code', head).setAttribute('aria-label', `Copy the SwiftUI code for ${name}`);
      $('.copy-code', head).addEventListener('click', () => copy($('code', box).innerText, 'Code copied'));
      box.insertBefore(head, box.firstChild);
    });
  }
  document.addEventListener('click', (e) => {
    const c = e.target.closest('[data-copy]'); if (c) { copy(c.dataset.copy); return; }
    const l = e.target.closest('[data-link]');
    if (l) { const id = l.dataset.link; history.replaceState(null, '', '#' + id); copy(location.href.split('#')[0] + '#' + id, 'Link copied'); }
  });

  /* ================================================================ views and routing */
  const views = $$('.view');
  let current = null, lastTarget = null, userMoved = false;
  const titleFor = (v) => (v.id === 'overview' ? 'Meridian Design System' : `${v.dataset.label} · Meridian Design System`);
  function show(view) {
    if (current === view) return;
    views.forEach((v) => v.classList.toggle('is-active', v === view));
    current = view; document.title = titleFor(view);
    buildSub(); rearm(view);
  }
  function revealInside(el) {
    let d = el.closest('details'); while (d) { d.open = true; d = d.parentElement && d.parentElement.closest('details'); }
    // Outermost first, so a state tab inside a hidden component group opens the group too.
    const panels = []; let p = el.closest('[role="tabpanel"][hidden]');
    while (p) { panels.unshift(p); p = p.parentElement && p.parentElement.closest('[role="tabpanel"][hidden]'); }
    panels.forEach((panel) => { const tab = $(`[aria-controls="${panel.id}"]`); if (tab) tab.click(); });
  }
  function targetFor(id) {
    let el = id ? document.getElementById(id) : null;
    if (el && !el.closest('.view')) el = null;
    if (!el && id && id.startsWith('type-')) { // a type row on another surface tab
      const t = typeIndex().find((x) => x.id === id);
      if (t) { if (tabsets['type-tabs']) tabsets['type-tabs'].select(t.tab); el = document.getElementById(id); }
    }
    return el;
  }
  function route(id, opts = {}) {
    if (id === 'foundations-space') id = 'space';
    const el = targetFor(id) || views[0];
    const view = el.classList.contains('view') ? el : el.closest('.view');
    show(view); revealInside(el);
    if (el === view) window.scrollTo(0, 0); else el.scrollIntoView({ block: 'start' });
    lastTarget = el; userMoved = false;
    if (opts.focus) {
      const f = el === view ? $('h1', view) : el;
      if (!f.matches('a, button, input, select, textarea, summary, [tabindex]')) f.setAttribute('tabindex', '-1');
      f.focus({ preventScroll: true });
    }
    if (opts.flash && el !== view) { el.classList.add('flash'); setTimeout(() => el.classList.remove('flash'), 1600); }
    markHere();
  }
  function navigate(id, opts) {
    if (location.hash.slice(1) !== id) history.pushState(null, '', '#' + id);
    route(id, opts);
  }
  document.addEventListener('click', (e) => {
    const a = e.target.closest('a[href^="#"]'); if (!a || e.defaultPrevented || e.metaKey || e.ctrlKey || e.shiftKey) return;
    if (a.closest('#search')) return;
    const id = a.getAttribute('href').slice(1);
    if (id === 'main') { e.preventDefault(); $('#main').focus(); return; }
    if (!document.getElementById(id) && !id.startsWith('type-')) return;
    e.preventDefault(); closeDrawer(true); navigate(id, { focus: true });
  });
  window.addEventListener('popstate', () => route(location.hash.slice(1)));
  ['wheel', 'touchmove', 'keydown', 'mousedown'].forEach((t) => window.addEventListener(t, () => { userMoved = true; }, { passive: true }));

  /* ================================================================ rail */
  const rail = $('#rail'), scrim = $('#scrim'), menuBtn = $('#menu-btn');
  const mobile = window.matchMedia('(max-width: 1000px)');
  function buildRail() {
    $('#rail-list').innerHTML = views.map((v) => `<li class="v" data-view="${v.id}"><a href="#${v.id}">${esc(v.dataset.label)}</a><ul class="sub"></ul></li>`).join('');
  }
  function buildSub() {
    $$('#rail-list .v').forEach((li) => {
      const open = li.dataset.view === current.id; li.classList.toggle('open', open);
      const a = $('a', li); if (open) a.setAttribute('aria-current', 'page'); else a.removeAttribute('aria-current');
      const ul = $('.sub', li);
      ul.innerHTML = open ? $$('h2[id]', current).map((h) => `<li><a href="#${h.id}" data-sub="${h.id}">${esc(h.textContent.trim())}</a></li>`).join('') : '';
    });
  }
  let raf = 0;
  function markHere() {
    if (!current) return;
    const hs = $$('h2[id]', current); let here = null;
    hs.forEach((h) => { if (h.offsetParent !== null && h.getBoundingClientRect().top < 200) here = h; });
    $$('#rail-list a[data-sub]').forEach((a) => {
      const on = !!here && a.dataset.sub === here.id;
      a.classList.toggle('here', on); if (on) a.setAttribute('aria-current', 'location'); else a.removeAttribute('aria-current');
    });
  }
  window.addEventListener('scroll', () => { if (!raf) raf = requestAnimationFrame(() => { raf = 0; markHere(); }); }, { passive: true });
  const outside = () => [$('main'), $('.topbar'), $('footer.foot'), $('.skip')];
  function syncRail() {
    const open = rail.classList.contains('open');
    rail.inert = mobile.matches && !open;
    outside().forEach((el) => { el.inert = mobile.matches && open; });
    scrim.hidden = !(mobile.matches && open);
  }
  function openDrawer() { rail.classList.add('open'); menuBtn.setAttribute('aria-expanded', 'true'); syncRail(); const first = $('#rail-list a[aria-current="page"]') || $('#rail-list a'); if (first) first.focus(); }
  function closeDrawer(silent) {
    if (!rail.classList.contains('open')) return;
    rail.classList.remove('open'); menuBtn.setAttribute('aria-expanded', 'false'); syncRail();
    if (!silent) menuBtn.focus();
  }
  function bindRail() {
    menuBtn.addEventListener('click', openDrawer);
    $('#rail-close').addEventListener('click', () => closeDrawer());
    scrim.addEventListener('click', () => closeDrawer());
    rail.addEventListener('keydown', (e) => { if (e.key === 'Escape') { e.preventDefault(); closeDrawer(); } });
    mobile.addEventListener('change', () => { if (!mobile.matches) rail.classList.remove('open'); syncRail(); });
    syncRail();
  }

  /* ================================================================ search */
  const dlg = $('#search'), input = $('#search-input');
  let index = [], sel = 0, results = [], opener = null, navigating = false;
  function buildIndex() {
    index = [];
    const viewLabel = (el) => { const v = el.closest('.view'); return v ? v.dataset.label : ''; };
    views.forEach((v) => index.push({ id: v.id, title: v.dataset.label, kind: 'Page', sub: '', text: v.dataset.search || '' }));
    $$('.view h2[id]').forEach((h) => index.push({ id: h.id, title: h.textContent.trim(), kind: 'Section', sub: viewLabel(h), text: '' }));
    $$('.view h3[id]').forEach((h) => index.push({ id: h.id, title: h.textContent.trim(), kind: 'Topic', sub: viewLabel(h), text: '' }));
    $$('.view [data-search][id]').forEach((el) => {
      if (el.classList.contains('view') || el.classList.contains('type-row')) return;
      index.push({ id: el.id, title: el.dataset.title || el.textContent.trim().split('\n')[0], kind: el.dataset.kind || 'Item', sub: viewLabel(el), text: el.dataset.search });
    });
    typeIndex().forEach((t) => index.push(t));
  }
  function score(item, terms) {
    const t = item.title.toLowerCase(), all = (item.title + ' ' + item.text + ' ' + item.sub + ' ' + item.kind).toLowerCase();
    let s = 0;
    for (const q of terms) { if (!all.includes(q)) return -1; s += t.startsWith(q) ? 6 : t.includes(q) ? 3 : 1; }
    if (item.kind === 'Page') s += 2; else if (item.kind === 'Section') s += 1;
    if (item.kind === 'Archive') s -= 3;
    return s;
  }
  function renderResults(q) {
    const terms = q.toLowerCase().split(/\s+/).filter(Boolean);
    results = terms.length ? index.map((i) => [score(i, terms), i]).filter((x) => x[0] >= 0).sort((a, b) => b[0] - a[0]).slice(0, 40).map((x) => x[1])
      : index.filter((i) => i.kind === 'Page');
    sel = 0;
    const ul = $('#search-results');
    ul.innerHTML = results.length ? results.map((i, n) => `<li role="option" id="sr-${n}" aria-selected="${n === 0}"><a href="#${i.id}" tabindex="-1"><span class="k">${esc(i.kind)}</span><span>${esc(i.title)}</span><span class="s">${esc(i.sub)}</span></a></li>`).join('')
      : `<li class="search-empty" role="presentation">Nothing matches “${esc(q)}”. Try a token (“muted”), a hex (“1C1C1C”), a component (“chip”) or a word (“Expected”).</li>`;
    if (results.length) input.setAttribute('aria-activedescendant', 'sr-0'); else input.removeAttribute('aria-activedescendant');
  }
  function openSearch() {
    if (dlg.open) return;
    opener = document.activeElement; navigating = false;
    input.value = ''; renderResults('');
    dlg.showModal(); input.focus();
  }
  function closeSearch() { if (dlg.open) dlg.close(); }
  function go(id) { navigating = true; closeSearch(); closeDrawer(true); navigate(id, { focus: true, flash: true }); }
  function bindSearch() {
    $('#search-btn').addEventListener('click', openSearch);
    $('#search-close').addEventListener('click', closeSearch);
    dlg.addEventListener('close', () => { if (!navigating && opener && opener.focus) opener.focus(); });
    dlg.addEventListener('click', (e) => {
      if (e.target === dlg) { closeSearch(); return; }
      const a = e.target.closest('#search-results a'); if (a) { e.preventDefault(); go(a.getAttribute('href').slice(1)); }
    });
    input.addEventListener('input', () => renderResults(input.value));
    dlg.addEventListener('cancel', (e) => { e.preventDefault(); closeSearch(); });
    dlg.addEventListener('keydown', (e) => {
      // A search field would otherwise spend the first Escape on clearing itself.
      if (e.key === 'Escape') { e.preventDefault(); e.stopPropagation(); closeSearch(); return; }
      if (e.key === 'Tab') { // keep focus inside the dialog
        const f = [input, $('#search-close')]; const i = f.indexOf(document.activeElement);
        e.preventDefault(); f[(i + (e.shiftKey ? -1 : 1) + f.length) % f.length].focus(); return;
      }
      if (document.activeElement !== input) return;
      const lis = $$('#search-results li[role="option"]');
      if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
        e.preventDefault(); if (!lis.length) return;
        sel = (sel + (e.key === 'ArrowDown' ? 1 : -1) + lis.length) % lis.length;
        lis.forEach((li, n) => li.setAttribute('aria-selected', String(n === sel)));
        lis[sel].scrollIntoView({ block: 'nearest' }); input.setAttribute('aria-activedescendant', 'sr-' + sel);
      } else if (e.key === 'Enter') { e.preventDefault(); if (results[sel]) go(results[sel].id); }
    });
    document.addEventListener('keydown', (e) => {
      const a = document.activeElement;
      const typing = a && (/INPUT|TEXTAREA|SELECT/.test(a.tagName) || a.isContentEditable);
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') { e.preventDefault(); if (dlg.open) closeSearch(); else { closeDrawer(true); openSearch(); } }
      else if (e.key === '/' && !typing && !dlg.open) { e.preventDefault(); closeDrawer(true); openSearch(); }
    });
  }

  /* ================================================================ hero, motion, checklist */
  const ART = { cool: '#181E24', warm: '#1C1B1A', none: '#1C1C1C' };
  function bindHero() {
    const hero = $('#hero'); if (!hero) return;
    const art = $('#hero-art'), code = $('#hero-night');
    $$('.pick button', hero).forEach((b) => b.addEventListener('click', () => {
      const k = b.dataset.art;
      $$('.pick button', hero).forEach((x) => x.setAttribute('aria-pressed', String(x === b)));
      hero.style.setProperty('--night', ART[k]); $('.hero-phone', hero).style.setProperty('--night', ART[k]);
      code.textContent = ART[k];
      art.hidden = k === 'none';
      if (k !== 'none') { art.className = 'art ' + k; if (!reduceMotion.matches) { art.classList.remove('arrive'); void art.offsetWidth; art.classList.add('arrive'); } }
    }));
  }
  function bindMotion() {
    const b = $('#motion-play'); if (!b) return;
    b.addEventListener('click', () => { const a = $('#motion-art'); a.classList.remove('in'); void a.offsetWidth; requestAnimationFrame(() => a.classList.add('in')); });
  }

  /* ================================================================ start */
  renderLogos(); renderTokens(); renderContrast(); renderZone();
  bindTabs(); bindCustomType(); decorate();
  buildRail(); bindRail(); bindSearch(); bindHero(); bindMotion(); bindDemo();
  buildIndex();
  route(location.hash.slice(1) || 'overview');
  document.documentElement.classList.add('routed');
  initCountdowns();
  // Web fonts can change line heights after the first layout; keep a deep link on its target.
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(() => { if (lastTarget && !lastTarget.classList.contains('view') && !userMoved) lastTarget.scrollIntoView({ block: 'start' }); markHere(); });
})();
