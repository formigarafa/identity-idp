# frozen_string_literal: true

# Data about one run of one spec
class Example
  attr_reader :id, :description, :full_description,
              :status, :file_path, :line_number,
              :run_time, :pending_message

  def initialize(id: nil,
                 description: nil,
                 full_description: nil,
                 status: nil,
                 file_path: nil,
                 line_number: nil,
                 run_time: nil,
                 pending_message: nil)
    @id = id
    @description = description
    @full_description = full_description
    @status = status
    @file_path = file_path
    @line_number = line_number
    @run_time = run_time
    @pending_message = pending_message
  end

  def spec_type
    file_path.split('/')[2].to_sym
  end
end
