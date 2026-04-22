import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://4.193.141.181:3001';

export const options = {
  scenarios: {
    soak_1000_vu_5m: {
      executor: 'constant-vus',
      vus: 1000,
      duration: '5m',
      gracefulStop: '30s',
    },
  },
  tags: {
    cluster: 'devops-monitoring',
    environment: 'dev',
    node: 'app-node',
    role: 'application',
    service: 'devops-app',
    test_type: 'k6-load',
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<0.2', 'p(99)<0.5'],
    checks: ['rate>0.99'],
  },
  summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function requestHealth() {
  const res = http.get(`${BASE_URL}/health`, {
    tags: { endpoint: '/health', method: 'GET', name: 'health' },
  });

  check(res, {
    'health status 200': (r) => r.status === 200,
  });
}

function requestUsers() {
  const id = randomInt(1, 5);
  const list = http.get(`${BASE_URL}/api/users`, {
    tags: { endpoint: '/api/users', method: 'GET', name: 'users_list' },
  });
  check(list, {
    'users list status 200': (r) => r.status === 200,
  });

  const detail = http.get(`${BASE_URL}/api/users/${id}`, {
    tags: { endpoint: '/api/users/:id', method: 'GET', name: 'users_detail' },
  });
  check(detail, {
    'users detail status 200': (r) => r.status === 200,
  });
}

function requestProducts() {
  const id = randomInt(1, 5);
  const category = Math.random() < 0.7 ? 'electronics' : 'audio';

  const list = http.get(`${BASE_URL}/api/products?category=${category}`, {
    tags: { endpoint: '/api/products', method: 'GET', name: 'products_list' },
  });
  check(list, {
    'products list status 200': (r) => r.status === 200,
  });

  const detail = http.get(`${BASE_URL}/api/products/${id}`, {
    tags: { endpoint: '/api/products/:id', method: 'GET', name: 'products_detail' },
  });
  check(detail, {
    'products detail status 200': (r) => r.status === 200,
  });
}

export default function () {
  const pick = Math.random();

  if (pick < 0.2) {
    requestHealth();
  } else if (pick < 0.55) {
    requestUsers();
  } else {
    requestProducts();
  }

  sleep(Math.random() * 0.4 + 0.1);
}
