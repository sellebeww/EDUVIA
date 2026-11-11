# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Curriculum
  # CRUD generik untuk data master. Subclass menyediakan:
  #   collection, build_record(attrs), permitted_params, resource_label
  class ResourceController < BaseController
    before_action :set_record, only: %i[edit update destroy]
    helper_method :resource_label

    def index
      @records = collection
    end

    def new
      @record = build_record(default_attributes)
    end

    def create
      @record = build_record(permitted_params)
      if @record.save
        redirect_to after_save_path, notice: "#{resource_label} berhasil ditambahkan."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @record.update(permitted_params)
        redirect_to after_save_path, notice: "#{resource_label} berhasil diperbarui."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @record.destroy
        redirect_to after_save_path, notice: "#{resource_label} berhasil dihapus.", status: :see_other
      else
        redirect_to after_save_path, alert: "#{resource_label} tidak bisa dihapus. #{@record.errors.full_messages.to_sentence}", status: :see_other
      end
    end

    private
      def set_record
        @record = collection.find(params[:id])
      end

      def default_attributes = {}
      def after_save_path = url_for(action: :index)
  end
end
