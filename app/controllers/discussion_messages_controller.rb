class DiscussionMessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_course
  before_action :ensure_course_member

  # GET /courses/:course_id/chat
  def index
    @messages = @course.discussion_messages
                       .top_level
                       .includes(:user, replies: :user)
                       .recent_window(50)
                       .reverse
    @members_count = @course.enrollments.active.count
    @message = DiscussionMessage.new
  end

  # GET /courses/:course_id/chat/:id/thread
  def thread
    @parent  = @course.discussion_messages.find(params[:id])
    @replies = @parent.replies.includes(:user).chronological
    @reply   = DiscussionMessage.new
  end

  # POST /courses/:course_id/chat
  def create
    @message = @course.discussion_messages.new(message_params)
    @message.user = current_user

    if @message.save
      respond_to_message_created
    else
      respond_to_message_invalid
    end
  end

  # DELETE /courses/:course_id/chat/:id
  def destroy
    @message = @course.discussion_messages.find(params[:id])
    authorize! :destroy, @message
    @message.destroy

    respond_to do |format|
      format.turbo_stream{render turbo_stream: turbo_stream.remove(@message)}
      format.html{redirect_to course_discussion_messages_path(@course)}
    end
  end

  # GET /courses/:course_id/chat/mentions
  def mentions
    query = params[:query].to_s.strip.downcase

    # 1. Fetch prioritized instructor
    instructor = @course.creator

    # 2. Fetch other candidates (enrolled users + active chat participants)
    active_chat_users = @course.discussion_messages.includes(:user).map(&:user).compact.uniq
    enrolled_users = @course.enrolled_users.to_a

    candidates = ([instructor] + active_chat_users + enrolled_users).compact.uniq

    # 3. If candidates is less than 5, grab some random users as backup autocomplete candidates
    if candidates.size < 5
      backup_users = User.limit(10).to_a
      candidates = (candidates + backup_users).uniq
    end

    # 4. Filter by query if present
    if query.present?
      candidates = candidates.select do |u|
        u.name.to_s.downcase.include?(query) || u.email.to_s.downcase.include?(query)
      end
    end

    # 5. Format results: prioritize instructor first
    results = candidates.map do |u|
      is_instructor = (u == instructor || u.role == "instructor")
      {
        id: u.id,
        name: u.name,
        email: u.email,
        is_instructor: is_instructor,
        avatar_initial: u.name[0]&.upcase || "?",
        avatar_bg: '#' + Digest::MD5.hexdigest(u.name)[0..5]
      }
    end

    # Ensure instructor is at the absolute top of the sorted results
    results = results.sort_by { |r| r[:is_instructor] ? 0 : 1 }

    # Limit to 5 results when query is empty, or 10 when searching
    limit = query.empty? ? 5 : 10
    results = results.first(limit)

    render json: results
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def message_params
    params.require(:discussion_message).permit(:content)
  end

  def ensure_course_member
    return if current_user.admin?
    return if current_user.can_access_course?(@course)
    return if @course.created_by == current_user.id
    return if current_user.has_license_for?(@course)

    redirect_to course_path(@course),
                 alert: "Bạn cần đăng ký khóa học để tham gia nhóm trao đổi."
  end

  def respond_to_message_created
    respond_to do |format|
      format.turbo_stream{render turbo_stream: message_created_streams}
      format.html{redirect_to course_discussion_messages_path(@course)}
    end
  end

  def message_created_streams
    [
      turbo_stream.replace("chat-form",
                           partial: "discussion_messages/lumina_form",
                           locals: new_message_form_locals)
    ]
  end

  def respond_to_message_invalid
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("chat-form",
                                                  partial: "discussion_messages/lumina_form",
                                                  locals: message_form_locals)
      end
      format.html{redirect_to course_discussion_messages_path(@course)}
    end
  end

  def new_message_form_locals
    { course: @course, message: DiscussionMessage.new }
  end

  def message_form_locals
    { course: @course, message: @message }
  end
end
