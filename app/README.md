# 📦 Devops Monitoring App

Aplikasi REST API sederhana berbasis **Node.js + Express** yang dirancang sebagai target monitoring dalam arsitektur observability stack. Aplikasi ini mengekspos metrik dalam format **Prometheus** dan digunakan bersama Prometheus + Grafana untuk visualisasi performa secara real-time.

> 🐳 Docker Image: [`trenttzzz/devops-app:latest`](https://hub.docker.com/repository/docker/trenttzzz/devops-app/general)

---

## 📁 Struktur Direktori

```
app/
├── src/
│   ├── index.js                  # Entry point aplikasi
│   ├── metrics.js                # Konfigurasi Prometheus client
│   ├── middleware/
│   │   └── metricsMiddleware.js  # Auto-tracking setiap HTTP request
│   └── routes/
│       ├── health.js             # Health check endpoint
│       ├── users.js              # Resource users (dummy data)
│       └── products.js           # Resource products (dummy data)
├── Dockerfile                    # Multi-stage build, support ARM64 & AMD64
├── .dockerignore
├── package.json
└── README.md
```

---

## 🚀 Endpoints

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/health` | Status kesehatan aplikasi |
| GET | `/metrics` | Prometheus metrics endpoint |
| GET | `/api/users` | Daftar semua users |
| GET | `/api/users/:id` | Detail user berdasarkan ID |
| GET | `/api/products` | Daftar semua products |
| GET | `/api/products/:id` | Detail product berdasarkan ID |
| GET | `/api/products?category=` | Filter product berdasarkan kategori |

---

## 📊 Prometheus Metrics yang Diekspos

| Metric Name | Type | Deskripsi |
|-------------|------|-----------|
| `http_requests_total` | Counter | Total HTTP request masuk, dilabeli method, route, status code |
| `http_request_duration_seconds` | Histogram | Durasi tiap request dalam detik |
| `http_active_connections` | Gauge | Jumlah koneksi aktif saat ini |
| `process_cpu_seconds_total` | Counter | CPU usage proses Node.js |
| `process_resident_memory_bytes` | Gauge | Memory usage proses |
| *(dan default metrics lainnya dari `prom-client`)* | — | — |

---

## 🛠️ Cara Menjalankan

### Prasyarat

Pastikan sudah terinstall salah satu dari berikut:
- [Docker](https://docs.docker.com/get-docker/) (direkomendasikan)
- Node.js v18+ (untuk menjalankan secara lokal tanpa Docker)

---

### ▶️ Opsi 1: Menjalankan via Docker (Direkomendasikan)

#### Pull image dari Docker Hub

```bash
docker pull trenttzzz/devops--app:latest
```

#### Jalankan container

```bash
docker run -d \
  --name devops-app \
  -p 3000:3000 \
  trenttzzz/devops-app:latest
```

#### Verifikasi container berjalan

```bash
docker ps
docker logs devops-app
```

Output log yang diharapkan:
```
✅ App running on port 3000
📊 Metrics available at http://localhost:3000/metrics
```

---

### Opsi 2: Menjalankan Secara Lokal (Tanpa Docker)

#### Clone repository dan masuk ke direktori app

```bash
cd app/
```

#### Install dependencies

```bash
npm install
```

#### Jalankan aplikasi

```bash
# Mode production
npm start

# Mode development (auto-reload)
npm run dev
```

---

### Opsi 3: Menjalankan via Docker Compose (Bersama Monitoring Stack)

Jika ingin menjalankan aplikasi bersama Prometheus dan Grafana sekaligus, gunakan file `docker-compose.yml` yang tersedia di direktori `docker-compose/`:

```bash
cd docker-compose/
docker compose up -d
```

Kemudian akses:
- Aplikasi: `http://localhost:3000`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000` *(port sesuai konfigurasi compose)*

---

## 🧪 Testing Endpoint

Setelah aplikasi berjalan, uji semua endpoint menggunakan `curl` atau Postman.

### Health Check
```bash
curl http://localhost:3000/health
```
Contoh response:
```json
{
  "status": "ok",
  "timestamp": "2025-01-01T00:00:00.000Z",
  "uptime": 123.45,
  "memory": {
    "rss": 30720000,
    "heapTotal": 10485760,
    "heapUsed": 7340032
  }
}
```

### Metrics Endpoint (untuk Prometheus)
```bash
curl http://localhost:3000/metrics
```

### Users API
```bash
# Semua users
curl http://localhost:3000/api/users

# User berdasarkan ID
curl http://localhost:3000/api/users/1
```

### Products API
```bash
# Semua products
curl http://localhost:3000/api/products

# Filter berdasarkan kategori
curl "http://localhost:3000/api/products?category=electronics"

# Product berdasarkan ID
curl http://localhost:3000/api/products/1
```

---

## 🐳 Docker Image Details

### Informasi Image

| Property | Value |
|----------|-------|
| Image Name | `trenttzzz/devops-app` |
| Tag | `latest` |
| Base Image | `node:20-alpine` |
| Platform Support | `linux/amd64`, `linux/arm64` |
| Exposed Port | `3000` |
| Docker Hub | [trenttzzz/devops-app](https://hub.docker.com/repository/docker/trenttzzz/devops-app/general) |

### Platform Support (Multi-Architecture)

Image ini dibangun menggunakan `docker buildx` sehingga mendukung dua arsitektur sekaligus:
- `linux/amd64` — untuk VM/server berbasis Intel/AMD
- `linux/arm64` — untuk VM berbasis ARM (termasuk VM yang digunakan dalam project ini)

Docker akan otomatis memilih layer yang sesuai dengan arsitektur host saat melakukan `docker pull`.

Untuk memverifikasi dukungan multi-platform:
```bash
docker buildx imagetools inspect trenttzzz/devops-app:latest
```

---

## ⚙️ Environment Variables

| Variable | Default | Deskripsi |
|----------|---------|-----------|
| `PORT` | `3000` | Port yang digunakan aplikasi |
| `NODE_ENV` | `production` | Environment mode |

Contoh penggunaan:
```bash
docker run -d \
  -e PORT=8080 \
  -e NODE_ENV=production \
  -p 8080:8080 \
  trenttzzz/devops-app:latest
```

---

## 🔗 Integrasi dengan Prometheus

Tambahkan konfigurasi berikut pada file `prometheus.yml` agar Prometheus dapat melakukan scraping metrik dari aplikasi ini:

```yaml
scrape_configs:
  - job_name: 'devops-app'
    static_configs:
      - targets: ['<APP_NODE_IP>:3000']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

Ganti `<APP_NODE_IP>` dengan IP address VM Application Node.

---

## 📋 Teknologi yang Digunakan

| Teknologi | Versi | Kegunaan |
|-----------|-------|----------|
| Node.js | 20.x | Runtime JavaScript |
| Express | 4.x | Web framework |
| prom-client | latest | Prometheus metrics library |
| Docker | — | Kontainerisasi |
| Docker Buildx | — | Multi-platform image build |
