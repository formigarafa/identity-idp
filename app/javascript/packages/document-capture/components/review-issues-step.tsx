import { useContext, useEffect, useState, ReactNode } from 'react';
import { useI18n, formatHTML } from '@18f/identity-react-i18n';
import { useDidUpdateEffect } from '@18f/identity-react-hooks';
import { FormStepsContext, FormStepsButton } from '@18f/identity-form-steps';
import { PageHeading } from '@18f/identity-components';
import { Cancel } from '@18f/identity-verify-flow';
import type { FormStepComponentProps } from '@18f/identity-form-steps';
import DocumentSideAcuantCapture from './document-side-acuant-capture';
import withBackgroundEncryptedUpload from '../higher-order/with-background-encrypted-upload';
import type { PII } from '../services/upload';
import DocumentCaptureTroubleshootingOptions from './document-capture-troubleshooting-options';
import Warning from './warning';
import AnalyticsContext from '../context/analytics';
import BarcodeAttentionWarning from './barcode-attention-warning';
import FailedCaptureAttemptsContext from '../context/failed-capture-attempts';
import { InPersonContext } from '../context';

function formatWithStrongNoWrap(text: string): ReactNode {
  return formatHTML(text, {
    strong: ({ children }) => <strong style={{ whiteSpace: 'nowrap' }}>{children}</strong>,
  });
}

type DocumentSide = 'front' | 'back';

interface ReviewIssuesStepValue {
  /**
   * Front image value.
   */
  front: Blob | string | null | undefined;

  /**
   * Back image value.
   */
  back: Blob | string | null | undefined;

  /**
   * Front image metadata.
   */
  front_image_metadata?: string;

  /**
   * Back image metadata.
   */
  back_image_metadata?: string;
}

interface ReviewIssuesStepProps extends FormStepComponentProps<ReviewIssuesStepValue> {
  remainingAttempts: number;

  isFailedResult: boolean;

  captureHints: boolean;

  pii?: PII;
}

/**
 * Sides of document to present as file input.
 */
const DOCUMENT_SIDES: DocumentSide[] = ['front', 'back'];

const DISPLAY_ATTEMPTS = 3;

