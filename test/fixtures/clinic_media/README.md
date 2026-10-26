`short_showcase.mp4` is a two-second neutral gray, silent test fixture generated with FFmpeg (64×64, H.264/yuv420p, 10fps). It contains no clinic, practitioner, patient or production content and is never included in Flutter application assets. It exercises actual Django MP4 duration validation; Flutter platform-player tests explicitly use a platform fake and do not claim physical-device decoding or R2 delivery.

# Android-layout upload regression

`android_layout_showcase.mp4` remuxes the same neutral two-second H.264 clip
without faststart (`ffmpeg -i short_showcase.mp4 -map_metadata -1 -c copy ...`).
It has `mdat` before `moov`. `test/support/large_showcase_fixture.dart` inserts
3 MiB of unreferenced padding after its real media samples inside `mdat`, leaving
sample offsets intact. The resulting decodable MP4 exceeds Django's 2.5 MB memory
threshold without committing a large binary. It contains no clinic/person imagery.

The optional `paddingBytes` argument also generates a 19 MiB weak-network test
file (19,925,044 bytes including the genuine samples/container). FFmpeg decoded
every frame successfully on Ubuntu; FFprobe reports H.264, 64×64 and 2.000s.
The controlled transport models 320s send time, delayed acknowledgment,
cancellation and loss after transmission. This is not mobile-network or
physical-player verification, and the large binary is never committed.
