# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Duty
  class SubmissionsController < SheetsController
    private
      def records = @activation.submissions
      def record_params = params.expect(submission: %i[submitted score note])
      def row_partial = "duty/sheets/submission_row"
  end
end
