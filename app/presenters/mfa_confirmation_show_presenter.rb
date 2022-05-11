class MfaConfirmationShowPresenter
  include ActionView::Helpers::TranslationHelper
  attr_reader :mfa_context, :final_path, :next_path, :suggest_second_mfa
  def initialize(current_user:, next_path:, final_path:, suggest_second_mfa: false)
    @mfa_context = MfaContext.new(current_user)
    @final_path = final_path
    @next_path = next_path
    @suggest_second_mfa = suggest_second_mfa
  end

  def title
    if enabled_method_count > 1
      t(
        'titles.mfa_setup.multiple_authentication_methods_setup',
        method_count: method_count_text,
      )
    elsif suggest_second_mfa
      t('titles.mfa_setup.suggest_second_mfa')
    else
      t('titles.mfa_setup.first_authentication_method')
    end
  end

  def info
    t('mfa.account_info', count: enabled_method_count)
  end

  private

  def enabled_method_count
    mfa_context.enabled_mfa_methods_count
  end

  def method_count_text
    t('mfa.current_method_count')[enabled_method_count - 1]
  end
end