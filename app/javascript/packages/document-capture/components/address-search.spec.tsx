import { render } from '@testing-library/react';
import { useSandbox } from '@18f/identity-test-helpers';
import userEvent from '@testing-library/user-event';
import { setupServer } from 'msw/node';
import { rest } from 'msw';
import type { SetupServerApi } from 'msw/node';
import AddressSearch, { ADDRESS_SEARCH_URL, LOCATIONS_URL } from './address-search';

const DEFAULT_RESPONSE = [
  {
    address: '100 Main St E, Bronwood, Georgia, 39826',
    location: {
      latitude: 31.831686000000005,
      longitude: -84.363768,
    },
    street_address: '100 Main St E',
    city: 'Bronwood',
    state: 'GA',
    zip_code: '39826',
  },
];

describe('AddressSearch', () => {
  const sandbox = useSandbox();
  context('when an address is found', () => {
    let server: SetupServerApi;
    before(() => {
      server = setupServer(
        rest.post(LOCATIONS_URL, (_req, res, ctx) => res(ctx.json([{ name: 'Baltimore' }]))),
        rest.post(ADDRESS_SEARCH_URL, (_req, res, ctx) => res(ctx.json(DEFAULT_RESPONSE))),
      );
      server.listen();
    });

    after(() => {
      server.close();
    });

    it('fires the callback with correct input', async () => {
      const handleAddressFound = sandbox.stub();
      const handleLocationsFound = sandbox.stub();
      const { findByText, findByLabelText } = render(
        <AddressSearch
          onFoundAddress={handleAddressFound}
          onFoundLocations={handleLocationsFound}
        />,
      );

      await userEvent.type(
        await findByLabelText('in_person_proofing.body.location.po_search.address_search_label'),
        '200 main',
      );
      await userEvent.click(
        await findByText('in_person_proofing.body.location.po_search.search_button'),
      );

      await expect(handleAddressFound).to.eventually.be.called();
      await expect(handleLocationsFound).to.eventually.be.called();
    });
  });

  context('when an address is not found after a previous search returned an address', () => {
    const handleAddressFound = sandbox.stub();
    const handleLocationsFound = sandbox.stub();

    let server: SetupServerApi;
    before(() => {
      server = setupServer(
        rest.post(LOCATIONS_URL, (_req, res, ctx) => res(ctx.json([{ name: 'Baltimore' }]))),
        rest.post(ADDRESS_SEARCH_URL, (_req, res, ctx) => res(ctx.json(DEFAULT_RESPONSE))),
        rest.post(ADDRESS_SEARCH_URL, (_req, res, ctx) => res(ctx.json([]))),
      );
      server.listen();
    });

    after(() => {
      server.close();
    });

    it('sets found address to null after the second search', async () => {
      const firstAddress = {
        streetAddress: DEFAULT_RESPONSE[0].street_address,
        city: DEFAULT_RESPONSE[0].city,
        state: DEFAULT_RESPONSE[0].state,
        zipCode: DEFAULT_RESPONSE[0].zip_code,
        address: DEFAULT_RESPONSE[0].address,
      };
      const { findByText, findByLabelText } = render(
        <AddressSearch
          onFoundAddress={handleAddressFound}
          onFoundLocations={handleLocationsFound}
        />,
      );

      await userEvent.type(
        await findByLabelText('in_person_proofing.body.location.po_search.address_search_label'),
        '200 main',
      );
      await userEvent.click(
        await findByText('in_person_proofing.body.location.po_search.search_button'),
      );

      expect(handleAddressFound).to.have.been.calledWith(firstAddress);

      await userEvent.type(
        await findByLabelText('in_person_proofing.body.location.po_search.address_search_label'),
        'asdfjk',
      );
      await userEvent.click(
        await findByText('in_person_proofing.body.location.po_search.search_button'),
      );
      expect(handleAddressFound).to.have.been.calledWith(null);
    });
  });
});
