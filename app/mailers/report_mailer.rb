class ReportMailer < ActionMailer::Base
  include Mailable

  before_action :attach_images

  def deleted_user_accounts_report(email:, name:, issuers:, data:)
    @name = name
    @issuers = issuers
    @data = data
    attachments['deleted_user_accounts.csv'] = data
    mail(to: email, subject: t('report_mailer.deleted_accounts_report.subject'))
  end

  def system_demand_report(email:, data:, name:)
    @name = name
    attachments['system_demand.csv'] = data
    mail(to: email, subject: t('report_mailer.system_demand_report.subject'))
  end
end
