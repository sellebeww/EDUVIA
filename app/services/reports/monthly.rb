# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Reports
  # Laporan bulanan jam kosong untuk satu sekolah. Semua angka dihitung dengan beberapa query GROUP BY
  # (bukan memuat baris satu per satu), jadi jumlah query tetap berapa pun banyak data.
  #
  # Definisi:
  #   - Jam kosong       = jumlah Activation pada bulan itu (menurut tanggal ketidakhadiran).
  #   - Tertangani kit   = aktivasi yang memakai kit DAN sudah diselesaikan guru piket.
  #   - Belum selesai    = aktivasi yang belum diselesaikan.
  #   - Penyebab         = alasan ketidakhadiran (Absence#reason).
  class Monthly
    TREND_MONTHS = 6
    HANDLED_SQL = "COUNT(*) FILTER (WHERE activations.kit_id IS NOT NULL AND activations.completed_at IS NOT NULL)".freeze
    MONTH_SQL = "date_trunc('month', absences.date)".freeze
    WEEK_SQL = "((EXTRACT(DAY FROM absences.date)::int - 1) / 7)".freeze

    Totals = Struct.new(:total, :with_kit, :handled, :unfinished, :reused, keyword_init: true) do
      def no_kit = total - with_kit
      def handled_percent = total.zero? ? 0 : (handled * 100.0 / total).round
    end

    attr_reader :month

    def initialize(school:, month:)
      @school = school
      @month = month.beginning_of_month
    end

    def totals
      @totals ||= begin
        total, with_kit, handled, unfinished, reused = month_scope(@month).pick(
          Arel.sql("COUNT(*)"), Arel.sql("COUNT(activations.kit_id)"), Arel.sql(HANDLED_SQL),
          Arel.sql("COUNT(*) FILTER (WHERE activations.completed_at IS NULL)"), Arel.sql("COUNT(*) FILTER (WHERE activations.reused)")
        )
        Totals.new(total: total.to_i, with_kit: with_kit.to_i, handled: handled.to_i, unfinished: unfinished.to_i, reused: reused.to_i)
      end
    end

    def empty? = totals.total.zero?

    # [{ week: 1, total:, handled: }, ...] untuk minggu ke-1 sampai ke-5 (hari 1-7, 8-14, ...).
    def weekly
      @weekly ||= begin
        rows = month_scope(@month).group(Arel.sql(WEEK_SQL)).pluck(Arel.sql(WEEK_SQL), Arel.sql("COUNT(*)"), Arel.sql(HANDLED_SQL)).to_h { |w, t, h| [ w.to_i, [ t, h ] ] }
        (0...weeks_in_month).map { |w| { week: w + 1, total: rows.dig(w, 0).to_i, handled: rows.dig(w, 1).to_i } }
      end
    end

    # Penyebab ketidakhadiran, terbanyak lebih dulu: [[label, jumlah], ...]
    def reasons
      @reasons ||= month_scope(@month).group("absences.reason").count.sort_by { |_, n| -n }.map { |reason, n| [ Absence::REASONS.fetch(reason), n ] }
    end

    # Enam bulan terakhir sampai bulan ini: [{ month: Date, total:, handled:, percent: }, ...]
    def trend
      @trend ||= begin
        from = @month << (TREND_MONTHS - 1)
        rows = scope.where(absences: { date: from..@month.end_of_month })
                    .group(Arel.sql(MONTH_SQL)).pluck(Arel.sql(MONTH_SQL), Arel.sql("COUNT(*)"), Arel.sql(HANDLED_SQL))
                    .to_h { |m, t, h| [ m.to_date, [ t, h ] ] }
        (0...TREND_MONTHS).map do |i|
          m = from >> i
          total, handled = rows.fetch(m, [ 0, 0 ])
          { month: m, total: total, handled: handled, percent: total.zero? ? 0 : (handled * 100.0 / total).round }
        end
      end
    end

    # Selisih jumlah jam kosong dibanding bulan sebelumnya (nil bila bulan sebelumnya kosong).
    def change_from_previous
      previous = trend[-2]&.fetch(:total)
      return nil if previous.nil? || previous.zero?
      ((totals.total - previous) * 100.0 / previous).round
    end

    private
      def scope = Activation.for_school(@school).joins(:absence)
      def month_scope(month) = scope.where(absences: { date: month..month.end_of_month })
      def weeks_in_month = ((@month.end_of_month.day - 1) / 7) + 1
  end
end
