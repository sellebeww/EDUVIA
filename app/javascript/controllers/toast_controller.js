// Copyright (c) 2026 Vassel Goleyu. All rights reserved.
// Pemberitahuan realtime (Turbo Stream): muncul, hilang sendiri, bisa ditutup.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 8000 } }

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
