// Copyright (c) 2026 Vassel Goleyu. All rights reserved.
// Menaruh jumlah kit terbuka di judul tab, "(2) Kit Hari Ini", supaya guru piket tahu ada kit baru
// walau tab sedang tidak dilihat.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { count: Number }

  connect() {
    this.base = document.title.replace(/^\(\d+\)\s/, "")
    document.title = this.countValue > 0 ? `(${this.countValue}) ${this.base}` : this.base
  }

  disconnect() {
    if (this.base) document.title = this.base
  }
}
