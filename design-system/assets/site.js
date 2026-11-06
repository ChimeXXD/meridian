/* Meridian design system: data and behaviour. Plain JS, no dependencies.
   Every app value below comes from the app's source at commit a22854f. */
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
  // `crop` trims the 100-unit square to the mark itself (16 6 68 84), so a small mark fills its box: `size` is then its height.
  function logoSVG({ size = 32, ink = 'currentColor', star = null, label = 'Meridian logo', crop = false } = {}) {
    const id = 'mlg' + (++uid);
    const a11y = label ? `role="img" aria-label="${esc(label)}"` : 'aria-hidden="true" focusable="false"';
    const box = crop ? '16 6 68 84' : '0 0 100 100', w = crop ? +(size * 68 / 84).toFixed(2) : size;
    return `<svg viewBox="${box}" width="${w}" height="${size}" ${a11y}>${logoInner(ink, star, id)}</svg>`;
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
      el.innerHTML = logoSVG({ size: Number(el.dataset.size || 32), star, label: el.dataset.label === undefined ? 'Meridian logo' : el.dataset.label, crop: 'crop' in el.dataset });
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
      ['night-bases', 'Computed: Wednesday', 'Wednesday’s art', '#181924', '#181924', '--night-sample-wednesday', '', 'Cool. Computed sample from its key art, used in the mockups'],
      ['night-bases', 'Computed: Severance', 'Severance’s art', '#1B241A', '#1B241A', '--night-sample-severance', '', 'Cool. Computed sample from its key art, used in the mockups'],
    ],
    controls: [
      ['control-colours', 'Control fill', 'Control fill', 'rgba(0,0,0,.55)', '#0000008C', '--control-fill', 'Color.black.opacity(0.55)', 'Unpicked filter chip, the Follow (+) button', '#1C1C1C'],
      ['control-colours', 'Hairline', 'Hairline', 'rgba(255,255,255,.35)', '#FFFFFF59', '--control-hairline', 'Color.white.opacity(0.35)', 'Strokes on the unpicked chip, (+) and “Following”', '#1C1C1C'],
      ['control-colours', 'Following fill', 'Following fill', 'rgba(255,255,255,.12)', '#FFFFFF1F', '--following-fill', 'Color.white.opacity(0.12)', 'The “Following” capsule; the episode divider', '#1C1C1C'],
      ['control-colours', 'Episode ink', 'Episode ink', 'rgba(255,255,255,.6)', '#FFFFFF99', '--episode-ink', 'Color.white.opacity(0.6)', 'Episode label and date; the Live Activity toggle tint', '#1C1C1C'],
      ['control-colours', 'Tag fill', 'Widget tag fill', 'rgba(0,0,0,.45)', '#00000073', '--widget-tag-fill', 'Color.black.opacity(0.45)', 'The widget tag capsule over art', '#8C8C8C'],
      ['control-colours', 'Art scrim', 'Art scrim', 'rgba(0,0,0,.4)', '#00000066', '--art-scrim', 'Color.black.opacity(0.4)', 'Top of the art header, clear by 25%', '#8C8C8C'],
      ['widget-ink', 'Tile', 'Widget tile', 'rgba(255,255,255,.08)', '#FFFFFF14', '--widget-tile', 'WidgetInk.tile', 'Where a widget thumbnail would be when a show has no art yet; the app’s poster surface is the same white at 0.08', '#1C1C1C'],
      ['control-colours', 'Welcome tile', 'Welcome tile', 'rgba(255,255,255,.05)', '#FFFFFF0D', '--welcome-tile', 'Color.white.opacity(0.05)', 'A Welcome wall tile until its picture loads, or if it can’t', '#1C1C1C'],
      ['control-colours', 'Picked / primary', 'Picked and primary', '#FFFFFF', '#FFFFFF', '--control-picked', 'Color.white', 'Picked chip, Following (+), Follow and Find a show, the tab tint. Text on it is black'],
    ],
    la: [
      ['la-ink', 'Out', 'Out now', '#E9C46A', '#E9C46A', '--la-out', 'LiveActivityInk.out', 'Meridian Gold (Tokens.gold): “Out now” wherever the Live Activity says it, from the drop', '#0D0D0E'],
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
    ['Hero countdown', 'App', 'serif', 64, 300, true, 'Upcoming hero and Show detail; 48 on the show page'],
    ['Welcome headline', 'App', 'serif', 34, 400, false, 'Welcome'],
    ['Welcome wordmark', 'App', 'serif', 22, 400, false, '“Meridian” in title 2, Starlight, beside the 36 pt mark; both grow with Dynamic Type'],
    ['Hero title', 'App', 'serif', 32, 400, false, 'Headline title, spotlight, the show page'],
    ['Empty headline', 'App', 'serif', 28, 400, false, '“Follow a show…”, “Nothing scheduled…”'],
    ['Row countdown', 'App', 'serif', 24, 300, true, 'Upcoming row'],
    ['Grid section header', 'App', 'serif', 22, 400, false, '“Popular in the past year”, “Results”'],
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
    ['Expanded countdown / Out now', 'Live Activity', 'serif', 24, 300, true, 'Expanded island, bottom right'],
    ['Small LA countdown', 'Live Activity', 'serif', 24, 300, true, 'Small family'],
    ['Lock banner title', 'Live Activity', 'serif', 19, 500, false, 'Lock Screen banner'],
    ['Expanded title', 'Live Activity', 'serif', 18, 500, false, 'Expanded island, leading'],
    ['Compact island timer', 'Live Activity', 'serif', 15, 500, true, 'Compact, trailing'],
    ['Expanded time', 'Live Activity', 'sans', 15, 500, false, '“Expected Mon 21:00”; “Delayed from 21:00” 13 muted'],
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
    if (/wordmark/.test(r)) return 'Meridian';
    if (/Welcome/.test(r)) return 'How long until your next episode';
    if (/empty/i.test(r)) return 'Follow a show';
    if (/meta|footnote/i.test(r)) return 'S4E1 · Apple TV';
    if (/chip/.test(r)) return 'New seasons';
    if (/label/i.test(r)) return 'Expected in';
    if (/Follow/.test(r)) return 'Follow';
    if (/Grid section/.test(r)) return 'Popular in the past year';
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
  // ReleaseWording.verb: once the time has passed a sure time says "Released" and an anime "Aired in Japan"; an
  // estimate keeps "Expected", so it never claims more than its source.
  const PAST = { 'Out': 'Released', 'Airs in Japan': 'Aired in Japan' };
  // ReleaseWording.outLine with DropFormatter.relativeDay: "today", "tomorrow", "yesterday", a weekday within the
  // week, then "Wed 18 Nov", with the year when it isn't this year.
  function outLine(verb, target, naming) {
    const d = new Date(target), now = new Date();
    const day0 = (x) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime();
    const diff = Math.round((day0(d) - day0(now)) / 86400000);
    const dayMonth = `${WD[d.getDay()]} ${d.getDate()} ${MO[d.getMonth()]}`;
    const day = diff === 0 ? 'today' : diff === 1 ? 'tomorrow' : diff === -1 ? 'yesterday' : diff >= 2 && diff <= 6 ? WD[d.getDay()]
      : d.getFullYear() === now.getFullYear() ? dayMonth : `${dayMonth} ${d.getFullYear()}`;
    const said = target <= now.getTime() ? PAST[verb] || verb : verb;
    return `${said} ${day} at ${p2(d.getHours())}:${p2(d.getMinutes())}${naming ? ` ${ZONE.city} time` : ''}`;
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
  // Only the last day ticks (CountdownFormatter.tickingWindow, 24 hours). Further out the countdown holds still:
  // CountdownFormatter.stillParts, whole days and hours rounded down, both always shown ("2d 4h", "4d 0h"), so the
  // width holds steady (D-56).
  const TICKING_WINDOW = 86400;
  function coarse(remaining) {
    const hours = Math.max(0, Math.floor(remaining / 3600));
    return [[Math.floor(hours / 24), 'd', 'day'], [hours % 24, 'h', 'hour']];
  }
  // CountdownFormatter.state: dateOnly is drawn in the page; here, ticking or still before the drop, "Out now" from
  // the drop until an hour after (outNowWindow), then "Released".
  const OUT_NOW_WINDOW = 3600;
  const stateOf = (remaining) => (remaining > TICKING_WINDOW ? 'coarse' : remaining > 0 ? 'ticking' : remaining > -OUT_NOW_WINDOW ? 'out' : 'released');
  // CountdownText's words in the countdown's place: "Out now" at 0.7 times in Meridian Gold, "Released" at 0.6 times
  // in the secondary ink.
  const WORDS = {
    out: ['<span class="cd-word out" style="font-size:.7em">Out now</span>', 'Out now'],
    released: ['<span class="cd-word" style="font-size:.6em;color:rgba(255,255,255,.6)">Released</span>', 'Released'],
  };
  function countdownHTML(remaining) {
    if (remaining <= 0) return null;
    if (remaining <= TICKING_WINDOW) return clock(remaining);
    // The unit letters are half size in the secondary ink, as the app draws them.
    const parts = coarse(remaining);
    return parts.map(([v, u], i) => `${v}<span class="d">${u}${i < parts.length - 1 ? ' ' : ''}</span>`).join('');
  }
  const plural = (n, w) => `${n} ${w}${n === 1 ? '' : 's'}`;
  // Over a day: CountdownFormatter.spokenText of the still parts, with a zero part left out ("2 days 4 hours", "4 days",
  // never "3 days 24 hours"). Under a day, as the widgets' VoiceOver phrase says it: CountdownFormatter.parts with
  // maxUnits 2, the largest unit that isn't zero and the next, rounded down, zeros left out ("23 hours 59 minutes",
  // "1 hour", "1 day" at exactly 24 hours), and anything under a minute "1 minute".
  function spoken(remaining) {
    if (remaining <= 0) return 'Out now';
    if (remaining > TICKING_WINDOW) return coarse(remaining).filter(([v]) => v > 0).map(([v, , w]) => plural(v, w)).join(' ');
    const minutes = Math.max(1, Math.floor(Math.floor(remaining) / 60));
    const units = [[Math.floor(minutes / 1440), 'day'], [Math.floor((minutes % 1440) / 60), 'hour'], [minutes % 60, 'minute']];
    const first = units.findIndex(([v]) => v > 0);
    return units.slice(first, first + 2).filter(([v]) => v > 0).map(([v, w]) => plural(v, w)).join(' ');
  }
  function arm(el, now = Date.now()) { el.dataset.cdTarget = String(now + Number(el.dataset.cd) * 1000); el.dataset.state = ''; }
  function tick() {
    const now = Date.now();
    $$('[data-cd]', current || document).forEach((el) => {
      if (!el.dataset.cdTarget) return;
      const rem = (Number(el.dataset.cdTarget) - now) / 1000;
      const state = stateOf(rem), was = el.dataset.state;
      el.dataset.state = state;
      // The out line beside it turns to the past ("Released …", "Aired in Japan …") at the drop.
      if (was && was !== state && (state === 'out' || was === 'out')) renderOutLines(el.closest('.phone-copy, .col, .stage, .cd-card') || el);
      if (state === 'out' || state === 'released') {
        // The Live Activity's timer (data-cd-hold) stops at 0:00 and stays there (LiveActivityCountdown); every other
        // countdown stops at zero and never counts up: the words take its place.
        const [html, label] = el.hasAttribute('data-cd-hold') ? ['0:00', '0:00'] : WORDS[state];
        if (el.innerHTML !== html) { el.innerHTML = html; el.setAttribute('aria-label', label); }
        return;
      }
      const html = countdownHTML(rem);
      if (el.innerHTML !== html) el.innerHTML = html;
      const label = spoken(rem); if (el.getAttribute('aria-label') !== label) el.setAttribute('aria-label', label);
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
      if (v === 'days') set(2 * 86400 + 4 * 3600 + 40 * 60 + 22, 'More than a day: whole days and hours, and it holds still. Only the last day ticks.');
      if (v === 'edge') set(86400 + 5, 'Five seconds before the last day: it reads 1d 0h, then starts ticking from 24:00:00.');
    }));
  }

  /* ================================================================ galleries */
  // [family, kind, width pt, height pt, frame, corner]
  const WIDGET_FAMILIES = [
    ['inline', 'accessoryInline', 234, 22, 'ink', ''], ['circular', 'accessoryCircular', 72, 72, 'ink', 'r-circle'],
    ['rectangular', 'accessoryRectangular', 160, 72, 'ink', 'r-rect'], ['small', 'systemSmall', 158, 158, '', 'r-home'],
    ['medium', 'systemMedium', 338, 158, '', 'r-home'], ['large', 'systemLarge', 338, 354, '', 'r-home'],
  ];
  const WSTATES = [
    ['countdown', 'Silo in 2 days 4 hours, with two more rows'], ['ticking', 'House of the Dragon in 3:10:00, no official stream'],
    ['outNow', 'Out 20 minutes ago'], ['dateOnly', 'Wonder Man: a date, no time'], ['nothing', 'Nothing followed yet'],
    ['returns', 'Nothing scheduled; Silo returns'], ['busy', 'Six shows: “+N more this week”'], ['quiet', 'Two scheduled, then quiet rows'],
    ['allQuiet', 'Followed, but none scheduled'], ['ticking-always-on', 'Always-On, dimmed'],
  ];
  const LA_PRES = [
    ['lock', 'Lock Screen banner', '', 360, 157, 'r-home'], ['compact', 'Compact', '', 221, 36, 'r-capsule'],
    ['minimal', 'Minimal', '', 36, 36, 'r-circle'], ['expanded', 'Expanded', '', 371, 118.67, 'r-expanded'],
    ['small', 'Small family', '', 170, 105, 'r-card'],
  ];
  const LSTATES = [
    ['countingDown', 'Silo, expected in 2 hours'], ['delayed', 'Moved an hour later'],
    ['longName', 'Frieren, airs in Japan'], ['merged', 'Silo + 1 more'], ['outNow', 'Out 10 minutes ago'], ['stale', 'At the drop, with no app running'],
  ];
  function shot(src, cap, frame, w, h, corner, holes) {
    let img = `<img src="${src}" alt="${esc(cap)}" width="${w}" height="${h}" class="${corner}" loading="lazy" decoding="async">`;
    // A render with art holes sits in a box the show's art fills from behind (see fillHoles). The render sizes the box
    // (its width and height reserve the space), so it shrinks as the plain renders do and nothing moves as art arrives.
    if (holes) img = `<span class="holes ${corner}" data-holes="${esc(src.split('/').pop())}">${img}</span>`;
    return `<figure class="shot" style="width:${w + 48}px"><div class="frame ${frame}">${img}</div><figcaption>${esc(cap)}</figcaption></figure>`;
  }
  // Each render with art is the app's own view with the art cut out (alpha 0), the fades over it kept as see-through
  // pixels; art-holes.json, written by the same tests, lists each hole in the PNG's pixels. The show's real art goes
  // behind each hole as the app crops it (cover, anchored as the view anchors it), so the browser composites it as the
  // phone does. Under each image is the site's neutral art placeholder, which shows if the image fails or is blocked.
  const holeManifests = {};
  function loadHoles(folder) {
    if (!holeManifests[folder]) {
      holeManifests[folder] = fetch(`assets/${folder}/art-holes.json`).then((r) => (r.ok ? r.json() : null)).catch(() => null);
    }
    return holeManifests[folder];
  }
  function fillHoles(root, folder) {
    loadHoles(folder).then((manifest) => {
      if (!manifest) return;
      $$('.holes[data-holes]', root).forEach((box) => {
        const entry = manifest.shots[box.dataset.holes];
        if (!entry || box.dataset.filled) return;
        box.dataset.filled = 'true';
        const render = box.querySelector(':scope > img');
        const pct = (v, of) => `${(100 * v / of).toFixed(3)}%`;
        entry.holes.forEach((hole) => {
          const art = document.createElement('span');
          art.className = 'art neutral hole';
          art.setAttribute('aria-hidden', 'true');
          art.style.left = pct(hole.x, entry.width); art.style.top = pct(hole.y, entry.height);
          art.style.width = pct(hole.w, entry.width); art.style.height = pct(hole.h, entry.height);
          if (hole.circle) art.style.borderRadius = '50%';
          else if (hole.radius) art.style.borderRadius = `${pct(hole.radius, hole.w)} / ${pct(hole.radius, hole.h)}`;
          const src = widgetImage(SHOW_BY_NAME[hole.show], hole.kind);
          if (src) {
            const img = document.createElement('img');
            img.alt = ''; img.decoding = 'async'; img.loading = 'lazy'; img.referrerPolicy = 'no-referrer';
            img.width = src[1]; img.height = src[2];
            img.style.objectPosition = hole.align === 'top' ? '50% 0' : '50% 50%';
            // A failed or blocked image is hidden, so the placeholder shows, never a broken-image icon.
            img.addEventListener('error', () => { img.hidden = true; });
            img.src = src[0];
            art.append(img);
          }
          // In the manifest's order, before the render: a row's poster paints over the hero's art behind it.
          box.insertBefore(art, render);
        });
      });
    });
  }
  function renderWidgets(fam) {
    const f = WIDGET_FAMILIES.find((x) => x[0] === fam);
    let h = `<p class="gallery-h">${f[1]}, ${f[2]} × ${f[3]} pt, the smallest current iPhone Pro size. Corners are clipped as iOS clips them.</p><div class="gallery">`;
    h += WSTATES.map(([s, d]) => shot(`assets/widgets/${fam}-${s}.png`, d, f[4], f[2], f[3], f[5])).join('') + '</div>';
    if (['small', 'medium', 'large'].includes(fam)) {
      h += '<p class="gallery-h">With each show’s art: the key art behind the top, a poster beside each row</p><div class="gallery">';
      ['countdown', 'ticking', 'busy', 'quiet', 'allQuiet'].forEach((s) => {
        const d = WSTATES.find((x) => x[0] === s)[1];
        h += shot(`assets/widgets/${fam}-${s}-art.png`, `${d}, with art`, '', f[2], f[3], f[5], true);
      });
      h += '</div>';
    }
    $('#widget-gallery').innerHTML = h;
    fillHoles($('#widget-gallery'), 'widgets');
  }
  function laSize(p, s) {
    const f = LA_PRES.find((x) => x[0] === p);
    if (p === 'compact' && /^(outNow|stale)/.test(s)) return [224, 36];
    if (p === 'minimal' && /^limited/.test(s)) return [24, 24];
    // A moved time adds a line under the words (D-57).
    if (p === 'expanded' && /^delayed/.test(s)) return [371, 136.33];
    return [f[3], f[4]];
  }
  function renderLA(p) {
    const f = LA_PRES.find((x) => x[0] === p);
    const one = (s, cap) => { const [w, h] = laSize(p, s); return shot(`assets/live-activity/${p}-${s}.png`, cap, f[2], w, h, f[5], /-art$/.test(s)); };
    let h = `<p class="gallery-h">${f[1]}, without art and then with the show’s art</p><div class="gallery">`;
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
    fillHoles($('#la-gallery'), 'live-activity');
  }

  /* ================================================================ device mockups */
  // An iPhone 18 Pro in points, after Apple's iOS 27 UI kit: screen 402 × 874, status bar 62, Dynamic Island 95 × 37
  // at 14 from the top, home indicator 144 × 5 at 8 from the bottom. The screen's corner is a superellipse 71 pt
  // across, exponent 2.31 (Apple's continuous corner, about a 62 pt radius at the diagonal). Each phone is laid out at
  // true points, 1 pt = 1 px, and scaled as a whole to its box, so the 3x renders inside stay sharp and every widget
  // keeps its real size relative to the screen.
  const SCR = { w: 402, h: 874 }, BAND = 13;
  const PH = { w: SCR.w + BAND * 2, h: SCR.h + BAND * 2 };
  function superellipse(w, h, a, n) {
    const e = 2 / n, pts = [];
    [[w - a, a, 1, -1], [w - a, h - a, 1, 1], [a, h - a, -1, 1], [a, a, -1, -1]].forEach(([cx, cy, sx, sy], c) => {
      for (let i = 0; i <= 24; i++) {
        const t = (i / 24) * (Math.PI / 2);
        const u = c % 2 === 0 ? Math.sin(t) : Math.cos(t), v = c % 2 === 0 ? Math.cos(t) : Math.sin(t);
        pts.push(`${(cx + sx * a * Math.pow(u, e)).toFixed(2)} ${(cy + sy * a * Math.pow(v, e)).toFixed(2)}`);
      }
    });
    return `M${pts.join('L')}Z`;
  }
  const SCREEN_PATH = superellipse(SCR.w, SCR.h, 71, 2.31);
  // The status bar glyphs, from the same UI kit: signal, Wi-Fi, a full battery.
  const GLYPH = {
    signal: '<svg width="20.33" height="13.67" viewBox="0 0 20.33 13.67">' + [6.33, 8.67, 11, 13.67].map((h, i) => `<rect x="${(i * 5.667).toFixed(2)}" y="${(13.67 - h).toFixed(2)}" width="3.33" height="${h}" rx="1.67" fill="currentColor"/>`).join('') + '</svg>',
    wifi: '<svg width="19.33" height="14.33" viewBox="0 0 19.33 14.33"><path fill-rule="evenodd" fill="currentColor" d="M0.42 5.54C0.9 6.04 1.66 5.96 2.28 5.41C4.31 3.58 6.84 2.64 9.67 2.64C12.5 2.64 15.05 3.61 17.06 5.41C17.66 5.97 18.42 6.03 18.92 5.54C19.42 5.03 19.49 4.25 18.98 3.71C16.83 1.52 13.33 0 9.67 0C6.01 0 2.49 1.53 0.36 3.72C-0.16 4.25 -0.1 5.03 0.42 5.56ZM3.95 9.14C4.51 9.68 5.22 9.62 5.85 9.11C6.88 8.29 8.25 7.73 9.67 7.75C11.07 7.75 12.44 8.29 13.49 9.12C14.12 9.64 14.86 9.67 15.4 9.12C15.93 8.58 16.02 7.75 15.46 7.23C14.07 5.99 11.99 5.11 9.68 5.11C7.38 5.11 5.28 5.99 3.91 7.23C3.42 7.69 3.32 8.48 3.96 9.14ZM8.73 13.89C9.34 14.48 9.98 14.48 10.6 13.89L11.76 12.78C12.37 12.17 12.5 11.42 11.8 10.9C11.21 10.48 10.47 10.21 9.67 10.21C8.87 10.21 8.11 10.48 7.54 10.91C6.84 11.42 6.98 12.19 7.6 12.78Z"/></svg>',
    battery: '<svg width="29.33" height="13.67" viewBox="0 0 29.33 13.67"><path fill="currentColor" d="M0 6.4C0 4.16 0 3.04 0.44 2.18C0.82 1.43 1.43 0.82 2.18 0.44C3.04 0 4.16 0 6.4 0L19.93 0C22.17 0 23.29 0 24.15 0.44C24.9 0.82 25.51 1.43 25.9 2.18C26.33 3.04 26.33 4.16 26.33 6.4L26.33 7.27C26.33 9.51 26.33 10.63 25.9 11.48C25.51 12.24 24.9 12.85 24.15 13.23C23.29 13.67 22.17 13.67 19.93 13.67L6.4 13.67C4.16 13.67 3.04 13.67 2.18 13.23C1.43 12.85 0.82 12.24 0.44 11.48C0 10.63 0 9.51 0 7.27Z"/><path fill="currentColor" transform="translate(27.33 4.33)" d="M0 0L0 5C0.6 4.86 2 3.75 2 2.5C2 1.25 0.6 0.14 0 0Z"/></svg>',
    flashlight: '<svg width="22" height="22" viewBox="0 0 24 24"><path fill="currentColor" fill-rule="evenodd" d="M7.6 1.6h8.8a1.6 1.6 0 0 1 1.6 1.6v1.9H6V3.2a1.6 1.6 0 0 1 1.6-1.6ZM6 6h12l-2.6 4v10.4a2 2 0 0 1-2 2h-2.8a2 2 0 0 1-2-2V10ZM10.6 14a1.4 1.4 0 1 0 2.8 0 1.4 1.4 0 1 0-2.8 0Z"/></svg>',
    camera: '<svg width="24" height="24" viewBox="0 0 24 24"><path fill="currentColor" fill-rule="evenodd" d="M4.6 6.6h3.3l1.2-1.8a1.3 1.3 0 0 1 1.1-.6h3.6a1.3 1.3 0 0 1 1.1.6l1.2 1.8h3.3A2.6 2.6 0 0 1 22 9.2v8.6a2.6 2.6 0 0 1-2.6 2.6H4.6A2.6 2.6 0 0 1 2 17.8V9.2a2.6 2.6 0 0 1 2.6-2.6ZM7.5 13.4a4.5 4.5 0 1 0 9 0 4.5 4.5 0 1 0-9 0ZM9 13.4a3 3 0 1 0 6 0 3 3 0 1 0-6 0Z"/></svg>',
    search: '<svg width="13" height="13" viewBox="0 0 16 16"><path fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" d="M6.8 12.1a5.3 5.3 0 1 0 0-10.6 5.3 5.3 0 0 0 0 10.6ZM10.7 10.7l3.8 3.8"/></svg>',
  };
  // The wallpaper: our own night sky, a faint globe rising from the foot with your meridian lit, and a few stars.
  // The stars sit only where each screen is open, so none lands on a widget, an icon or a label.
  const STARS = {
    'home-large': [[22, 452, 0.9, 0.3], [384, 560, 0.8, 0.26], [70, 668, 1, 0.34], [318, 702, 0.8, 0.26], [150, 712, 0.7, 0.22]],
    'home-medium': [[22, 300, 0.8, 0.26], [96, 600, 1, 0.34], [330, 578, 0.9, 0.3], [252, 640, 0.7, 0.24], [40, 700, 0.8, 0.24], [362, 690, 0.7, 0.2]],
    lock: [[44, 330, 1, 0.34], [330, 352, 0.8, 0.28], [128, 418, 0.7, 0.24], [362, 470, 1, 0.3], [236, 506, 0.8, 0.26], [70, 548, 0.7, 0.22]],
  };
  function skySVG(kind) {
    const stars = STARS[kind] || [];
    const ellipses = [0.38, 0.72].map((k) => `<ellipse cx="201" cy="1230" rx="${(560 * k).toFixed(1)}" ry="560"/>`).join('');
    const id = 'dev-mer' + (++uid);
    // A faint globe rising from the foot, and your meridian, lit where it leaves the rim and gone before the dock.
    return `<svg class="dev-sky-lines" viewBox="0 0 ${SCR.w} ${SCR.h}" width="${SCR.w}" height="${SCR.h}" aria-hidden="true">` +
      `<defs><linearGradient id="${id}" x1="0" y1="670" x2="0" y2="722" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#F4EFE4" stop-opacity=".22"/><stop offset="1" stop-color="#F4EFE4" stop-opacity="0"/></linearGradient></defs>` +
      `<g fill="none" stroke="#F4EFE4" stroke-width="1" stroke-opacity=".05"><circle cx="201" cy="1230" r="560"/>${ellipses}</g>` +
      `<path d="M201 670 V 722" stroke="url(#${id})" stroke-width="1"/><circle cx="201" cy="670" r="1.5" fill="#F4EFE4" fill-opacity=".55"/>` +
      stars.map(([x, y, r, o]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="#F4EFE4" fill-opacity="${o}"/>`).join('') + '</svg>';
  }
  const at = (x, y, w, h) => `left:${x}px;top:${y}px;width:${w}px;height:${h}px`;
  // A render placed on the screen at its point size; with art holes, the show's art fills in behind it (fillHoles).
  function placed(folder, file, x, y, w, h, corner, extra = '') {
    const img = `<img src="assets/${folder}/${file}" alt="" width="${w}" height="${h}" decoding="async">`;
    if (/-art\.png$/.test(file)) return `<span class="holes dev-r ${corner} ${extra}" data-holes="${file}" style="${at(x, y, w, h)}">${img}</span>`;
    return `<span class="dev-r ${corner} ${extra}" style="${at(x, y, w, h)}">${img}</span>`;
  }
  // The Home Screen grid at 402 pt: widgets in two 158 pt columns 22 apart (338 wide, 32 from each side); app icons
  // 60 pt on a 90 pt pitch, each pair centred on its widget column; rows 98 pt apart from y 76, so a medium widget
  // spans two rows and a large one four.
  const COLX = [36, 126, 216, 306], WCOLX = [32, 212], ROWY = (r) => 76 + r * 98;
  const BAR_W = [34, 26, 40, 30, 22, 36, 28, 38];
  let tileN = 0;
  // A dock icon has no name, so no bar under it.
  function tile(x, y, label, named = true) {
    const n = tileN++;
    const name = label ? `<span class="dev-label">${label}</span>` : named ? `<span class="dev-bar" style="width:${BAR_W[n % BAR_W.length]}px"></span>` : '';
    const face = label ? `<span class="dev-icon is-app">${iconSVG('dark')}</span>` : `<span class="dev-icon" style="--tint:${0.07 + (n * 7 % 5) * 0.012}"></span>`;
    return `<span class="dev-app" style="left:${x}px;top:${y}px">${face}${name}</span>`;
  }
  const row = (r, cols = [0, 1, 2, 3]) => cols.map((c) => tile(COLX[c], ROWY(r))).join('');
  function statusBar(time, glyphs = ['signal', 'wifi', 'battery'], timeX = 0, timeW = 138.5) {
    return `<div class="dev-status">${time ? `<span class="dev-time" style="left:${timeX}px;width:${timeW}px">${time}</span>` : ''}` +
      `<span class="dev-glyphs">${glyphs.map((g) => GLYPH[g]).join('')}</span></div>`;
  }
  function dock() {
    return `<span class="dev-search">${GLYPH.search}Search</span><span class="dev-dock"></span>` + COLX.map((x) => tile(x, 874 - 12 - 76, '', false)).join('');
  }
  const SCREENS = {
    // Two Home Screen pages at 19:00 on Monday, when House of the Dragon is out at 22:10 and Silo on Wednesday.
    'home-large': () => statusBar('19:00') + placed('widgets', 'large-busy-art.png', WCOLX[0], ROWY(0), 338, 354, 'r-home') + row(4) + row(5) + dock(),
    'home-medium': () => statusBar('19:00') + placed('widgets', 'medium-countdown-art.png', WCOLX[0], ROWY(0), 338, 158, 'r-home') +
      placed('widgets', 'small-countdown-art.png', WCOLX[0], ROWY(2), 158, 158, 'r-home') +
      tile(COLX[2], ROWY(2), 'Meridian') + tile(COLX[3], ROWY(2)) + row(3, [2, 3]) + row(4) + dock(),
    // The Lock Screen at 19:00 on Monday, two hours before Silo's expected 21:00: the date, the clock and the Live
    // Activity banner at the foot. No Lock Screen widgets here: they would show the soonest drop, Silo, and every
    // widget render tells a different story (a date-only Wonder Man, House of the Dragon at 22:10); the widget
    // gallery below shows them.
    lock: () => statusBar('', ['signal', 'wifi', 'battery']) +
      '<div class="dev-date"><span>Monday 2 November</span></div>' +
      '<div class="dev-clock">19:00</div>' +
      placed('live-activity', 'lock-countingDown-art.png', 21, 594, 360, 157, 'r-home') +
      `<span class="dev-btn" style="left:46px">${GLYPH.flashlight}</span><span class="dev-btn" style="right:46px">${GLYPH.camera}</span><span class="dev-home"></span>`,
    // The island over the Home Screen. Compact widens it to 221 pt, so the status bar keeps only the time and battery;
    // expanded covers the status bar, 371 pt wide, from the island's top.
    compact: () => statusBar('19:00', ['battery'], 14, 72) + row(0) + row(1) +
      placed('live-activity', 'compact-countingDown-art.png', (SCR.w - 220.67) / 2, 14.5, 220.67, 36, 'r-capsule', 'island'),
    expanded: () => row(0) + row(1) + placed('live-activity', 'expanded-countingDown-art.png', (SCR.w - 371) / 2, 14, 371, 118.67, 'r-expanded', 'island'),
  };
  function phoneHTML(kind) {
    tileN = 0;
    const band = 'dev-band' + (++uid);
    const bands = `<svg class="dev-bands" width="${PH.w}" height="${PH.h}" viewBox="0 0 ${PH.w} ${PH.h}"><defs><linearGradient id="${band}" x1=".2" y1="0" x2=".8" y2="1">` +
      ['#5b5c61', '#2b2c2f', '#48494d', '#232427', '#404145'].map((c, i) => `<stop offset="${[0, 0.22, 0.48, 0.74, 1][i]}" stop-color="${c}"/>`).join('') +
      `</linearGradient></defs><g transform="translate(${BAND} ${BAND})" fill="none" stroke-linejoin="round">` +
      `<path d="${SCREEN_PATH}" stroke="url(#${band})" stroke-width="26"/><path d="${SCREEN_PATH}" stroke="#2c2c2d" stroke-width="20"/>` +
      `<path d="${SCREEN_PATH}" stroke="#0b0b0c" stroke-width="18.5"/></g></svg>`;
    return `<div class="dev-phone" aria-hidden="true">${bands}<div class="dev-screen dev-${kind}" style="clip-path:path('${SCREEN_PATH}')">` +
      `<div class="dev-sky">${skySVG(kind)}</div>${SCREENS[kind]()}${kind === 'expanded' || kind === 'compact' ? '' : '<span class="dev-island"></span>'}</div></div>`;
  }
  // Scale each phone to its box: the box's size comes from CSS (aspect-ratio), so nothing below it moves.
  const devFit = 'ResizeObserver' in window ? new ResizeObserver((entries) => entries.forEach((e) => {
    const w = e.contentRect.width; if (w) e.target.style.setProperty('--s', String(w / PH.w));
  })) : null;
  function renderMockups() {
    $$('.dev[data-dev]').forEach((box) => {
      box.innerHTML = phoneHTML(box.dataset.dev);
      // The observer's first callback lands before the first paint; measure by hand only without one.
      if (devFit) { devFit.observe(box); return; }
      const w = box.getBoundingClientRect().width; if (w) box.style.setProperty('--s', String(w / PH.w));
    });
    $$('.showcase').forEach((s) => { fillHoles(s, 'widgets'); fillHoles(s, 'live-activity'); });
  }

  /* ================================================================ tabs (WAI-ARIA tabs, automatic activation) */
  // On a phone a tab row scrolls sideways: bring the chosen tab into view by moving the row only, never the page.
  function revealTab(list, tab, smooth) {
    if (!tab || !list.offsetParent || list.scrollWidth <= list.clientWidth) return;
    const l = list.getBoundingClientRect(), t = tab.getBoundingClientRect();
    const pad = parseFloat(getComputedStyle(list).paddingLeft) || 0;
    const dx = t.left < l.left + pad ? t.left - l.left - pad : t.right > l.right - pad ? t.right - l.right + pad : 0;
    if (dx) list.scrollTo({ left: list.scrollLeft + dx, behavior: smooth && !reduceMotion.matches ? 'smooth' : 'auto' });
  }
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
      if (focus) tab.focus({ preventScroll: true });
      revealTab(list, tab, initial !== true);
      if (onSelect) onSelect(tab.dataset.tab, tab);
    };
    let initial = true;
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
    initial = false;
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
    $$('[role="tablist"]', view).forEach((l) => revealTab(l, $('[aria-selected="true"]', l), false));
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

  /* ================================================================ show art */
  // Where a show is named, it shows its own art, loaded at runtime from TVmaze's and AniList's image servers as the
  // app loads it, and never stored in this repo (rule 9, D-37). These are the images the app's ShowArtwork picks:
  // `hero` is the wide background (TVmaze: sharp first, then main, then nearest 1920 px wide; for an anime, its
  // AniList banner, a strip), which the app also crops into an Upcoming row's square; `poster` is TVmaze's 210 × 295
  // poster or AniList's large cover (`widgetPoster`); `cover` is an anime's extra-large cover, which the widgets use
  // instead of the strip. `night` is the base the app's ArtworkPalette works out from the hero art, for the hero's
  // buttons; the phones in index.html carry the same computed bases. `name` is the show as the app's samples name it.
  // Each image is [url, width, height], looked up 2 Nov 2026.
  const TVMAZE = 'https://static.tvmaze.com/uploads/images/';
  const ANILIST = 'https://s4.anilist.co/file/anilistcdn/media/anime/';
  const SHOWS = {
    silo: { name: 'Silo', hero: [TVMAZE + 'original_untouched/460/1151687.jpg', 1920, 1080], poster: [TVMAZE + 'medium_portrait/631/1577677.jpg', 210, 295], night: '#1C1B1A' },
    wednesday: { name: 'Wednesday', hero: [TVMAZE + 'original_untouched/423/1059627.jpg', 1280, 720], night: '#181924' },
    dragon: { name: 'House of the Dragon', hero: [TVMAZE + 'original_untouched/218/547436.jpg', 1920, 1080], poster: [TVMAZE + 'medium_portrait/627/1568449.jpg', 210, 295] },
    severance: { name: 'Severance', hero: [TVMAZE + 'original_untouched/384/960581.jpg', 3840, 2160], poster: [TVMAZE + 'medium_portrait/548/1371406.jpg', 210, 295] },
    wonderman: { name: 'Wonder Man', hero: [TVMAZE + 'original_untouched/551/1377680.jpg', 2048, 1152], poster: [TVMAZE + 'medium_portrait/613/1532943.jpg', 210, 295] },
    andor: { name: 'Andor', hero: [TVMAZE + 'original_untouched/418/1046464.jpg', 1920, 1080], poster: [TVMAZE + 'medium_portrait/564/1411766.jpg', 210, 295] },
    from: { name: 'From', poster: [TVMAZE + 'medium_portrait/621/1554646.jpg', 210, 295] },
    tracker: { poster: [TVMAZE + 'medium_portrait/644/1610559.jpg', 210, 295] },
    lastofus: { name: 'The Last of Us', poster: [TVMAZE + 'medium_portrait/563/1409008.jpg', 210, 295] },
    frieren: { name: "Frieren: Beyond Journey's End", strip: true, hero: [ANILIST + 'banner/182255-wyHvp6zJbWsO.jpg', 1900, 400], cover: [ANILIST + 'cover/large/bx154587-qQTzQnEJJ3oB.jpg', 460, 649], poster: [ANILIST + 'cover/medium/bx154587-qQTzQnEJJ3oB.jpg', 230, 325] },
    sololeveling: { name: 'Solo Leveling', strip: true, cover: [ANILIST + 'cover/large/bx151807-it355ZgzquUd.png', 460, 609], poster: [ANILIST + 'cover/medium/bx151807-it355ZgzquUd.png', 230, 305] },
  };
  const SHOW_BY_NAME = Object.fromEntries(Object.values(SHOWS).filter((x) => x.name).map((x) => [x.name, x]));
  // The image a widget or Live Activity saves for a show (ShowArtwork.widget and .widgetPoster, D-46/D-47): `wide` is
  // the key art unless it's a banner strip, then the cover; `poster` is the 2:3 poster.
  function widgetImage(show, kind) {
    if (!show) return null;
    return kind === 'wide' ? (show.strip ? null : show.hero) || show.cover || show.poster : show.poster || show.cover;
  }
  function setArt(art, key, use = art.dataset.use || 'hero') {
    const src = SHOWS[key] && SHOWS[key][use];
    let img = $('img', art);
    // A different show gets a fresh image, so the last show's art never sits under the new title while it loads.
    if (img && (!src || img.getAttribute('src') !== src[0])) { img.remove(); img = null; }
    if (!src) return;
    if (!img) {
      img = document.createElement('img');
      // No referrer: TVmaze and AniList get the image request, not which page made it.
      img.alt = ''; img.decoding = 'async'; img.referrerPolicy = 'no-referrer';
      // A failed or blocked image is hidden, so the placeholder underneath shows, never a broken-image icon.
      img.addEventListener('error', () => { img.hidden = true; });
      // It fades in as it loads, as the app's art does (ArtworkLoaderView: 0.35 s ease out, none with Reduce Motion).
      // Hidden from here only, just before its src is set, so art never stays invisible if this script stops. The
      // hero's art is left out: its whole layer fades (.arrive). Widget and Live Activity art never fades (fillHoles).
      if (!reduceMotion.matches && !art.closest('.hero')) {
        img.style.opacity = '0';
        img.addEventListener('load', () => {
          img.style.opacity = '';
          if (img.animate) img.animate([{ opacity: 0 }, { opacity: 1 }], { duration: 350, easing: 'cubic-bezier(0, 0, .58, 1)' });
        }, { once: true });
      }
      art.prepend(img);
    }
    const hero = !!art.closest('.hero');
    img.loading = hero ? 'eager' : 'lazy';
    if (hero) img.fetchPriority = 'high';
    img.width = src[1]; img.height = src[2]; img.hidden = false; img.src = src[0];
  }
  function renderArt() { $$('.art[data-show]').forEach((a) => setArt(a, a.dataset.show)); }

  /* ================================================================ Welcome wall */
  // WelcomeWall.arrange: TV posters, the first three (wideTV) swapped for wide key art; anime covers, every third
  // (index 1, 4, …) as its wide banner when it has one; TV and anime alternate, then are dealt across the three rows in
  // turn, at most 8 a row. WelcomeWallView: rows 128, 172 and 128 tall, 8 apart; posters 2:3 and wide art 16:9, rounded
  // to the point; each row its tiles several times over (at least 3, enough to cover 1000 pt), sliding one run at 9 pt
  // a second, alternate rows the other way, each starting part-way into its run. The art loads like every named show's.
  const WALL = { tv: ['silo', 'dragon', 'severance', 'wonderman', 'andor', 'from', 'tracker', 'lastofus'], anime: ['frieren', 'sololeveling'] };
  const WALL_HEIGHTS = [128, 172, 128], WALL_LEADS = [0, 0.42, 0.18], WALL_GAP = 8, WALL_SPEED = 9, WALL_PER_ROW = 8;
  function renderWall() {
    const host = $('#welcome-wall'); if (!host) return;
    const tv = WALL.tv.map((key, i) => ({ key, wide: i < 3 && !!SHOWS[key].hero }));
    const anime = WALL.anime.map((key, i) => ({ key, wide: i % 3 === 1 && !!SHOWS[key].hero }));
    const merged = [];
    for (let i = 0; i < Math.max(tv.length, anime.length); i++) [tv[i], anime[i]].forEach((t) => { if (t) merged.push(t); });
    const rows = WALL_HEIGHTS.map(() => []);
    merged.slice(0, rows.length * WALL_PER_ROW).forEach((t, i) => rows[i % rows.length].push(t));
    host.innerHTML = '<div class="wall-rows">' + rows.map((tiles, r) => {
      const h = WALL_HEIGHTS[r], lead = WALL_LEADS[r], leftward = r % 2 === 0;
      const width = (t) => Math.round(t.wide ? (h * 16) / 9 : (h * 2) / 3);
      const run = tiles.reduce((sum, t) => sum + width(t) + WALL_GAP, 0);
      const copies = Math.max(3, Math.ceil(1000 / run) + 1);
      const dur = run / WALL_SPEED;
      // Leftward rows slide from 0 to -run, rightward ones from -run to 0; a negative delay starts each `lead` of a run
      // in, and --x0 is that same starting place, where the row stays when Reduce Motion drops the animation.
      const x0 = leftward ? -lead * run : lead * run - run;
      const use = (t) => (t.wide ? 'hero' : SHOWS[t.key].cover ? 'cover' : 'poster');
      const cells = tiles.map((t) => `<span class="art" data-show="${t.key}" data-use="${use(t)}" style="width:${width(t)}px"></span>`).join('');
      return `<div class="wall-row" style="--h:${h}px"><div class="wall-strip" style="--run:${run}px;--x0:${x0.toFixed(1)}px;--dur:${dur.toFixed(2)}s;--delay:${(-lead * dur).toFixed(2)}s;--drift:wall-${leftward ? 'left' : 'right'}">${cells.repeat(copies)}</div></div>`;
    }).join('') + '</div><div class="wall-top"></div>';
  }

  /* ================================================================ hero, motion, checklist */
  // The hero's three buttons: Silo's art is warm (orange), Wednesday's cool (blue-violet), then no art at all.
  const HERO = {
    warm: { show: 'silo', title: 'Silo', cd: 7807, meta: 'S4E1 · Apple TV' },
    cool: { show: 'wednesday', title: 'Wednesday', cd: 15022, meta: 'S3E1 · Netflix' },
  };
  const NO_ART = '#1C1C1C';
  function bindHero() {
    const hero = $('#hero'); if (!hero) return;
    const art = $('#hero-art'), code = $('#hero-night'), phone = $('.hero-phone', hero);
    $$('.pick button', hero).forEach((b) => b.addEventListener('click', () => {
      const k = b.dataset.art, h = HERO[k];
      // The same choice again changes nothing, so the art doesn't fade in again (the app keeps art whose URL is the same).
      if (hero.dataset.art === k) return;
      $$('.pick button', hero).forEach((x) => x.setAttribute('aria-pressed', String(x === b)));
      const night = h ? SHOWS[h.show].night : NO_ART;
      hero.dataset.art = k;
      hero.style.setProperty('--night', night); phone.style.setProperty('--night', night);
      code.textContent = night;
      art.hidden = !h;
      if (!h) return; // No art yet: the same show on the plain base, as before its art loads.
      if (art.dataset.show !== h.show) {
        art.dataset.show = h.show; setArt(art, h.show);
        $('.hl-title', phone).textContent = h.title; $('.meta', phone).textContent = h.meta;
        const cd = $('[data-cd]', phone); cd.dataset.cd = String(h.cd); arm(cd); renderOutLines(phone); tick();
      }
      art.className = 'art ' + k;
      if (!reduceMotion.matches) { art.classList.remove('arrive'); void art.offsetWidth; art.classList.add('arrive'); }
    }));
    // Fetch the other show's art once the page is idle, so the first switch doesn't wait for it.
    const preload = () => { const i = new Image(); i.referrerPolicy = 'no-referrer'; i.src = SHOWS[HERO.cool.show].hero[0]; };
    if ('requestIdleCallback' in window) requestIdleCallback(preload, { timeout: 4000 }); else setTimeout(preload, 2000);
  }
  function bindMotion() {
    const b = $('#motion-play'); if (!b) return;
    b.addEventListener('click', () => { const a = $('#motion-art'); a.classList.remove('in'); void a.offsetWidth; requestAnimationFrame(() => a.classList.add('in')); });
    // With Reduce Motion there's nothing to play: the app skips this fade too, so say so instead.
    const note = document.createElement('p'); note.className = 'small'; note.id = 'motion-note';
    note.textContent = 'Reduce Motion is on, so the app skips this fade too.';
    b.after(note);
    const sync = () => { b.disabled = reduceMotion.matches; note.hidden = !reduceMotion.matches; };
    sync(); reduceMotion.addEventListener('change', sync);
  }

  /* ================================================================ start */
  renderLogos(); renderTokens(); renderContrast(); renderZone(); renderWall(); renderArt(); renderMockups();
  bindTabs(); bindCustomType(); decorate();
  buildRail(); bindRail(); bindSearch(); bindHero(); bindMotion(); bindDemo();
  buildIndex();
  route(location.hash.slice(1) || 'overview');
  document.documentElement.classList.add('routed');
  initCountdowns();
  // Web fonts can change line heights after the first layout; keep a deep link on its target.
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(() => { if (lastTarget && !lastTarget.classList.contains('view') && !userMoved) lastTarget.scrollIntoView({ block: 'start' }); markHere(); });
})();
