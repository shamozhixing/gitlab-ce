class JwtController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  before_action :authenticate_project_or_user

  SERVICES = {
    Auth::ContainerRegistryAuthenticationService::AUDIENCE => Auth::ContainerRegistryAuthenticationService,
  }

  def auth
    service = SERVICES[params[:service]]
    return head :not_found unless service

    result = service.new(@project, @user, auth_params).execute

    render json: result, status: result[:http_status]
  end

  private

  def authenticate_project_or_user
    authenticate_with_http_basic do |login, password|
      # if it's possible we first try to authenticate project with login and password
      @project = authenticate_project(login, password)
      return if @project

      @project, @user = authenticate_build(login, password)
      return if @project

      @user = authenticate_user(login, password)
      return if @user

      render_403
    end
  end

  def auth_params
    params.permit(:service, :scope, :account, :client_id)
  end

  def authenticate_project(login, password)
    # We use gitlab-ci-token to find a project using runners_token
    # This is to allow existing builds to access Container Registry
    # TODO: This should be removed in the future
    if login == 'gitlab-ci-token'
      Project.find_by(builds_enabled: true, runners_token: password)
    end
  end

  def authenticate_build(login, password)
    if login == 'gitlab-ci-token' && password
      build = Ci::Build.find_by(token: password)
      return build.project, build.user if build
    end
  end

  def authenticate_user(login, password)
    user = Gitlab::Auth.find_with_user_password(login, password)
    Gitlab::Auth.rate_limit!(request.ip, success: user.present?, login: login)
    user
  end
end
