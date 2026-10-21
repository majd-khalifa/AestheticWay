// Operator-run k6 harness. No load test is executed by the Flutter test suite.
// Read docs/SCALABILITY_LOAD_TEST_PLAN.md before enabling it.
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';
import { SharedArray } from 'k6/data';

const target = (__ENV.AW_LOAD_BASE_URL || '').replace(/\/$/, '');
const match = /^https:\/\/([a-z0-9.-]+)(?::\d+)?\/api\/v1$/i.exec(target);
const forbidden = ['aestheticway.ae', 'www.aestheticway.ae', 'api.aestheticway.ae'];
if (__ENV.AW_LOAD_AUTHORIZED !== 'staging-synthetic-only' || !match ||
    match[1].toLowerCase() !== (__ENV.AW_LOAD_APPROVED_HOST || '').toLowerCase() ||
    forbidden.includes(match[1].toLowerCase())) {
  throw new Error('Refusing load: configure an explicitly authorized HTTPS staging host and synthetic-only acknowledgement.');
}

const mode = __ENV.AW_LOAD_SCENARIO || 'clinics100';
const targets = { clinics100: 100, catalog500: 500, products1000: 1000,
  search: 50, home: 50, home_media: 50, tab_mix: 50, leads: 5, cold_warm: 50,
  failure: 50, ramps: 500 };
const peak = targets[mode];
const approvedCap = Number(__ENV.AW_LOAD_MAX_VUS || 0);
if (!peak || !Number.isInteger(approvedCap) || approvedCap < peak || approvedCap > 1000) {
  throw new Error('Requested scenario exceeds the explicitly configured staging VU budget.');
}

// Optional synthetic accounts are loaded from an untracked CI-mounted file.
// Never bundle/archive this file or log JWTs. Public API scenarios can omit it;
// those runs measure public endpoint service traffic, not authenticated app UX.
const accounts = new SharedArray('synthetic-accounts', () =>
  __ENV.AW_LOAD_FIXTURE_FILE ? JSON.parse(open(__ENV.AW_LOAD_FIXTURE_FILE)) : []);
const media = new SharedArray('synthetic-media', () =>
  __ENV.AW_LOAD_MEDIA_FILE ? JSON.parse(open(__ENV.AW_LOAD_MEDIA_FILE)) : []);
if (mode === 'home_media' && (!media.length || media.some((url) => {
  const host = /^https:\/\/([a-z0-9.-]+)(?::\d+)?\//i.exec(url);
  return !host || host[1].toLowerCase() !== (__ENV.AW_LOAD_APPROVED_MEDIA_HOST || '').toLowerCase();
}))) throw new Error('Media scenario requires synthetic fixtures on the explicitly approved CDN host.');
if (mode === 'leads' && (accounts.length < peak || accounts.some((a) =>
  a.synthetic !== true || !a.access_token || !a.clinic_id || !a.phone || !a.name))) {
  throw new Error('Lead scenario requires distinct authorized synthetic patient fixtures.');
}

const limited = new Rate('rate_limited');
const failures = new Rate('unexpected_status');
const characters = new Counter('decoded_body_characters');
const latency = new Trend('catalog_latency_ms', true);

export const options = {
  scenarios: { selected: {
    executor: 'ramping-vus', startVUs: 0, gracefulRampDown: '30s',
    stages: mode === 'ramps' ? [
      { duration: '30s', target: 50 }, { duration: '1m', target: 100 },
      { duration: '1m', target: peak }, { duration: '1m', target: 100 },
      { duration: '1m', target: 0 },
    ] : [{ duration: '30s', target: peak }, { duration: '2m', target: peak },
      { duration: '30s', target: 0 }],
  } },
  // These are operator stop conditions, not achieved performance claims.
  thresholds: { unexpected_status: [{ threshold: 'rate<0.10', abortOnFail: true, delayAbortEval: '30s' }] },
  discardResponseBodies: false,
  // Do not emit URL tags containing signed media tokens or patient identifiers.
  systemTags: ['status', 'method', 'name', 'scenario', 'expected_response'],
};

function params(name) {
  const account = accounts.length ? accounts[(__VU - 1) % accounts.length] : null;
  return { tags: { name, scenario: mode }, timeout: '15s', redirects: 0,
    headers: { Accept: 'application/json', 'Accept-Language': 'en',
      ...(account ? { Authorization: `Bearer ${account.access_token}` } : {}) } };
}

function observe(response, name) {
  limited.add(response.status === 429);
  failures.add(response.status !== 200 && response.status !== 201 && response.status !== 429);
  latency.add(response.timings.duration, { route: name });
  characters.add((response.body || '').length); // Use k6 data_received for wire bytes.
  if (response.status === 429 || response.status === 503) {
    const value = response.headers['Retry-After'];
    const seconds = value && /^\d+$/.test(value) ? Number(value)
      : value ? Math.max(0, (Date.parse(value) - Date.now()) / 1000) : 1;
    // No immediate retry; operator can stop a long cooldown run externally.
    sleep((Number.isFinite(seconds) ? seconds : 1) + Math.random());
  }
  return response;
}

function get(path, name) {
  const response = observe(http.get(`${target}/${path}`, params(name)), name);
  if (response.status === 200 && name !== 'home') {
    const body = response.json();
    check(body, { 'bounded paginated envelope': (b) => Array.isArray(b.results) && b.results.length <= 20 });
  }
}

export default function () {
  if (mode === 'leads') {
    // At most one lead per VU for this whole run. No write retries.
    if (__ITER === 0) {
      const a = accounts[__VU - 1];
      const p = params('consultation'); p.headers['Content-Type'] = 'application/json';
      observe(http.post(`${target}/leads/`, JSON.stringify({ clinic: a.clinic_id,
        patient_name: a.name, patient_phone: a.phone, lead_type: 'consultation',
        consent_accepted: true, notes: 'Authorized synthetic load fixture' }), p), 'consultation');
    }
    sleep(5); return;
  }
  if (mode === 'home' || mode === 'home_media') {
    get('home/feed/', 'home');
    if (mode === 'home_media') {
      for (const url of media.slice(0, 3)) {
        // Media uses no API bearer token and preserves the exact signed URL.
        observe(http.get(url, { tags: { name: 'approved_synthetic_media' },
          timeout: '15s', redirects: 0 }), 'approved_synthetic_media');
      }
    }
  }
  else if (mode === 'search') get(`clinics/?page=1&page_size=20&city=${__ITER % 2 ? 'dubai' : 'abu%20dhabi'}&search=${__ITER % 2 ? 'synthetic' : 'fixture'}`, 'clinic_search');
  else if (mode === 'products1000') get('products/?page=1&page_size=20', 'products');
  else if (mode === 'tab_mix') {
    // HTTP approximation only. Device tests must measure real tab rendering.
    const route = ['products', 'clinics', 'offers', 'articles'][__ITER % 4];
    get(`${route}/?page=1&page_size=20`, route);
  } else if (mode === 'catalog500') {
    const route = ['products', 'practitioners', 'offers', 'articles'][__VU % 4];
    get(`${route}/?page=${1 + (__ITER % 3)}&page_size=20`, route);
  } else get('clinics/?page=1&page_size=20', 'clinics');
  // cold_warm/failure change only through an operator-controlled isolated
  // staging cache or fault proxy. This script never flushes caches or kills a service.
  sleep(2 + Math.random() * 3);
}
