# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
# Ikon garis buatan sendiri (24x24, stroke 1.75) supaya seragam dengan logo dan tanpa dependensi.
module IconsHelper
  ICONS = {
    "kit" => '<path d="M5 8.5 12 5l7 3.5-7 3.5-7-3.5z"/><path d="m5 12.5 7 3.5 7-3.5"/><path d="m5 16.5 7 3.5 7-3.5"/>',
    "check" => '<path d="m5 12.5 4.5 4.5L19 7.5"/>',
    "clock" => '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
    "calendar" => '<rect x="4" y="5.5" width="16" height="14.5" rx="2.5"/><path d="M4 10h16M8.5 3.5v4M15.5 3.5v4"/>',
    "users" => '<circle cx="9" cy="9" r="3"/><path d="M3.5 19c.6-3 2.8-4.5 5.5-4.5s4.9 1.5 5.5 4.5"/><circle cx="17" cy="9.5" r="2.4"/><path d="M16.5 14.6c2.3.2 3.5 1.6 4 4"/>',
    "chart" => '<path d="M5 19v-8M12 19V5M19 19v-10"/>',
    "alert" => '<path d="M12 4 21 19.5H3L12 4z"/><path d="M12 10v4.5M12 17.2v.1"/>',
    "info" => '<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5M12 8v.1"/>',
    "x" => '<path d="m6 6 12 12M18 6 6 18"/>',
    "plus" => '<path d="M12 5v14M5 12h14"/>',
    "download" => '<path d="M12 4v10M7.5 10.5 12 15l4.5-4.5M5 19h14"/>',
    "arrow-left" => '<path d="M19 12H5M11 6l-6 6 6 6"/>',
    "arrow-right" => '<path d="M5 12h14M13 6l6 6-6 6"/>',
    "pencil" => '<path d="M4 20l1-4L16.5 4.5a2 2 0 0 1 2.8 2.8L8 18.5 4 20z"/>',
    "trash" => '<path d="M5 7h14M9 7V5h6v2M7 7l1 12h8l1-12"/>',
    "doc" => '<path d="M7 3.5h7l4 4V20a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V4.5a1 1 0 0 1 1-1z"/><path d="M14 3.5V8h4"/>',
    "copy" => '<rect x="8" y="8" width="11" height="12" rx="2"/><path d="M5 16V6a2 2 0 0 1 2-2h8"/>',
    "grid" => '<rect x="4" y="4" width="16" height="16" rx="2.5"/><path d="M4 10h16M10 10v10"/>',
    "bell" => '<path d="M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 2h-15l1.5-2z"/><path d="M10 20.5a2 2 0 0 0 4 0"/>',
    "school" => '<path d="M3 10 12 5l9 5-9 5-9-5z"/><path d="M7 12.5V17c1.5 1.3 3 2 5 2s3.5-.7 5-2v-4.5"/>',
    "logout" => '<path d="M10 5H6.5A1.5 1.5 0 0 0 5 6.5v11A1.5 1.5 0 0 0 6.5 19H10M14 8l4 4-4 4M18 12H9"/>'
  }.freeze

  def icon(name, size: 20, class_name: nil)
    body = ICONS.fetch(name.to_s)
    tag.svg(body.html_safe, class: [ "icon", class_name ].compact.join(" "), width: size, height: size, viewBox: "0 0 24 24", fill: "none",
                            stroke: "currentColor", "stroke-width": 1.75, "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": "true", focusable: "false")
  end

  def initials(name)
    name.to_s.split.reject { |w| w.match?(/\A(S\.|Drs\.|Dr\.)/) }.first(2).map { |w| w[0].upcase }.join
  end
end
