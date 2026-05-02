class NotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_note, only: [:update, :destroy]

  # POST /lessons/:lesson_id/notes
  def create
    @lesson = Lesson.find(params[:lesson_id])
    authorize! :read, @lesson # Ensure user can at least view the lesson

    @note = current_user.notes.new(note_params.merge(lesson: @lesson))
    authorize! :create, @note

    if @note.save
      respond_to_note_created
    else
      respond_to_note_invalid
    end
  end

  # PATCH /notes/:id
  def update
    if @note.update(note_params)
      respond_to_note_updated
    else
      respond_to_note_update_invalid
    end
  end

  # DELETE /notes/:id
  def destroy
    lesson = @note.lesson
    @note.destroy

    respond_to do |format|
      format.turbo_stream{render turbo_stream: note_destroyed_streams(lesson)}
      format.html{redirect_to lesson_path(lesson), notice: "Đã xóa ghi chú."}
    end
  end

  private

  def set_note
    @note = current_user.notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:content)
  end

  def respond_to_note_created
    respond_to do |format|
      format.turbo_stream{render turbo_stream: note_created_streams}
      format.html{redirect_to lesson_path(@lesson), notice: "Đã lưu ghi chú!"}
    end
  end

  def note_created_streams
    [
      turbo_stream.prepend("notes-list",
                           partial: "notes/note", locals: { note: @note }),
      turbo_stream.replace("note-form",
                           partial: "notes/form", locals: { lesson: @lesson, note: Note.new }),
      turbo_stream.replace("notes-empty-state", "<div id='notes-empty-state'></div>"),
      turbo_stream.replace("notes-count-badge",
                           partial: "notes/count_badge",
                           locals: { count: notes_count(@lesson) })
    ]
  end

  def respond_to_note_invalid
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("note-form",
                                                  partial: "notes/form",
                                                  locals: { lesson: @lesson, note: @note })
      end
      format.html{redirect_to lesson_path(@lesson), alert: "Không thể lưu ghi chú."}
    end
  end

  def respond_to_note_updated
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(@note,
                                                  partial: "notes/note",
                                                  locals: { note: @note })
      end
      format.html{redirect_to lesson_path(@note.lesson), notice: "Đã cập nhật ghi chú!"}
    end
  end

  def respond_to_note_update_invalid
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(@note,
                                                  partial: "notes/edit_form",
                                                  locals: { note: @note })
      end
      format.html{redirect_to lesson_path(@note.lesson), alert: "Không thể cập nhật."}
    end
  end

  def note_destroyed_streams lesson
    remaining = notes_count(lesson)
    streams = [
      turbo_stream.remove(@note),
      turbo_stream.replace("notes-count-badge",
                           partial: "notes/count_badge",
                           locals: { count: remaining })
    ]
    streams << turbo_stream.replace("notes-list", partial: "notes/empty_state") if remaining.zero?
    streams
  end

  def notes_count lesson
    current_user.notes.where(lesson:).count
  end
end
