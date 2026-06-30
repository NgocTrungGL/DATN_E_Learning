class ErrorsController < ActionController::Base
  layout "error"

  ERROR_PAGES = {
    "400" => {
      status: :bad_request,
      eyebrow: "Bad request",
      title: "This request could not be understood",
      message: "The link or form data looks incomplete. Please go back and try again.",
      icon: "bi-exclamation-diamond"
    },
    "401" => {
      status: :unauthorized,
      eyebrow: "Sign in required",
      title: "Please sign in to continue",
      message: "Your session may have expired, or this page requires an account.",
      icon: "bi-person-lock"
    },
    "403" => {
      status: :forbidden,
      eyebrow: "Access denied",
      title: "You do not have permission here",
      message: "This area is limited to users with the right role or enrollment access.",
      icon: "bi-shield-lock"
    },
    "404" => {
      status: :not_found,
      eyebrow: "Page not found",
      title: "We could not find that learning page",
      message: "The page may have moved, or the address may be incorrect.",
      icon: "bi-compass"
    },
    "406" => {
      status: :not_acceptable,
      eyebrow: "Format not supported",
      title: "This response format is not available",
      message: "Please refresh the page or try opening it from the main application.",
      icon: "bi-file-earmark-x"
    },
    "422" => {
      status: :unprocessable_entity,
      eyebrow: "Request rejected",
      title: "The request could not be processed",
      message: "Some information was missing or could not be validated.",
      icon: "bi-ui-checks"
    },
    "429" => {
      status: :too_many_requests,
      eyebrow: "Too many requests",
      title: "Please slow down for a moment",
      message: "The system received too many requests in a short time. Try again shortly.",
      icon: "bi-hourglass-split"
    },
    "500" => {
      status: :internal_server_error,
      eyebrow: "System error",
      title: "Something went wrong on our side",
      message: "The issue has been recorded. Please return to the homepage or try again later.",
      icon: "bi-tools"
    },
    "503" => {
      status: :service_unavailable,
      eyebrow: "Temporarily unavailable",
      title: "The learning platform is taking a short break",
      message: "Service may be restarting or under maintenance. Please check back soon.",
      icon: "bi-cloud-slash"
    }
  }.freeze

  FALLBACK_PAGE = {
    status: :internal_server_error,
    eyebrow: "Unexpected error",
    title: "An unexpected problem occurred",
    message: "Please return to the homepage while the system records this issue.",
    icon: "bi-life-preserver"
  }.freeze

  def show
    @code = normalized_code
    @error_page = ERROR_PAGES.fetch(@code, FALLBACK_PAGE)

    respond_to do |format|
      format.html { render :show, status: @error_page[:status] }
      format.json { render json: error_json, status: @error_page[:status] }
      format.any { render :show, status: @error_page[:status], formats: :html }
    end
  end

  private

  def normalized_code
    code = params[:code].presence || request.path.delete_prefix("/")
    ERROR_PAGES.key?(code) ? code : "error"
  end

  def error_json
    {
      status: Rack::Utils.status_code(@error_page[:status]),
      error: @error_page[:eyebrow],
      message: @error_page[:message]
    }
  end
end
