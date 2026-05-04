class MyNotesController < ApplicationController
  before_action :authenticate_user!

  def index
    @notes = current_user.notes
                         .includes(lesson: { course_module: :course })
                         .recent

    # Group notes by course for organized display
    @notes_by_course = @notes.group_by(&:course)
  end
end
