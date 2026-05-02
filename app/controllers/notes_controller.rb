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
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("notes-list",
              partial: "notes/note", locals: { note: @note }),
            turbo_stream.replace("note-form",
              partial: "notes/form", locals: { lesson: @lesson, note: Note.new }),
            turbo_stream.replace("notes-empty-state", "<div id='notes-empty-state'></div>"),
            turbo_stream.replace("notes-count-badge",
              partial: "notes/count_badge",
              locals: { count: current_user.notes.where(lesson: @lesson).count })
          ]
        end
        format.html { redirect_to lesson_path(@lesson), notice: "Đã lưu ghi chú!" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("note-form",
            partial: "notes/form", locals: { lesson: @lesson, note: @note })
        end
        format.html { redirect_to lesson_path(@lesson), alert: "Không thể lưu ghi chú." }
      end
    end
  end

  # PATCH /notes/:id
  def update
    if @note.update(note_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@note,
            partial: "notes/note", locals: { note: @note })
        end
        format.html { redirect_to lesson_path(@note.lesson), notice: "Đã cập nhật ghi chú!" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@note,
            partial: "notes/edit_form", locals: { note: @note })
        end
        format.html { redirect_to lesson_path(@note.lesson), alert: "Không thể cập nhật." }
      end
    end
  end

  # DELETE /notes/:id
  def destroy
    lesson = @note.lesson
    @note.destroy

    respond_to do |format|
      format.turbo_stream do
        remaining = current_user.notes.where(lesson: lesson).count
        streams = [
          turbo_stream.remove(@note),
          turbo_stream.replace("notes-count-badge",
            partial: "notes/count_badge",
            locals: { count: remaining })
        ]
        if remaining.zero?
          streams << turbo_stream.replace("notes-list",
            partial: "notes/empty_state")
        end
        render turbo_stream: streams
      end
      format.html { redirect_to lesson_path(lesson), notice: "Đã xóa ghi chú." }
    end
  end

  private

  def set_note
    @note = current_user.notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:content)
  end
end
