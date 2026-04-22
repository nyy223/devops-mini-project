# DevOps Study Case #4

## Anggota Kelompok
| Nama | NRP |
| :--- | :--- |
| Arsyad Rizantha Maulana Salim| 5027221049 |
| Nathan Kho Pancras | 5027231002 |
| Farida Qurrotu A'yuna | 5027231015 |
| Nayla Raissa Azzahra | 5027231054 |
| Azza Farichi Tjahjono | 5027231071 |
| Nayyara Ashila | 5027231083 |

## Daftar Isi

- [DevOps Study Case #4](#devops-study-case-4)
  - [Anggota Kelompok](#anggota-kelompok)
  - [Daftar Isi](#daftar-isi)
  - [Gambaran Arsitektur](#gambaran-arsitektur)
  - [Spesifikasi VM](#spesifikasi-vm)
  - [Informasi Jaringan \& IP Address](#informasi-jaringan--ip-address)
    - [IP Address](#ip-address)
    - [URL Akses Layanan](#url-akses-layanan)
    - [Konfigurasi Jaringan](#konfigurasi-jaringan)
  - [Cara SSH ke VM](#cara-ssh-ke-vm)
    - [Set Permission File Key (wajib, hanya sekali)](#set-permission-file-key-wajib-hanya-sekali)
    - [SSH ke Application Node](#ssh-ke-application-node)
    - [SSH ke Monitoring Node](#ssh-ke-monitoring-node)
    - [Tips: Buat SSH Config (opsional, biar lebih praktis)](#tips-buat-ssh-config-opsional-biar-lebih-praktis)
  - [Firewall Rules (NSG)](#firewall-rules-nsg)
    - [Application Node — Ports yang Dibuka](#application-node--ports-yang-dibuka)
    - [Monitoring Node — Ports yang Dibuka](#monitoring-node--ports-yang-dibuka)
  - [Cara Menjalankan Ulang Terraform](#cara-menjalankan-ulang-terraform)
  - [Cara Menghapus Semua Resources](#cara-menghapus-semua-resources)
  - [Troubleshooting](#troubleshooting)
    - [SSH: "Permission denied (publickey)"](#ssh-permission-denied-publickey)
    - [SSH: "Connection timed out"](#ssh-connection-timed-out)
    - [Docker: Image tidak bisa di-pull](#docker-image-tidak-bisa-di-pull)
    - [Terraform: "Error acquiring the state lock"](#terraform-error-acquiring-the-state-lock)
    - [Kredit Azure Hampir Habis](#kredit-azure-hampir-habis)

---

## Gambaran Arsitektur

```
Internet
    │
    ├──── HTTP :3001 ──────► [ Application Node VM ]
    │                           Private IP: 10.0.1.10
    │                           - Web App / REST API
    │                           - Node Exporter (:9100)
    │
    └──── HTTP :3000 ──────► [ Monitoring Node VM ]
                                Private IP: 10.0.1.20
                                - Prometheus (:9090)
                                - Grafana (:3000)
                                - Alertmanager (:9093)

Kedua VM berada dalam satu Virtual Network (VNet) yang sama,
sehingga bisa saling berkomunikasi melalui private IP secara langsung.
```

---

## Spesifikasi VM

Kedua VM menggunakan spesifikasi yang **identik**:

| Spesifikasi | Detail |
|---|---|
| **VM Size** | `Standard_B2ps_v2` |
| **vCPU** | 2 Core |
| **RAM** | 4 GB |
| **Storage (OS Disk)** | 30 GB (Standard LRS) |
| **Sistem Operasi** | Ubuntu 22.04 LTS |
| **⚠️ Arsitektur CPU** | **ARM64 / AArch64** |
| **OS Image SKU** | `22_04-lts-arm64` |
| **Region Azure** | Southeast Asia (Singapore) |
| **Admin Username** | `azureuser` |
| **Metode Login** | SSH Key (password dinonaktifkan) |

> Dikarenakan batasan kapasitas di region Southeast Asia, kedua VM ini menggunakan arsitektur ARM64 (Aarch64). Seluruh anggota tim wajib memastikan bahwa setiap Docker image, base image, maupun binary yang digunakan pada tahap selanjutnya telah mendukung arsitektur linux/arm64 agar sistem dapat berjalan dengan normal.

---

## Informasi Jaringan & IP Address

### IP Address

| Node | Public IP | Private IP | Fungsi |
|---|---|---|---|
| **Application Node** | `4.193.141.181` | `10.0.1.10` | Web App + Node Exporter |
| **Monitoring Node** | `20.205.153.210` | `10.0.1.20` | Prometheus + Grafana |

### URL Akses Layanan

| Layanan | URL | Keterangan |
|---|---|---|
| **Aplikasi** | `http://4.193.141.181:3001` | Endpoint API utama |
| **Grafana Dashboard** | `http://20.205.153.210:3000` | Visualisasi metrik |
| **Prometheus UI** | `http://20.205.153.210:9090` | Hanya dari dalam VNet |
| **Node Exporter** | `http://10.0.1.10:9100/metrics` | Hanya dari dalam VNet |
| **Alertmanager** | `http://20.205.153.210:9093` | Hanya dari dalam VNet |

### Konfigurasi Jaringan

| Resource | Detail |
|---|---|
| **Resource Group** | `devops-monitoring-dev-rg` |
| **Virtual Network** | `devops-monitoring-vnet` (`10.0.0.0/16`) |
| **Subnet** | `devops-monitoring-subnet` (`10.0.1.0/24`) |

---

## Cara SSH ke VM

File SSH key bernama `devops-project.pem` harus sudah kamu terima dari Person 3.
Simpan file tersebut di folder yang mudah diingat, misalnya `~/.ssh/`.

### Set Permission File Key (wajib, hanya sekali)

```bash
chmod 600 ~/.ssh/devops-project.pem
```

> Tanpa langkah ini, SSH akan menolak key dengan error "Permissions too open".

### SSH ke Application Node

```bash
ssh -i ~/.ssh/devops-project.pem azureuser@4.193.141.181
```

### SSH ke Monitoring Node

```bash
ssh -i ~/.ssh/devops-project.pem azureuser@20.205.153.210
```

### Tips: Buat SSH Config (opsional, biar lebih praktis)

Tambahkan konfigurasi berikut ke file `~/.ssh/config` agar bisa SSH hanya dengan `ssh app-node`:

```
Host app-node
    HostName 4.193.141.181
    User azureuser
    IdentityFile ~/.ssh/devops-project.pem

Host monitoring-node
    HostName 20.205.153.210
    User azureuser
    IdentityFile ~/.ssh/devops-project.pem
```

Setelah itu cukup jalankan:
```bash
ssh app-node
ssh monitoring-node
```

---

## Firewall Rules (NSG)

### Application Node — Ports yang Dibuka

| Port | Protokol | Sumber | Fungsi |
|---|---|---|---|
| `22` | TCP | `0.0.0.0/0` | SSH |
| `3001` | TCP | `0.0.0.0/0` | Akses aplikasi dari internet |
| `9100` | TCP | `10.0.0.0/16` (VNet only) | Node Exporter — scraping Prometheus |
| `9091` | TCP | `10.0.0.0/16` (VNet only) | Custom app metrics |

### Monitoring Node — Ports yang Dibuka

| Port | Protokol | Sumber | Fungsi |
|---|---|---|---|
| `22` | TCP | `0.0.0.0/0` | SSH |
| `3000` | TCP | `0.0.0.0/0` | Akses Grafana dari internet |
| `9090` | TCP | `10.0.0.0/16` (VNet only) | Prometheus UI |
| `9093` | TCP | `10.0.0.0/16` (VNet only) | Alertmanager |

> **Catatan keamanan:** Port Prometheus dan Alertmanager sengaja hanya bisa diakses dari dalam VNet (private), bukan dari internet publik. Kalau kamu perlu akses Prometheus UI dari laptopmu, gunakan SSH tunneling:
> ```bash
> ssh -i ~/.ssh/devops-project.pem -L 9090:localhost:9090 azureuser@20.205.153.210
> # Lalu buka http://localhost:9090 di browser
> ```

---



## Cara Menjalankan Ulang Terraform

Jika ada perubahan konfigurasi infrastruktur yang diperlukan:

```bash
# Masuk ke folder terraform
cd ~/devops-project/terraform

# Pastikan masih login ke Azure
az account show

# Kalau sudah logout, login lagi
az login

# Preview perubahan
terraform plan

# Terapkan perubahan
terraform apply
```

---

## Cara Menghapus Semua Resources

> **PENTING:** Lakukan ini hanya setelah project selesai dan semua screenshot/dokumentasi sudah disimpan.
> Menghapus resources akan menghentikan VM dan menghemat kredit Azure.

```bash
cd ~/devops-project/terraform
terraform destroy
# Ketik 'yes' saat diminta konfirmasi
```

Semua resources di Azure (VM, VNet, NSG, Public IP, dll) akan dihapus dalam ~5 menit.

---


## Troubleshooting

### SSH: "Permission denied (publickey)"

```bash
# Pastikan permission file key sudah benar
chmod 600 ~/.ssh/devops-project.pem

# Coba dengan verbose untuk lihat detail error
ssh -v -i ~/.ssh/devops-project.pem azureuser@4.193.141.181
```

### SSH: "Connection timed out"

VM mungkin sedang reboot atau belum fully booted. Tunggu 2-3 menit lalu coba lagi.
Bisa juga cek status VM di Azure Portal → Virtual Machines.

### Docker: Image tidak bisa di-pull

Pastikan image yang digunakan mendukung ARM64. Cek dengan:
```bash
# Di dalam VM (setelah SSH)
uname -m  # Harusnya: aarch64

# Test pull image
docker pull node:20-alpine
docker run --rm node:20-alpine node --version
```

### Terraform: "Error acquiring the state lock"

```bash
terraform force-unlock <LOCK_ID>
```

### Kredit Azure Hampir Habis

Matikan VM sementara via Azure Portal atau:
```bash
az vm deallocate --resource-group devops-monitoring-dev-rg --name devops-monitoring-app-vm
az vm deallocate --resource-group devops-monitoring-dev-rg --name devops-monitoring-monitoring-vm
```

Untuk menyalakan kembali:
```bash
az vm start --resource-group devops-monitoring-dev-rg --name devops-monitoring-app-vm
az vm start --resource-group devops-monitoring-dev-rg --name devops-monitoring-monitoring-vm
```

> **Catatan:** Setelah VM dinyalakan kembali, **Public IP bisa berubah** jika menggunakan Dynamic IP. Karena kita menggunakan Static IP (`allocation_method = "Static"`), IP address **tidak akan berubah**.

---
