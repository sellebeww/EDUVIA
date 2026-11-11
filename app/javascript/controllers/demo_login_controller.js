// Copyright (c) 2026 Vassel Goleyu. All rights reserved.
// Tombol akun demo: isi form lalu kirim.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "email", "password"]

  fill({ currentTarget }) {
    this.emailTarget.value = currentTarget.dataset.email
    this.passwordTarget.value = currentTarget.dataset.password
    this.formTarget.requestSubmit()
  }
}
