# FastSave — Async Batch Chunk I/O for Minecraft 1.20.1 (Fabric)

Minecraft, chunk'ları diske yazarken ana I/O thread'ini bloklar ve her chunk için
ayrı küçük bir `FileChannel.write()` çağrısı yapar.  FastSave bunu şöyle düzeltir:

```
Oyun thread'i
    │
    ▼  enqueue() — nanosaniye seviyesinde, bloklamaz
  LinkedBlockingQueue<WriteTask>  (kapasite: 512)
    │
    ▼  her 50 ms (1 tick)
  I/O Worker Thread
    │  ─ region dosyasına göre gruplar
    │  ─ offset'e göre sıralar (sequential I/O)
    ▼
  AsynchronousFileChannel.write()   ← NIO async, OS'a bırakır
    │
    ▼
  SSD  (büyük, sıralı yazma — küçük rastgele yazma değil)
```

## Kurulum

### Gereksinimler
- JDK 17+ (17 veya 21)
- Fabric Loader 0.14.22+
- Fabric API 0.83.0+1.20.1

### Derleme

```bash
# gradle-wrapper.jar'ı indirmek için (ilk seferinde internet gerekir):
./gradlew build

# Çıktı:
#   build/libs/fastsave-1.0.0.jar
```

### Yükleme

1. `build/libs/fastsave-1.0.0.jar` dosyasını Minecraft `mods/` klasörüne koy.
2. Fabric API'nin de `mods/` içinde olduğundan emin ol.
3. Oyunu başlat.  Log'da şunu görmelisin:
   ```
   [FastSave] Loaded. Async batch chunk I/O active.
   ```

## Ayarlar (`FastSaveConfig.java`)

| Sabit | Varsayılan | Açıklama |
|---|---|---|
| `QUEUE_CAPACITY` | 512 | Kuyruk dolarsa caller bloklanır |
| `FLUSH_INTERVAL_MS` | 50 | Kaç ms'de bir batch flush (1 tick) |
| `WORKER_THREADS` | 1 | Tek SSD için 1 idealdir |
| `WRITE_BUFFER_BYTES` | 2 MiB | Worker başına buffer boyutu |

## Nasıl çalışır?

### Mixin Noktası

`StorageIoWorker#setResult` — chunk/poi/entity NBT verisi diske yazılmadan önce
buradan geçer.  Mixin bu noktayı yakalar:

1. NBT → byte[] olarak serialize eder (ZLIB, vanilla formatı)
2. Hangi `.mca` dosyasına ve hangi offset'e yazılacağını çözer
3. `AsyncChunkWriteQueue.enqueue()` ile kuyruğa ekler
4. Vanilla'nın write path'ini iptal eder, kendi `CompletableFuture`'ını döner

Vanilla'nın in-memory sektör tablosu (`RegionFile`) güncellenmeden önce sektör
ayrılmamışsa (`sectorIndex == 0`) mixin devreye girmez ve vanilla devam eder.
Bu sayede **hiçbir veri kaybı** yaşanmaz.

### Async Write Queue

- `LinkedBlockingQueue` — thread-safe, bounded
- `ScheduledExecutorService` — daemon thread, oyunun altında çalışır
- `drainTo()` ile tek seferde toplu çekme
- `AsynchronousFileChannel` — OS-level async I/O, thread bloklamaz
- Kapanışta (shutdown hook) tüm bekleyen yazılar tamamlanır

## Uyumluluk

- ✅ Vanilla Fabric sunucu
- ✅ Singleplayer
- ⚠️  Lithium ile birlikte kullanımda Mixin çakışması olabilir (test et)
- ⚠️  Distant Horizons gibi chunk yönetimini değiştiren modlarla dikkatli ol

## Lisans

MIT
