# testMoviePanin 🎬

Aplikasi iOS untuk menjelajahi film populer menggunakan **The Movie Database (TMDB) API**.
Dibangun dengan **UIKit + SnapKit**, arsitektur **MVVM**, dan **SQLite** untuk caching lokal.

---

## 📱 Fitur Utama

| Fitur | Detail |
|---|---|
| 🏠 Home | Daftar film populer dengan genre filter & sorting |
| 🔍 Search | Pencarian real-time dengan debounce 400ms |
| 🎬 Detail | Info lengkap film: rating, runtime, genre, overview |
| ❤️ Favorites | Simpan & kelola film favorit (persist via SQLite) |
| ⚡ Cache-First | Data ditampilkan dari cache dulu, lalu update dari API |
| 📡 Offline | Tetap tampil data dari cache saat offline |
| ♾️ Infinite Scroll | Load more otomatis saat scroll ke bawah |

---

## 🏗️ Arsitektur

```
MVVM (Model - View - ViewModel)
├── Model       → Data structures (Movie, MovieDetail, Genre)
├── ViewModel   → Business logic, API calls, state management
└── View        → UIViewController + UICollectionView (UIKit + SnapKit)
```

### State Management
Setiap ViewModel menggunakan **enum State** + **closure callbacks** sebagai binding:
```swift
viewModel.onStateChanged = { [weak self] state in
    switch state {
    case .loading: // show spinner
    case .loaded:  // update UI
    case .error:   // show alert
    }
}
```

---

## 📁 Struktur Folder

```
testMoviePanin/
├── App/
│   ├── AppDelegate.swift         ← Setup database on launch
│   ├── SceneDelegate.swift       ← TabBar + Navigation setup
│   └── Info.plist
│
├── Core/
│   ├── Network/
│   │   ├── APIClient.swift       ← URLSession async/await wrapper
│   │   ├── APIEndpoint.swift     ← Semua TMDB endpoint + cache key
│   │   └── NetworkMonitor.swift  ← Deteksi koneksi internet (NWPathMonitor)
│   │
│   ├── Cache/
│   │   ├── DatabaseManager.swift ← Raw SQLite3: api_cache + favorites tables
│   │   ├── CacheManager.swift    ← Cache-first strategy (encode/decode JSON)
│   │   └── ImageCacheManager.swift ← NSCache (memory) + Disk cache untuk gambar
│   │
│   └── Models/
│       └── Models.swift          ← Movie, MovieDetail, Genre, AppError, SortOption
│
├── Features/
│   ├── Home/
│   │   ├── View/HomeViewController.swift      ← Grid film + genre chips + header
│   │   └── ViewModel/HomeViewModel.swift      ← Popular movies, genre filter, sort
│   │
│   ├── Search/
│   │   ├── View/SearchViewController.swift    ← UISearchController + grid hasil
│   │   └── ViewModel/SearchViewModel.swift    ← Debounce search, pagination
│   │
│   ├── Detail/
│   │   ├── View/DetailViewController.swift    ← Backdrop, poster, info card
│   │   └── ViewModel/DetailViewModel.swift    ← Fetch detail, toggle favorite
│   │
│   └── Favorites/
│       ├── View/FavoritesViewController.swift ← Grid favorites + context menu delete
│       └── ViewModel/FavoritesViewModel.swift ← Load/sort/remove dari SQLite
│
└── Shared/
    ├── Components/SharedComponents.swift  ← MovieCardCell, EmptyStateView, dll
    ├── Constants/Constants.swift          ← AppColors, APIConstants, Strings
    └── Extensions/Extensions.swift       ← UIColor hex, UIImageView+cache, dll
```

---

## 🗄️ Database Schema (SQLite)

```sql
-- Cache API responses
CREATE TABLE api_cache (
    cache_key   TEXT PRIMARY KEY,
    data        BLOB NOT NULL,       -- JSON encoded
    created_at  REAL NOT NULL,
    expires_at  REAL NOT NULL        -- Auto-expire
);

-- Persistent favorites
CREATE TABLE favorites (
    movie_id    INTEGER PRIMARY KEY,
    data        BLOB NOT NULL,       -- JSON encoded Movie
    added_at    REAL NOT NULL
);
```

