// Copyright (c) 2026 Vassel Goleyu. All rights reserved.
// Angka naik dari 0 ke nilai akhir. Isi awal dari server sudah nilai akhir, jadi tanpa JS atau dengan
// "kurangi gerakan" angka langsung benar.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { to: Number, duration: { type: Number, default: 800 }, suffix: { type: String, default: "" } }

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    const start = performance.now()
    const tick = (now) => {
      const progress = Math.min(1, (now - start) / this.durationValue)
      const eased = 1 - Math.pow(1 - progress, 3)
      this.element.textContent = `${Math.round(this.toValue * eased)}${this.suffixValue}`
      if (progress < 1) this.frame = requestAnimationFrame(tick)
    }
    this.element.textContent = `0${this.suffixValue}`
    this.frame = requestAnimationFrame(tick)
  }

  disconnect() {
    cancelAnimationFrame(this.frame)
  }
}
