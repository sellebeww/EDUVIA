# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Duty
  class AttendanceRecordsController < SheetsController
    private
      def records = @activation.attendance_records
      def record_params = params.expect(attendance_record: %i[status])
      def row_partial = "duty/sheets/attendance_row"
  end
end
