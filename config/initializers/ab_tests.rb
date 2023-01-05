require 'ab_test_bucket'

module AbTests
  DOC_AUTH_VENDOR = AbTestBucket.new(
    experiment_name: 'Doc Auth Vendor',
    buckets: {
      alternate_vendor: IdentityConfig.store.doc_auth_vendor_randomize ?
        IdentityConfig.store.doc_auth_vendor_randomize_percent :
        0,
    }.compact,
  )

  ACUANT_SDK = AbTestBucket.new(
    experiment_name: 'Acuant SDK Upgrade',
    buckets: {
      use_alternate_sdk: IdentityConfig.store.idv_acuant_sdk_upgrade_a_b_testing_enabled ?
        IdentityConfig.store.idv_acuant_sdk_upgrade_a_b_testing_percent :
        0,
    },
  )

  IN_PERSON_CTA = AbTestBucket.new(
    experiment_name: 'In-Person Proofing CTA',
    buckets: {
      more_prominent_cta: IdentityConfig.store.in_person_cta_a_b_testing_enabled ?
        IdentityConfig.store.in_person_cta_a_b_testing_percent :
        0,
    },
  )
end
