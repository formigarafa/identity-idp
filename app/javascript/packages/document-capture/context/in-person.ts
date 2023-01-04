import { createContext } from 'react';

export interface InPersonContextProps {
  /**
   * Feature flag for enabling address search
   */
  arcgisSearchEnabled?: boolean;

  /**
   * Whether or not A/B testing of a more prominent in-person proofing CTA is enabled.
   */
  inPersonCtaABTestingEnabled: boolean;

  /**
   * Whether or not the in-person proofing CTA should be placed more prominently.
   */
  inPersonMoreProminentCta: boolean;

  /**
   * URL to in-person proofing alternative flow, if enabled.
   */
  inPersonURL?: string;
}

const InPersonContext = createContext<InPersonContextProps>({
  arcgisSearchEnabled: false,
  inPersonCtaABTestingEnabled: false,
  inPersonMoreProminentCta: false,
});

InPersonContext.displayName = 'InPersonContext';

export default InPersonContext;
