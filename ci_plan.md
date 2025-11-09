# CI Migration Plan: Static Linking FFmpeg via vcpkg

## Цель
Перевести все платформы в GitHub Actions на статический линкинг FFmpeg через vcpkg для получения единого standalone бинарника без внешних зависимостей.

## Текущее состояние

### Локальная разработка
- ✅ FFmpeg 7.1.1 через vcpkg
- ✅ Статический линкинг (`x64-windows-static-md`)
- ✅ Hardware encoding support (NVENC headers включены)
- ✅ Triplets настроены в `build.rs:81-95`

### GitHub Actions CI (проблемы)
| Платформа | Источник | Версия | Линкинг | Hardware |
|-----------|----------|--------|---------|----------|
| Windows | gyan.dev | ~7.1.x | shared | NVENC есть |
| Linux | avbuild | 8.0 | shared | нет |
| macOS | Homebrew | ~7.1.x | shared | VideoToolbox? |

**Проблемы:**
1. Разные источники FFmpeg
2. Разные версии (7.1.x vs 8.0)
3. Shared linking → требуются .dll/.so/.dylib при распространении
4. Нет консистентности с локальной разработкой
5. Linux build без hardware codecs

---

## План миграции

### Фаза 1: Подготовка vcpkg

#### 1.1. Создать vcpkg-configuration.json
```json
{
  "default-registry": {
    "kind": "git",
    "baseline": "...",
    "repository": "https://github.com/microsoft/vcpkg"
  },
  "registries": []
}
```

#### 1.2. Создать vcpkg.json
```json
{
  "name": "playa-ffmpeg",
  "version-string": "8.0.2",
  "dependencies": [
    {
      "name": "ffmpeg",
      "version>=": "7.1.1",
      "default-features": false,
      "features": [
        "avcodec",
        "avdevice",
        "avfilter",
        "avformat",
        "swresample",
        "swscale",
        "ffnvcodec"
      ]
    }
  ]
}
```

**Включённые features:**
- ✅ `"ffnvcodec"` - **ОБЯЗАТЕЛЬНО** - NVIDIA NVENC/NVDEC (Windows/Linux)
- `"vpx"` - VP8/VP9 (опционально)
- `"x264"` - H.264 encoder (опционально)
- `"x265"` - H.265 encoder (опционально)

---

### Фаза 2: Обновление CI workflows

#### 2.1. Windows (`build-test-lint-windows`)

**До:**
```yaml
- name: Install dependencies
  run: |
    Invoke-WebRequest "${env:FFMPEG_DOWNLOAD_URL}" -OutFile ffmpeg-release-full-shared.7z
    7z x ffmpeg-release-full-shared.7z
```

**После:**
```yaml
- name: Set up vcpkg
  uses: lukka/run-vcpkg@v11
  with:
    vcpkgGitCommitId: '<baseline-commit>'

- name: Install FFmpeg via vcpkg
  run: |
    vcpkg install ffmpeg:x64-windows-static-md
  env:
    VCPKG_DEFAULT_TRIPLET: x64-windows-static-md

- name: Build with static linking
  run: |
    cargo build --release --examples
  env:
    VCPKG_ROOT: ${{ github.workspace }}/vcpkg
```

**Результат:**
- ✅ Статический линкинг FFmpeg
- ✅ Единый .exe без .dll зависимостей
- ✅ **NVENC support включён по умолчанию**
- ✅ Консистентность с локальной разработкой

---

#### 2.2. Linux (`build-test-lint-linux`)

**До:**
```yaml
- name: Install dependencies
  run: |
    curl -L https://sourceforge.net/projects/avbuild/files/linux/ffmpeg-8.0-linux-clang-default.tar.xz/download -o ffmpeg.tar.xz
    tar -xf ffmpeg.tar.xz
```

