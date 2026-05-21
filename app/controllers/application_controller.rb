class ApplicationController < ActionController::API
  include Pagy::Backend

  before_action :authenticate_request!

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from Pundit::NotAuthorizedError, with: :forbidden if defined?(Pundit)

  private

  def authenticate_request!
    token = extract_token
    result = Auth::JwtService.decode(token)

    if result[:success]
      @current_user = User.find(result[:payload]["user_id"])
    else
      render json: { error: result[:error] }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def extract_token
    header = request.headers["Authorization"]
    header&.split(" ")&.last
  end

  def record_not_found(e)
    render json: { error: "Record not found: #{e.message}" }, status: :not_found
  end

  def record_invalid(e)
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  def parameter_missing(e)
    render json: { error: e.message }, status: :bad_request
  end

  def render_success(data, status: :ok, meta: nil)
    response = { data: data }
    response[:meta] = meta if meta
    render json: response, status: status
  end

  def render_error(message, status: :unprocessable_entity, errors: nil)
    response = { error: message }
    response[:errors] = errors if errors
    render json: response, status: status
  end

  def pagy_metadata_response(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end
end
