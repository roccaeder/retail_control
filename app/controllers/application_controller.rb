class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  set_current_tenant_through_filter

  before_action :authenticate_user!
  before_action :set_tenant

  private

  def set_tenant
    # acts_as_tenant escopea automáticamente todas las queries al account del usuario.
    set_current_tenant(current_user.account) if current_user&.account
  end
end