**После:**
```yaml
- name: Install system dependencies
  run: |
    sudo apt update
    sudo apt install -y --no-install-recommends \
      clang \
      curl \
      pkg-config \
      nasm \
      yasm \
      autoconf \
      automake \
      libtool

- name: Set up vcpkg
  uses: lukka/run-vcpkg@v11
  with:
    vcpkgGitCommitId: '<baseline-commit>'

- name: Install FFmpeg via vcpkg
  run: |
    vcpkg install ffmpeg:x64-linux-release
  env:
    VCPKG_DEFAULT_TRIPLET: x64-linux-release

- name: Build with static linking
  run: |
    cargo build --release --examples
  env:
    VCPKG_ROOT: ${{ github.workspace }}/vcpkg
```

**Результат:**
- ✅ Статический линкинг FFmpeg
- ✅ Единый binary без .so зависимостей
- ✅ **NVENC support включён по умолчанию**
- ✅ Одна версия FFmpeg на всех платформах (x64 only)

---

#### 2.3. macOS (`build-test-lint-macos`)

**До:**
```yaml
- name: Install dependencies
  run: |
    brew install ffmpeg pkg-config
```

**После:**
```yaml
- name: Install system dependencies
  run: |
    brew install \
      nasm \
      yasm \
      autoconf \
      automake \
      libtool \
      pkg-config

- name: Set up vcpkg
  uses: lukka/run-vcpkg@v11
  with:
    vcpkgGitCommitId: '<baseline-commit>'

- name: Install FFmpeg via vcpkg (Apple Silicon)
  if: runner.arch == 'ARM64'
  run: |
    vcpkg install ffmpeg:arm64-osx-release
  env:
    VCPKG_DEFAULT_TRIPLET: arm64-osx-release

- name: Install FFmpeg via vcpkg (Intel)
  if: runner.arch == 'X64'
  run: |
    vcpkg install ffmpeg:x64-osx-release
  env:
    VCPKG_DEFAULT_TRIPLET: x64-osx-release

- name: Build with static linking
  run: |
    cargo build --release --examples
  env:
    VCPKG_ROOT: ${{ github.workspace }}/vcpkg
```

**Результат:**
- ✅ Статический линкинг FFmpeg
- ✅ Единый binary без .dylib зависимостей
- ✅ Поддержка Apple Silicon (arm64) и Intel (x64)
- ✅ VideoToolbox support (встроен в macOS)

---

### Фаза 3: Оптимизация build.rs

#### 3.1. Triplet логика (без изменений)

**Текущее состояние** (уже корректно):
```rust
fn get_vcpkg_triplet() -> String {
    if cfg!(target_os = "windows") {
        if cfg!(target_env = "msvc") {
            "x64-windows-static-md".to_string()
        } else {
            "x64-mingw-static".to_string()
        }
    } else if cfg!(target_os = "macos") {
        if cfg!(target_arch = "aarch64") {
            "arm64-osx-release".to_string()
        } else {
            "x64-osx-release".to_string()
        }
    } else {
        // Linux - только x64, ARM не требуется
        "x64-linux-release".to_string()
    }
}
```

**Изменения:** Нет, код уже правильный для x64-only Linux

#### 3.2. Обновить default features в Cargo.toml

```toml
[features]
# NVENC включён в default - ОБЯЗАТЕЛЬНАЯ зависимость
default = ["codec", "device", "filter", "format", "software-resampling", "software-scaling", "nvenc"]

# Hardware encoding
nvenc = []           # NVIDIA NVENC/NVDEC (ОБЯЗАТЕЛЬНО в default)
vaapi = []           # Linux VA-API (опционально)
videotoolbox = []    # macOS VideoToolbox (опционально)
qsv = []             # Intel QuickSync (опционально)
```

**Использование:**
```bash
# Default build (с NVENC)
cargo build --release

# С дополнительными hardware codecs
cargo build --release --features vaapi,videotoolbox,qsv
```

---

### Фаза 4: Кэширование vcpkg

Добавить кэширование для ускорения CI:

```yaml
- name: Cache vcpkg
  uses: actions/cache@v4
  with:
    path: |
      ${{ github.workspace }}/vcpkg
      ~/.cache/vcpkg
    key: ${{ runner.os }}-vcpkg-${{ hashFiles('**/vcpkg.json') }}
    restore-keys: |
      ${{ runner.os }}-vcpkg-
```

