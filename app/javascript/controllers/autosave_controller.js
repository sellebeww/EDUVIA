// Copyright (c) 2026 Vassel Goleyu. All rights reserved.
// Simpan formulir per baris otomatis: langsung saat pilihan berubah, atau setelah jeda singkat saat mengetik.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 600 } }

  submit() {
    clearTimeout(this.timer)
    this.element.requestSubmit()
  }

  debounce() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
