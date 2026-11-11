# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
# Bank kit milik guru mapel. Semua query di-scope ke current_user.kits,
# jadi kit guru lain tidak pernah bisa dimuat walau ID-nya ditebak (hasilnya 404).
class KitsController < ApplicationController
  require_role :guru_mapel

  before_action :set_kit, only: %i[show edit update destroy duplicate worksheet]
  before_action :ensure_editable, only: %i[edit update destroy]
  before_action :load_assignments, only: %i[index new create edit update]

  def index
    @kits = current_user.kits.includes(:subject, :school_class).with_attached_worksheet
                        .by_subject(params[:subject_id]).by_class(params[:school_class_id]).by_phase(params[:phase]).recent
    @counts = current_user.kits.group(:status).count
    @missing = @assignments.reject { |a| kit_pairs.include?([ a.subject_id, a.school_class_id ]) }
    @filtered = params.values_at(:subject_id, :school_class_id, :phase).any?(&:present?)
  end

  def show
  end

  def new
    template = KitTemplate.find(params[:template])
    @kit = current_user.kits.new(template ? template.attributes : { duration_minutes: 35 })
    assign_pair(@kit, params[:assignment])
  end

  def create
    @kit = current_user.kits.new(kit_params)
    if @kit.save
      redirect_to @kit, notice: "Kit berhasil disiapkan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @kit.update(kit_params)
      @kit.worksheet.purge if params.dig(:kit, :remove_worksheet) == "1" && !params.dig(:kit, :worksheet)
      redirect_to @kit, notice: "Kit berhasil diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @kit.destroy
      redirect_to kits_path, notice: "Kit dihapus.", status: :see_other
    else
      redirect_to @kit, alert: "Kit tidak bisa dihapus. #{@kit.errors.full_messages.to_sentence}", status: :see_other
    end
  end

  def duplicate
    copy = @kit.dup
    copy.assign_attributes(title: "#{@kit.title.truncate(108, omission: "")} (salinan)", status: "disiapkan", times_used: 0, last_used_at: nil)
    copy.worksheet.attach(@kit.worksheet.blob) if @kit.worksheet.attached?
    copy.save!
    redirect_to edit_kit_path(copy), notice: "Kit disalin. Ubah isinya sesuai kebutuhan."
  end

  # Unduhan lewat aksi ini (bukan URL Active Storage publik) supaya hak akses tetap dicek.
  def worksheet
    return head :not_found unless @kit.worksheet.attached?
    send_data @kit.worksheet.download, filename: @kit.worksheet.filename.to_s, type: "application/pdf", disposition: "attachment"
  end

  private
    Assignment = Struct.new(:subject_id, :subject_name, :school_class_id, :class_name, :grade_level) do
      def value = "#{subject_id}:#{school_class_id}"
      def label = "#{class_name} · #{subject_name}"
    end

    def set_kit
      @kit = current_user.kits.find(params[:id])
    end

    def ensure_editable
      return if @kit.editable?
      redirect_to @kit, alert: "Kit sedang dipakai di kelas. Tunggu sampai selesai untuk mengubah atau menghapusnya.", status: :see_other
    end

    # Pasangan kelas + mapel yang benar-benar diajar guru ini (dari jadwal).
    def load_assignments
      @assignments = current_user.lessons.joins(:subject, :school_class).distinct
                                 .order("school_classes.grade_level", "school_classes.name", "subjects.name")
                                 .pluck("subjects.id", "subjects.name", "school_classes.id", "school_classes.name", "school_classes.grade_level")
                                 .map { |row| Assignment.new(*row) }
      @subjects = @assignments.uniq(&:subject_id)
      @classes = @assignments.uniq(&:school_class_id)
      @phases = @classes.filter_map { |a| SchoolClass.new(grade_level: a.grade_level).phase }.uniq.sort
    end

    def kit_pairs
      @kit_pairs ||= current_user.kits.pluck(:subject_id, :school_class_id).to_set
    end

    def assign_pair(kit, value)
      subject_id, class_id = value.to_s.split(":").map(&:to_i)
      kit.subject_id = subject_id if subject_id.to_i.positive?
      kit.school_class_id = class_id if class_id.to_i.positive?
    end

    # Pemilik, status, dan penghitung tidak pernah diterima dari form.
    def kit_params
      permitted = params.expect(kit: %i[assignment title duration_minutes supervisor_instructions answer_key worksheet])
      attrs = permitted.slice(:title, :duration_minutes, :supervisor_instructions, :answer_key).to_h
      attrs[:worksheet] = permitted[:worksheet] if permitted[:worksheet].present?
      subject_id, class_id = permitted[:assignment].to_s.split(":").map(&:to_i)
      attrs.merge!(subject_id: subject_id, school_class_id: class_id) if subject_id.to_i.positive? && class_id.to_i.positive?
      attrs
    end
end