**Результат:**
- ⚡ Ускорение CI в 5-10 раз после первого билда
- 💾 Экономия трафика GitHub Actions

---

## Проверка результатов

### Критерии успеха

#### Windows
```powershell
# Проверить что бинарник standalone
cargo build --release
dumpbin /DEPENDENTS target/release/examples/*.exe
# Не должно быть ffmpeg dll зависимостей
```

#### Linux
```bash
# Проверить что бинарник standalone
cargo build --release
ldd target/release/examples/* | grep -i ffmpeg
# Не должно быть ffmpeg .so зависимостей
```

#### macOS
```bash
# Проверить что бинарник standalone
cargo build --release
otool -L target/release/examples/*
# Не должно быть ffmpeg .dylib зависимостей
```

### Проверка размеров

Ожидаемые размеры статических бинарников:
- Windows: ~40-60 MB
- Linux: ~35-50 MB
- macOS: ~40-60 MB

---

## Риски и mitigation

### Риск 1: Долгое время сборки vcpkg
**Mitigation:** Кэширование vcpkg (см. Фаза 4)

### Риск 2: Несовместимость vcpkg triplets
**Mitigation:** Использовать `-release` triplets для production builds

### Риск 3: Увеличение размера бинарника
**Mitigation:**
- UPX compression (опционально)
- Strip debug symbols: `--release`
- LTO: добавить в Cargo.toml

```toml
[profile.release]
lto = true
codegen-units = 1
strip = true
```

### Риск 4: Hardware encoding не тестируется в CI
**Mitigation:**
- Документировать что NVENC требует NVIDIA GPU
- NVENC включён по умолчанию (graceful fallback на CPU если нет GPU)
- Тестировать локально на машинах с GPU перед релизом
- CI проверяет что код компилируется с NVENC support

---

## Timeline

| Фаза | Задача | Время | Приоритет |
|------|--------|-------|-----------|
| 1 | Создать vcpkg.json | 30 мин | Высокий |
| 2.1 | Обновить Windows CI | 1 час | Высокий |
| 2.2 | Обновить Linux CI | 1 час | Высокий |
| 2.3 | Обновить macOS CI | 1 час | Средний |
| 3 | Улучшить build.rs | 30 мин | Средний |
| 4 | Добавить кэширование | 30 мин | Средний |
| ✅ | Тестирование | 2 часа | Критичный |

**Общее время:** ~6-8 часов

---

## Действия после миграции

1. ✅ Обновить README.md - убрать инструкции по установке FFmpeg
2. ✅ Обновить документацию - добавить раздел про hardware encoding
3. ✅ Создать release с standalone бинарниками
4. ✅ Проверить размеры артефактов GitHub Actions
5. ✅ Обновить CHANGELOG.md

---

## Откат (Rollback Plan)

Если что-то пойдёт не так:

1. Вернуть `.github/workflows/build.yml` к предыдущей версии:
   ```bash
   git revert <commit-hash>
   ```

2. Удалить `vcpkg.json` и `vcpkg-configuration.json`

3. Локальная разработка продолжит работать (build.rs уже поддерживает vcpkg)

---

## Принятые решения

1. **NVENC в default build**
   - ✅ **ОБЯЗАТЕЛЬНО** включён в default features
   - Бинарник будет работать с NVENC на машинах с NVIDIA GPU
   - На машинах без GPU просто не будет использоваться

2. **LTO в release builds**
   - ✅ **Включить** для оптимизации размера и производительности
   - Компиляция будет дольше, но бинарник меньше и быстрее

3. **Поддержка ARM Linux**
   - ❌ **НЕ требуется**
   - Только x64 на всех платформах
   - Упрощает поддержку и тестирование

---

## Итог

После миграции получим:
- ✅ Единый standalone бинарник на всех платформах (x64)
- ✅ Консистентность между локальной разработкой и CI
- ✅ Одна версия FFmpeg везде (7.1.1)
- ✅ **NVENC support включён по умолчанию**
- ✅ Воспроизводимые сборки через vcpkg
- ✅ Упрощённая дистрибуция (не нужны dll/so/dylib)
- ✅ LTO оптимизация для меньшего размера
