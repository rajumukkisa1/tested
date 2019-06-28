# frozen_string_literal: true

class Admin::ImpersonationsController < Admin::ApplicationController
  skip_before_action :authenticate_admin!
  before_action :authenticate_impersonator!

  def destroy
    original_user = stop_impersonation
    redirect_to admin_user_path(original_user), status: :found
  end

  private

  def authenticate_impersonator!
    render_404 unless impersonator&.admin? && !impersonator.blocked?
  end
end
