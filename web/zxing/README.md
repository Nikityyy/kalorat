# zxing-wasm reader

Vendored from the npm package `zxing-wasm@3.1.5` (`dist/iife/reader/index.js`
and `dist/reader/zxing_reader.wasm`), so barcode scanning works offline and
nothing loads from a CDN. Used only by `../barcode_worker.js`.

- zxing-wasm: MIT, see `LICENSE`
- zxing-cpp (the decoder compiled to WebAssembly): Apache License 2.0,
  https://github.com/zxing-cpp/zxing-cpp

To update: `npm pack zxing-wasm@<version>` and copy the two files above.