### Cache Durations
| Data | Duration |
|---|---|
| Popular movies | 1 jam |
| Movie detail | 2 jam |
| Genres | 24 jam |
| Search results | 1 jam |

---

## 🔄 Cache-First Flow

```
Request Data
     │
     ▼
┌─────────────┐    HIT     ┌──────────────┐
│ SQLite Cache│──────────► │ Return Cache │
└─────────────┘            └──────────────┘
     │ MISS
     ▼
┌─────────────┐
│  Internet?  │──── NO ───► AppError.noInternet
└─────────────┘
     │ YES
     ▼
┌─────────────┐
│  API Call   │
└─────────────┘
     │
     ▼
┌─────────────┐
│ Save Cache  │──────────► Return Data
└─────────────┘
```

---

## 🖼️ Image Loading Strategy

```
Load Image URL
     │
     ▼
┌──────────────┐   HIT    ┌──────────┐
│ Memory Cache │─────────►│ Display  │
│  (NSCache)   │          └──────────┘
└──────────────┘
     │ MISS
     ▼
┌──────────────┐   HIT    ┌──────────────┐   ┌──────────┐
│  Disk Cache  │─────────►│ → Memory     │──►│ Display  │
│  (FileSystem)│          └──────────────┘   └──────────┘
└──────────────┘
     │ MISS
     ▼
┌──────────────┐          ┌──────────────┐   ┌──────────┐
│   Download   │─────────►│ → Disk+Mem   │──►│ Display  │
└──────────────┘          └──────────────┘   └──────────┘
```

---

## 🚀 Setup & Instalasi

### Prasyarat
- Xcode 15+
- iOS 15.0+
- CocoaPods

### Langkah

**1. Clone / Extract project**
```bash
cd testMoviePanin
```

**2. Install dependencies**
```bash
pod install
```

**3. Buka workspace (BUKAN .xcodeproj)**
```bash
open testMoviePanin.xcworkspace
```

**4. Masukkan TMDB API Key**

Edit file `Shared/Constants/Constants.swift`:
```swift
enum APIConstants {
    static let apiKey = "GANTI_DENGAN_API_KEY_TMDB_KAMU"
}
```

Daftar API key gratis di: https://www.themoviedb.org/settings/api

**5. Build & Run**
- Pilih simulator iPhone 15 atau device
- `Cmd + R`

---

## 🔑 Cara Dapat API Key TMDB

1. Buka https://www.themoviedb.org/
2. Daftar akun (gratis)
3. Buka Settings → API
4. Request API key (pilih "Developer")
5. Copy API Key (v3 auth) → paste ke `Constants.swift`

---

## 📦 Dependencies

| Library | Versi | Fungsi |
|---|---|---|
| SnapKit | ~> 5.7 | Auto Layout DSL, menggantikan NSLayoutConstraint |

> SQLite digunakan langsung via `sqlite3` system framework (tidak perlu pod tambahan).

---

## ✅ Checklist Kriteria Penilaian

### Caching
- [x] SQLite dengan 2 tabel: `api_cache` dan `favorites`
- [x] Cache-first approach di `APIClient.swift`
- [x] Auto-expire berdasarkan `expires_at`
- [x] Image cache: NSCache (memory) + FileSystem (disk)
- [x] Favorites persist secara lokal meski app di-restart

### Performa
- [x] `async/await` untuk non-blocking API calls
- [x] Debounce 400ms pada search (hindari spam request)
- [x] `UICollectionViewCompositionalLayout` untuk smooth scroll
- [x] Image fade-in dengan `UIView.transition`
- [x] `prepareForReuse()` untuk cancel & clear cell state
- [x] `NSCache` dengan `countLimit` & `totalCostLimit`
- [x] Disk cache management (auto-delete kalau over limit)

### Kualitas Kode
- [x] MVVM architecture yang konsisten
- [x] `enum AppError` dengan pesan error informatif
- [x] Protocol `APIClientProtocol` untuk testability
- [x] Naming convention Swift style guide
- [x] `[weak self]` di semua closure untuk hindari retain cycle
- [x] Konstanta terpusat di `Constants.swift`
- [x] Extension terpisah per fungsi

---

## 🧑‍💻 Author

Dibuat untuk iOS Test  
Stack: UIKit + SnapKit + MVVM + SQLite + TMDB API
