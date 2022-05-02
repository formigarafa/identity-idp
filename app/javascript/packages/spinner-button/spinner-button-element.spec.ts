import sinon from 'sinon';
import userEvent from '@testing-library/user-event';
import { getByRole, fireEvent, screen } from '@testing-library/dom';
import './spinner-button-element';
import type { SpinnerButtonElement } from './spinner-button-element';

describe('SpinnerButtonElement', () => {
  let clock;

  const longWaitDurationMs = 1000;

  interface WrapperOptions {
    actionMessage?: string;

    tagName?: string;
  }

  function createWrapper({ actionMessage, tagName = 'a' }: WrapperOptions = {}) {
    document.body.innerHTML = `
      <lg-spinner-button data-long-wait-duration-ms="${longWaitDurationMs}">
        <div class="spinner-button__content">
          ${tagName === 'a' ? '<a href="#">Click Me</a>' : '<input type="submit" value="Click Me">'}
          <span class="spinner-dots" aria-hidden="true">
            <span class="spinner-dots__dot"></span>
            <span class="spinner-dots__dot"></span>
            <span class="spinner-dots__dot"></span>
          </span>
        </div>
        ${
          actionMessage
            ? `<div
                 role="status"
                 data-message="${actionMessage}"
                 class="spinner-button__action-message usa-sr-only"></div>`
            : ''
        }
      </lg-spinner-button>`;

    return document.body.firstElementChild as SpinnerButtonElement;
  }

  beforeEach(() => {
    clock = sinon.useFakeTimers();
  });

  afterEach(() => {
    clock.restore();
  });

  it('shows spinner on click', async () => {
    const wrapper = createWrapper();
    const button = screen.getByRole('link', { name: 'Click Me' });

    await userEvent.click(button, { advanceTimers: clock.tick });

    expect(wrapper.classList.contains('spinner-button--spinner-active')).to.be.true();
  });

  it('disables button without preventing form handlers', async () => {
    const wrapper = createWrapper({ tagName: 'button' });
    let submitted = false;
    const form = document.createElement('form');
    form.action = '#';
    form.addEventListener('submit', (event) => {
      submitted = true;
      event.preventDefault();
    });
    document.body.appendChild(form);
    form.appendChild(wrapper);
    const button = screen.getByRole('button', { name: 'Click Me' });

    await userEvent.type(button, '{Enter}', { advanceTimers: clock.tick });
    clock.tick(0);

    expect(submitted).to.be.true();
    expect(button.hasAttribute('disabled')).to.be.true();
  });

  it('announces action message', async () => {
    const wrapper = createWrapper({ actionMessage: 'Verifying...' });
    const status = getByRole(wrapper, 'status');
    const button = screen.getByRole('link', { name: 'Click Me' });

    expect(status.textContent).to.be.empty();

    await userEvent.click(button, { advanceTimers: clock.tick });

    expect(status.textContent).to.equal('Verifying...');
    expect(status.classList.contains('usa-sr-only')).to.be.true();
  });

  it('shows action message visually after long delay', async () => {
    const wrapper = createWrapper({ actionMessage: 'Verifying...' });
    const status = getByRole(wrapper, 'status');
    const button = screen.getByRole('link', { name: 'Click Me' });

    expect(status.textContent).to.be.empty();

    await userEvent.click(button, { advanceTimers: clock.tick });
    clock.tick(longWaitDurationMs - 1);
    expect(status.classList.contains('usa-sr-only')).to.be.true();
    clock.tick(1);
    expect(status.classList.contains('usa-sr-only')).to.be.false();
  });

  it('supports external dispatched events to control spinner', () => {
    const wrapper = createWrapper();

    fireEvent(wrapper, new window.CustomEvent('spinner.start'));
    expect(wrapper.classList.contains('spinner-button--spinner-active')).to.be.true();
    fireEvent(wrapper, new window.CustomEvent('spinner.stop'));
    expect(wrapper.classList.contains('spinner-button--spinner-active')).to.be.false();
  });
});