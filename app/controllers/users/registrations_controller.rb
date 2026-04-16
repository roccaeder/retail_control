class Users::RegistrationsController < Devise::RegistrationsController
  # Desactiva el tenant obligatorio en el registro (aún no existe account)
  skip_before_action :set_tenant

  def new
    @account = Account.new
    super
  end

  def create
    @account = Account.new(account_params)

    unless @account.valid?
      build_resource(sign_up_params)
      resource.valid?
      flash.now[:alert] = @account.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity and return
    end

    build_resource(sign_up_params)

    ActiveRecord::Base.transaction do
      @account.save!
      resource.account = @account
      resource.save!
    end

    if resource.persisted?
      set_flash_message! :notice, :signed_up
      sign_up(resource_name, resource)
      respond_with resource, location: after_sign_up_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  rescue ActiveRecord::RecordInvalid
    clean_up_passwords resource
    render :new, status: :unprocessable_entity
  end

  private

  def account_params
    params.require(:account).permit(:name, :subdomain)
  end
end
