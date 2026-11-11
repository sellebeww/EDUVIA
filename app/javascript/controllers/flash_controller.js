// Copyright (c) 2026 Vassel Goleyu. All rights reserved.
// Pesan sukses hilang sendiri setelah beberapa detik (pesan galat dan peringatan tetap sampai ditutup).
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 7000 } }

  connect() {
    this.timer = setTimeout(() => this.dismiss(), this.delayValue)
  }

  dismiss() {
    clearTimeout(this.timer)
    this.element.classList.add("is-leaving")
    this.element.addEventListener("animationend", () => this.element.remove(), { once: true })
    setTimeout(() => this.element.remove(), 600) // cadangan bila animasi dimatikan
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
