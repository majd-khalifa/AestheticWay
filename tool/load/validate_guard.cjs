// Offline initialization checks only. This never loads k6 or sends requests.
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const assert = require('node:assert/strict');
const source = fs.readFileSync(path.join(__dirname, 'staging_catalog.js'), 'utf8')
  .replace(/^import .*;$/gm, '')
  .replace('export const options', 'const options')
  .replace('export default function ()', 'function scenario()');
const valid = { AW_LOAD_AUTHORIZED: 'staging-synthetic-only',
  AW_LOAD_BASE_URL: 'https://isolated-staging.example.test/api/v1',
  AW_LOAD_APPROVED_HOST: 'isolated-staging.example.test',
  AW_LOAD_MAX_VUS: '100', AW_LOAD_SCENARIO: 'clinics100' };
function initialize(env) {
  let requests = 0;
  const metric = function () { this.add = () => {}; };
  vm.runInNewContext(source, { __ENV: env, Counter: metric, Rate: metric,
    SharedArray: function (_, create) { return create(); },
    Trend: metric, http: { get: () => { requests++; throw Error('Unexpected HTTP'); } },
    check: () => {}, sleep: () => {}, open: () => { throw Error('Unexpected fixture read'); } });
  assert.equal(requests, 0);
}
for (const env of [{}, { ...valid, AW_LOAD_AUTHORIZED: '' },
  { ...valid, AW_LOAD_BASE_URL: 'https://aestheticway.ae/api/v1', AW_LOAD_APPROVED_HOST: 'aestheticway.ae' },
  { ...valid, AW_LOAD_APPROVED_HOST: 'another.example.test' },
  { ...valid, AW_LOAD_SCENARIO: 'products1000' },
  { ...valid, AW_LOAD_SCENARIO: 'leads' },
  { ...valid, AW_LOAD_SCENARIO: 'home_media' }]) {
  assert.throws(() => initialize(env));
}
initialize(valid);
console.log('PASS: seven unsafe/unconfigured initializations rejected; one configured staging initialization accepted; zero HTTP requests.');
