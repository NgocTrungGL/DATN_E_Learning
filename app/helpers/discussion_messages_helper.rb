module DiscussionMessagesHelper
  def render_chat_message(content, course)
    return "" if content.blank?

    # 1. Escape HTML for strict XSS safety
    escaped = ERB::Util.html_escape(content)

    # 2. Collect all candidate names from the course (creator, active, enrolled)
    names = []
    names << course.creator&.name if course.creator
    names += course.discussion_messages.includes(:user).map { |m| m.user&.name }.compact
    names += course.enrolled_users.map(&:name)
    names = names.uniq.compact.reject(&:empty?)

    # Sort by length descending to match longer names first (e.g. "Hoàng Điệp" before "Hoàng")
    names = names.sort_by { |name| -name.length }

    # 3. Perform regex replacements for @Name
    names.each do |name|
      escaped_name = ERB::Util.html_escape(name)
      # Match @Name preceded by whitespace or start of line, followed by whitespace, end of line, or punctuation
      pattern = /(?<=^|\s)@#{Regexp.escape(escaped_name)}(?=\s|$|[,.?!:;])/
      escaped = escaped.gsub(pattern) do
        "<span class=\"lumina__mention-tag\">@#{escaped_name}</span>"
      end
    end

    # 4. Render simple format safely (sanitize is false because we already escaped user input and manually added trusted spans)
    simple_format(escaped, {}, sanitize: false)
  end
end
