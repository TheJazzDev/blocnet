import http from 'k6/http';
import { check, sleep } from 'k6';
import exec from 'k6/execution';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3080/api';
const AUTH_TOKEN = __ENV.AUTH_TOKEN || '';
const UPDATE_IDS = (__ENV.UPDATE_IDS || '')
  .split(',')
  .map((value) => value.trim())
  .filter((value) => value.length > 0);
const COMMUNITY_POST_IDS = (__ENV.COMMUNITY_POST_IDS || '')
  .split(',')
  .map((value) => value.trim())
  .filter((value) => value.length > 0);

const READ_HEADERS = AUTH_TOKEN
  ? { Authorization: `Bearer ${AUTH_TOKEN}` }
  : {};
const WRITE_HEADERS = AUTH_TOKEN
  ? {
      Authorization: `Bearer ${AUTH_TOKEN}`,
      'Content-Type': 'application/json',
    }
  : { 'Content-Type': 'application/json' };

export const options = {
  scenarios: {
    readers: {
      executor: 'ramping-vus',
      startVUs: 100,
      stages: [
        { duration: '2m', target: 400 },
        { duration: '3m', target: 1000 },
        { duration: '2m', target: 1000 },
        { duration: '2m', target: 150 },
      ],
      gracefulRampDown: '30s',
      exec: 'readFlow',
    },
    writers: {
      executor: 'constant-vus',
      vus: 40,
      duration: '8m',
      startTime: '1m',
      exec: 'writeFlow',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<900', 'p(99)<1500'],
    'http_req_duration{flow:read}': ['p(95)<700'],
    'http_req_duration{flow:write}': ['p(95)<900'],
  },
};

function pick(list) {
  if (!list.length) return null;
  return list[Math.floor(Math.random() * list.length)];
}

export function readFlow() {
  const updateId = pick(UPDATE_IDS);
  const postId = pick(COMMUNITY_POST_IDS);
  const limit = 40;

  if (updateId) {
    const response = http.get(
      `${BASE_URL}/updates/${updateId}/comments?limit=${limit}`,
      {
        headers: READ_HEADERS,
        tags: { flow: 'read', endpoint: 'update-comments' },
      },
    );
    check(response, {
      'update comments read status is 200': (r) => r.status === 200,
    });
  }

  if (postId) {
    const response = http.get(
      `${BASE_URL}/community-posts/${postId}/comments?limit=${limit}`,
      {
        headers: READ_HEADERS,
        tags: { flow: 'read', endpoint: 'community-comments' },
      },
    );
    check(response, {
      'community comments read status is 200': (r) => r.status === 200,
    });
  }

  sleep(0.4);
}

export function writeFlow() {
  if (!AUTH_TOKEN) {
    sleep(1);
    return;
  }

  const updateId = pick(UPDATE_IDS);
  const postId = pick(COMMUNITY_POST_IDS);
  const iteration = exec.scenario.iterationInTest;
  const body = JSON.stringify({
    content: `load-test-${iteration}`,
  });

  if (updateId) {
    const response = http.post(`${BASE_URL}/updates/${updateId}/comments`, body, {
      headers: WRITE_HEADERS,
      tags: { flow: 'write', endpoint: 'update-comments' },
    });
    check(response, {
      'update comments write status is 201': (r) => r.status === 201,
    });
  }

  if (postId) {
    const response = http.post(
      `${BASE_URL}/community-posts/${postId}/comments`,
      body,
      {
        headers: WRITE_HEADERS,
        tags: { flow: 'write', endpoint: 'community-comments' },
      },
    );
    check(response, {
      'community comments write status is 201': (r) => r.status === 201,
    });
  }

  sleep(1);
}

export default function () {
  readFlow();
}