function ReviewIssuesStep({
  value = {},
  onChange = () => {},
  errors = [],
  unknownFieldErrors = [],
  onError = () => {},
  registerField = () => undefined,
  remainingAttempts = Infinity,
  isFailedResult = false,
  pii,
  captureHints = false,
}: ReviewIssuesStepProps) {
  const { t } = useI18n();
  const { trackEvent } = useContext(AnalyticsContext);
  const [hasDismissed, setHasDismissed] = useState(remainingAttempts === Infinity);
  const { onPageTransition, changeStepCanComplete } = useContext(FormStepsContext);
  useDidUpdateEffect(onPageTransition, [hasDismissed]);

  const { onFailedSubmissionAttempt } = useContext(FailedCaptureAttemptsContext);
  const { inPersonURL, inPersonCtaVariantTestingEnabled, inPersonCtaVariantActive } =
    useContext(InPersonContext);
  useEffect(() => onFailedSubmissionAttempt(), []);
  function onWarningPageDismissed() {
    trackEvent('IdV: Capture troubleshooting dismissed');

    setHasDismissed(true);
  }
  function onInPersonSelected() {
    trackEvent('IdV: verify in person troubleshooting option clicked');
  }

  // let FormSteps know, via FormStepsContext, whether this page
  // is ready to submit form values
  useEffect(() => {
    changeStepCanComplete(!!hasDismissed);
  }, [hasDismissed]);

  if (!hasDismissed) {
    if (pii) {
      return <BarcodeAttentionWarning onDismiss={onWarningPageDismissed} pii={pii} />;
    }

    if (!inPersonCtaVariantTestingEnabled || !inPersonURL || isFailedResult) {
      return (
        <Warning
          heading={t('errors.doc_auth.throttled_heading')}
          actionText={t('idv.failure.button.warning')}
          actionOnClick={onWarningPageDismissed}
          location="doc_auth_review_issues"
          remainingAttempts={remainingAttempts}
          troubleshootingOptions={
            <DocumentCaptureTroubleshootingOptions
              location="post_submission_warning"
              showAlternativeProofingOptions={!isFailedResult}
              heading={t('components.troubleshooting_options.ipp_heading')}
            />
          }
        >
          {!!unknownFieldErrors &&
            unknownFieldErrors
              .filter((error) => !['front', 'back'].includes(error.field!))
              .map(({ error }) => <p key={error.message}>{error.message}</p>)}

          {remainingAttempts <= DISPLAY_ATTEMPTS && (
            <p>
              <strong>
                {remainingAttempts === 1
                  ? t('idv.failure.attempts.one')
                  : t('idv.failure.attempts.other', { count: remainingAttempts })}
              </strong>
            </p>
          )}
        </Warning>
      );
    }
    if (inPersonCtaVariantActive === 'in_person_variant_a') {
      trackEvent('IdV: IPP CTA Variant A');
      return (
        <Warning
          heading={t('errors.doc_auth.throttled_heading')}
          actionText={t('idv.failure.button.warning_variant')}
          actionOnClick={onWarningPageDismissed}
          location="doc_auth_review_issues"
          remainingAttempts={remainingAttempts}
          troubleshootingOptions={
            <DocumentCaptureTroubleshootingOptions
              location="post_submission_warning"
              showAlternativeProofingOptions={!isFailedResult}
              heading={t('components.troubleshooting_options.ipp_heading')}
              altInPersonCta={t('in_person_proofing.headings.cta_variant')}
              altInPersonPrompt={t('in_person_proofing.body.cta.prompt_detail_a')}
              altInPersonCtaButtonText={t('in_person_proofing.body.cta.button_variant')}
            />
          }
        >
          <h2>{t('errors.doc_auth.throttled_subheading')}</h2>
          {!!unknownFieldErrors &&
            unknownFieldErrors
              .filter((error) => !['front', 'back'].includes(error.field!))
              .map(({ error }) => <p key={error.message}>{error.message}</p>)}

          {remainingAttempts <= DISPLAY_ATTEMPTS && (
            <p>
              {remainingAttempts === 1
                ? formatWithStrongNoWrap(t('idv.failure.attempts.one_variant_a_html'))
                : formatWithStrongNoWrap(
                    t('idv.failure.attempts.other_variant_a_html', { count: remainingAttempts }),
                  )}
            </p>
          )}
        </Warning>
      );
    }
    if (inPersonCtaVariantActive === 'in_person_variant_b') {
      trackEvent('IdV: IPP CTA Variant B');
      return (
        <Warning
          heading={t('errors.doc_auth.throttled_heading')}
          actionText={t('idv.failure.button.warning_variant')}
          actionOnClick={onWarningPageDismissed}
          altActionText={t('in_person_proofing.body.cta.button_variant')}
          altActionOnClick={onInPersonSelected}
          altHref="#location"
          location="doc_auth_review_issues"
          remainingAttempts={remainingAttempts}
          troubleshootingOptions={
            <DocumentCaptureTroubleshootingOptions
              location="post_submission_warning"
              showAlternativeProofingOptions={false}
              heading={t('components.troubleshooting_options.ipp_heading')}
            />
          }
        >
          {!!unknownFieldErrors &&
            unknownFieldErrors
              .filter((error) => !['front', 'back'].includes(error.field!))
              .map(({ error }) => <p key={error.message}>{error.message}</p>)}

          {remainingAttempts <= DISPLAY_ATTEMPTS && (
            <p>
              {remainingAttempts === 1
                ? formatWithStrongNoWrap(t('idv.failure.attempts.one_variant_b_html'))
                : formatWithStrongNoWrap(
                    t('idv.failure.attempts.other_variant_b_html', { count: remainingAttempts }),
                  )}
            </p>
          )}
          <p>{t('in_person_proofing.body.cta.prompt_detail_b')}</p>
        </Warning>
      );
    }
    if (inPersonCtaVariantActive === 'in_person_variant_c') {
      trackEvent('IdV: IPP CTA Variant C');
      return (
        <Warning
          heading={t('errors.doc_auth.throttled_heading')}
          actionText={t('idv.failure.button.warning')}
          actionOnClick={onWarningPageDismissed}
          location="doc_auth_review_issues"
          remainingAttempts={remainingAttempts}
          troubleshootingOptions={
            <DocumentCaptureTroubleshootingOptions
              location="post_submission_warning"
              showAlternativeProofingOptions={false}
              heading={t('components.troubleshooting_options.ipp_heading')}
            />
          }
        >
          {!!unknownFieldErrors &&
            unknownFieldErrors
              .filter((error) => !['front', 'back'].includes(error.field!))
              .map(({ error }) => <p key={error.message}>{error.message}</p>)}

          {remainingAttempts <= DISPLAY_ATTEMPTS && (
            <p>
              <strong>
                {remainingAttempts === 1
                  ? t('idv.failure.attempts.one')
                  : t('idv.failure.attempts.other', { count: remainingAttempts })}
              </strong>
            </p>
          )}
        </Warning>
      );
    }
  }

  return (
    <>
      <PageHeading>{t('doc_auth.headings.review_issues')}</PageHeading>
      {!!unknownFieldErrors &&
        unknownFieldErrors.map(({ error }) => <p key={error.message}>{error.message}</p>)}
      {captureHints && (
        <>
          <p className="margin-bottom-0">{t('doc_auth.tips.review_issues_id_header_text')}</p>
          <ul>
            <li>{t('doc_auth.tips.review_issues_id_text1')}</li>
            <li>{t('doc_auth.tips.review_issues_id_text2')}</li>
            <li>{t('doc_auth.tips.review_issues_id_text3')}</li>
            <li>{t('doc_auth.tips.review_issues_id_text4')}</li>
          </ul>
        </>
      )}
      {DOCUMENT_SIDES.map((side) => (
        <DocumentSideAcuantCapture
          key={side}
          side={side}
          registerField={registerField}
          value={value[side]}
          onChange={onChange}
          errors={errors}
          onError={onError}
          className="document-capture-review-issues-step__input"
        />
      ))}

      <FormStepsButton.Submit />
      <DocumentCaptureTroubleshootingOptions />
      <Cancel />
    </>
  );
}

export default withBackgroundEncryptedUpload(ReviewIssuesStep);
