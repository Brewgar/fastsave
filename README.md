---

# FastSave — Async Batch Chunk I/O for Minecraft 1.20.1 (Fabric)

Minecraft blocks the main I/O thread when writing chunks to disk and issues separate, small `FileChannel.write()` calls for each chunk. FastSave optimizes this process by introducing asynchronous, sequential batching:

```
Game Thread
    │
    ▼  enqueue() — Non-blocking (nanosecond level)
  LinkedBlockingQueue<WriteTask>  (Capacity: 512)
    │
    ▼  Every 50 ms (1 tick)
  I/O Worker Thread
    │  ─ Group by region file
    │  ─ Sort by offset (Sequential I/O)
    ▼
  AsynchronousFileChannel.write()   ← NIO Async (OS-level)
    │
    ▼
  SSD  (Large sequential writes instead of small random writes)

```

## Installation


You can directly download the JAR file from the releases tab but if you want to build it yourself:


### Requirements

* JDK 17 or 21
* Fabric Loader 0.14.22+
* Fabric API 0.83.0+1.20.1

### Build

```bash
./gradlew build
# Output: build/libs/fastsave-1.0.0.jar

```

### Setup

1. Move `build/libs/fastsave-1.0.0.jar` to your Minecraft `mods/` directory.
2. Ensure Fabric API is also in the `mods/` folder.
3. Launch the game. The logs will confirm initialization:
```
[FastSave] Loaded. Async batch chunk I/O active.

```



## Configuration (`FastSaveConfig.java`)

| Constant | Default | Description |
| --- | --- | --- |
| `QUEUE_CAPACITY` | `512` | Blocks the caller if the queue fills up |
| `FLUSH_INTERVAL_MS` | `50` | Time interval between batch flushes (1 tick) |
| `WORKER_THREADS` | `1` | Optimal setting for a single SSD |
| `WRITE_BUFFER_BYTES` | `2 MiB` | Buffer size per worker thread |

## Architecture

### Mixin Entry Point

The mod injects into `StorageIoWorker#setResult` before chunk, POI, or entity NBT data is written to disk:

1. Serializes NBT data to `byte[]` using standard vanilla ZLIB compression.
2. Resolves the target `.mca` file and disk offset.
3. Pushes the task via `AsyncChunkWriteQueue.enqueue()`.
4. Cancels the vanilla write path and returns its own `CompletableFuture`.

> **Data Safety:** If a sector is not yet allocated in the vanilla in-memory sector table (`RegionFile`, where `sectorIndex == 0`), the mixin bypasses execution and falls back to vanilla behavior to prevent data loss.

### Async Write Queue

* **`LinkedBlockingQueue`:** A thread-safe, bounded queue.
* **`ScheduledExecutorService`:** Runs as a background daemon thread.
* Uses `drainTo()` to batch-process all pending writes simultaneously.
* Leverages `AsynchronousFileChannel` for non-blocking, OS-level async I/O.
* Includes a shutdown hook to ensure all pending data is flushed to disk upon closing.

## Compatibility

* ✅ Vanilla Fabric Server / Singleplayer
* ⚠️ **Lithium:** Potential Mixin conflicts (testing required).
* ⚠️ **Distant Horizons / Modded Chunk Managers:** Exercise caution.

## License

MIT



If you want any help, feel free to contact me on discord: brewgar
This was a little project for me and i dont plan on keeping this maintained
